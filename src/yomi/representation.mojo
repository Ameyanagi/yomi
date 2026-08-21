"""Source-preserving phonetic representation values."""

from std.collections import List


struct _Validated:
    def __init__(out self):
        pass


struct SourceRange(Copyable):
    """One non-empty half-open byte range in original source text.

    Values returned by a representation projection are ordered by source byte
    position. Construction establishes the range invariant and reads trust it
    thereafter. Direct mutation of underscore-prefixed storage is out of
    contract; call `validate()` explicitly after unusual low-level mutation.
    """

    var _start: Int
    var _end: Int

    def __init__(out self, start: Int, end: Int) raises:
        self._start = start
        self._end = end
        self.validate()

    def validate(self) raises:
        """Validate the stored source range explicitly."""
        if self._start < 0 or self._end <= self._start:
            raise Error(
                "source range ["
                + String(self._start)
                + ", "
                + String(self._end)
                + ") is invalid: start must be >= 0 and end must be > start"
            )

    def start(self) -> Int:
        """Return the inclusive source byte offset."""
        return self._start

    def end(self) -> Int:
        """Return the exclusive source byte offset."""
        return self._end


struct SourceMapping(Copyable):
    """Map one non-empty UTF-8 output range to its original source range.

    All offsets are half-open byte offsets. A transformed source grapheme may
    occupy a different number of output bytes, so consumers must not assume
    that the two ranges have equal lengths. Construction establishes range
    shape; `PhoneticRepresentation` additionally validates the ranges against
    its owned source and transformed text. Reads trust those invariants. Direct
    mutation of underscore-prefixed storage is out of contract; call
    `validate()` explicitly after unusual low-level mutation.
    """

    var _output_start: Int
    var _output_end: Int
    var _source_start: Int
    var _source_end: Int

    def __init__(
        out self,
        output_start: Int,
        output_end: Int,
        source_start: Int,
        source_end: Int,
    ) raises:
        self._output_start = output_start
        self._output_end = output_end
        self._source_start = source_start
        self._source_end = source_end
        self.validate()

    @staticmethod
    def _from_validated(
        output_start: Int,
        output_end: Int,
        source_start: Int,
        source_end: Int,
    ) -> Self:
        """Build a mapping without validation.

        Package-internal callers guarantee non-empty, boundary-aligned ranges
        produced by arithmetic that preserves the mapping invariants.
        """
        return Self(
            output_start,
            output_end,
            source_start,
            source_end,
            _validated=_Validated(),
        )

    def __init__(
        out self,
        output_start: Int,
        output_end: Int,
        source_start: Int,
        source_end: Int,
        *,
        _validated: _Validated,
    ):
        self._output_start = output_start
        self._output_end = output_end
        self._source_start = source_start
        self._source_end = source_end

    def validate(self) raises:
        """Validate the stored output and source ranges explicitly."""
        if self._output_start < 0 or self._output_end <= self._output_start:
            raise Error(
                "output mapping range ["
                + String(self._output_start)
                + ", "
                + String(self._output_end)
                + ") is invalid: start must be >= 0 and end must be > start"
            )
        if self._source_start < 0 or self._source_end <= self._source_start:
            raise Error(
                "source mapping range ["
                + String(self._source_start)
                + ", "
                + String(self._source_end)
                + ") is invalid: start must be >= 0 and end must be > start"
            )

    def output_start(self) -> Int:
        """Return the inclusive output byte offset."""
        return self._output_start

    def output_end(self) -> Int:
        """Return the exclusive output byte offset."""
        return self._output_end

    def source_start(self) -> Int:
        """Return the inclusive source byte offset."""
        return self._source_start

    def source_end(self) -> Int:
        """Return the exclusive source byte offset."""
        return self._source_end


struct PhoneticRepresentation(Copyable):
    """Own source and transformed UTF-8 text plus ordered mappings.

    Mappings cover the transformed text from byte zero without gaps or
    overlaps and point only to valid source-text boundaries. Empty input has
    empty transformed text and no mappings. Construction establishes these
    invariants and reads trust them thereafter. Direct mutation of
    underscore-prefixed storage is out of contract; call `validate()`
    explicitly after unusual low-level mutation.
    """

    var _source: String
    var _text: String
    var _mappings: List[SourceMapping]

    def __init__(
        out self,
        var source: String,
        var text: String,
        var mappings: List[SourceMapping],
    ) raises:
        self._source = source^
        self._text = text^
        self._mappings = mappings^
        self.validate()

    @staticmethod
    def _from_validated(
        var source: String,
        var text: String,
        var mappings: List[SourceMapping],
    ) -> Self:
        """Build a representation without validation.

        Package-internal transforms guarantee owned UTF-8 text plus ordered,
        gap-free, boundary-aligned mappings covering the transformed text.
        """
        return Self(source^, text^, mappings^, _validated=_Validated())

    def __init__(
        out self,
        var source: String,
        var text: String,
        var mappings: List[SourceMapping],
        *,
        _validated: _Validated,
    ):
        self._source = source^
        self._text = text^
        self._mappings = mappings^

    def validate(self) raises:
        """Validate owned text and all stored mappings explicitly."""
        var text_length = self._text.byte_length()
        var source_length = self._source.byte_length()
        var expected_output_start = 0
        for index in range(len(self._mappings)):
            var mapping = self._mappings[index].copy()
            mapping.validate()
            if mapping._output_start != expected_output_start:
                raise Error(
                    "output mapping at index "
                    + String(index)
                    + " starts at "
                    + String(mapping._output_start)
                    + ", but ordered, gap-free mappings require output start "
                    + String(expected_output_start)
                    + "; set this mapping's output start to "
                    + String(expected_output_start)
                )
            if not _is_utf8_boundary(self._text, mapping._output_end):
                raise Error(
                    "output mapping at index "
                    + String(index)
                    + " has invalid end offset "
                    + String(mapping._output_end)
                    + " for transformed text with byte length "
                    + String(text_length)
                    + ": end must be a UTF-8 code-point boundary within [0, "
                    + String(text_length)
                    + "]; choose an in-bounds boundary offset"
                )
            if not _is_utf8_boundary(self._source, mapping._source_start):
                raise Error(
                    "source mapping at index "
                    + String(index)
                    + " has invalid start offset "
                    + String(mapping._source_start)
                    + " for source text with byte length "
                    + String(source_length)
                    + ": start must be a UTF-8 code-point boundary within [0, "
                    + String(source_length)
                    + "]; choose an in-bounds boundary offset"
                )
            if not _is_utf8_boundary(self._source, mapping._source_end):
                raise Error(
                    "source mapping at index "
                    + String(index)
                    + " has invalid end offset "
                    + String(mapping._source_end)
                    + " for source text with byte length "
                    + String(source_length)
                    + ": end must be a UTF-8 code-point boundary within [0, "
                    + String(source_length)
                    + "]; choose an in-bounds boundary offset"
                )
            expected_output_start = mapping._output_end
        if expected_output_start != text_length:
            raise Error(
                "output mappings have covered length "
                + String(expected_output_start)
                + ", but transformed text byte length is "
                + String(text_length)
                + "; mappings must cover [0, "
                + String(text_length)
                + "); add or extend mappings to cover all "
                + String(text_length)
                + " bytes"
            )

    def source_text(self) -> String:
        """Return a copy of the original source text."""
        return self._source.copy()

    def text(self) -> String:
        """Return a copy of the transformed text."""
        return self._text.copy()

    def mapping_count(self) -> Int:
        """Return the number of mapping spans."""
        return len(self._mappings)

    def mapping(self, index: Int) raises -> SourceMapping:
        """Return a mapping, rejecting an invalid index."""
        var mapping_count = len(self._mappings)
        if index < 0 or index >= mapping_count:
            var mapping_count_description = String(mapping_count) + " mappings"
            if mapping_count == 1:
                mapping_count_description = String("1 mapping")
            raise Error(
                "mapping index "
                + String(index)
                + " is out of range for "
                + mapping_count_description
                + "; valid indexes are [0, "
                + String(mapping_count)
                + ")"
            )
        return self._mappings[index].copy()

    def mapping_snapshot(self) -> List[SourceMapping]:
        """Copy all mappings for linear-time enumeration.

        The returned list is detached from the representation, and its mapping
        values retain the construction-validated, trusted-read contract.
        """
        return self._mappings.copy()

    def source_ranges_for_output(
        self, output_start: Int, output_end: Int
    ) raises -> List[SourceRange]:
        """Project a matched output range to exact ordered source ranges.

        The output range must be non-empty, in bounds, and on UTF-8 code-point
        boundaries. Returned source ranges are sorted by source byte position.
        Overlapping or touching ranges merge; a gap is never bridged by a
        bounding range.
        """
        if output_start < 0:
            raise Error(
                "output range start "
                + String(output_start)
                + " must be >= 0; choose a nonnegative start offset"
            )
        if output_end < output_start:
            raise Error(
                "output range ["
                + String(output_start)
                + ", "
                + String(output_end)
                + ") is reversed: end must be >= start; swap the values or "
                "choose an end at or after " + String(output_start)
            )
        if output_end == output_start:
            raise Error(
                "output range ["
                + String(output_start)
                + ", "
                + String(output_end)
                + ") is empty: end must be greater than start; choose an end "
                "greater than " + String(output_start)
            )

        var text_length = self._text.byte_length()
        if output_start > text_length:
            raise Error(
                "output range start "
                + String(output_start)
                + " exceeds transformed text length "
                + String(text_length)
                + "; choose a start offset within [0, "
                + String(text_length)
                + "]"
            )
        if output_end > text_length:
            raise Error(
                "output range end "
                + String(output_end)
                + " exceeds transformed text length "
                + String(text_length)
                + "; choose an end offset within [0, "
                + String(text_length)
                + "]"
            )
        if not _is_utf8_boundary(self._text, output_start):
            raise Error(
                "output range start "
                + String(output_start)
                + " is not a UTF-8 code-point boundary in transformed text with byte"
                " length "
                + String(text_length)
                + "; align the start to a boundary within [0, "
                + String(text_length)
                + "]"
            )
        if not _is_utf8_boundary(self._text, output_end):
            raise Error(
                "output range end "
                + String(output_end)
                + " is not a UTF-8 code-point boundary in transformed text with byte"
                " length "
                + String(text_length)
                + "; align the end to a boundary within [0, "
                + String(text_length)
                + "]"
            )

        var ranges = List[SourceRange]()
        var index = _first_mapping_ending_after(self._mappings, output_start)
        while index < len(self._mappings):
            var mapping = self._mappings[index].copy()
            if mapping._output_start >= output_end:
                break
            ranges.append(SourceRange(mapping._source_start, mapping._source_end))
            index += 1

        _sort_source_ranges(ranges)
        return _merge_source_ranges(ranges^)


def _is_utf8_boundary(text: StringSlice, offset: Int) -> Bool:
    if offset < 0 or offset > text.byte_length():
        return False
    return text.is_codepoint_boundary(offset)


def _first_mapping_ending_after(
    mappings: List[SourceMapping], output_start: Int
) -> Int:
    var lower = 0
    var upper = len(mappings)
    while lower < upper:
        var middle = lower + (upper - lower) // 2
        if mappings[middle]._output_end <= output_start:
            lower = middle + 1
        else:
            upper = middle
    return lower


def _sort_source_ranges(mut ranges: List[SourceRange]):
    @parameter
    def less(left: SourceRange, right: SourceRange) -> Bool:
        return left._start < right._start or (
            left._start == right._start and left._end < right._end
        )

    sort[less](ranges[:])


def _merge_source_ranges(var ranges: List[SourceRange]) raises -> List[SourceRange]:
    var merged = List[SourceRange]()
    for index in range(len(ranges)):
        var current = ranges[index].copy()
        if len(merged) == 0:
            merged.append(current.copy())
            continue
        var previous = merged[len(merged) - 1].copy()
        if current._start <= previous._end:
            merged[len(merged) - 1] = SourceRange(
                previous._start, max(previous._end, current._end)
            )
        else:
            merged.append(current.copy())
    return merged^
