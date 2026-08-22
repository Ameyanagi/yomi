"""Source-preserving phonetic representation values."""

from std.collections import List


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
            raise Error("source range must be nonnegative and non-empty")

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
    that the two ranges have equal lengths. Generated separators use
    `SourceMapping.unmapped()` and have no source range; call `has_source()`
    before reading their source offsets. Their internal source-offset sentinel
    is an implementation detail. Construction establishes range shape;
    `PhoneticRepresentation` additionally validates ranges against its owned
    source and transformed text. Reads trust those invariants. Direct mutation
    of underscore-prefixed storage is out of contract; call `validate()`
    explicitly after unusual low-level mutation.
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
    def unmapped(output_start: Int, output_end: Int) raises -> Self:
        """Construct an output span generated without source text."""
        return Self(output_start, output_end, -1, -1)

    def validate(self) raises:
        """Validate the stored output and source ranges explicitly."""
        if self._output_start < 0 or self._output_end <= self._output_start:
            raise Error("output mapping range must be nonnegative and non-empty")
        if self._source_start == -1 and self._source_end == -1:
            return
        if self._source_start < 0 or self._source_end <= self._source_start:
            raise Error(
                "source mapping range must be nonnegative and non-empty, "
                "or both offsets must be -1 for unmapped output"
            )

    def has_source(self) -> Bool:
        """Return whether this output span maps to source text."""
        return self._source_start >= 0

    def output_start(self) -> Int:
        """Return the inclusive output byte offset."""
        return self._output_start

    def output_end(self) -> Int:
        """Return the exclusive output byte offset."""
        return self._output_end

    def source_start(self) -> Int:
        """Return the inclusive source byte offset; requires `has_source()`."""
        return self._source_start

    def source_end(self) -> Int:
        """Return the exclusive source byte offset; requires `has_source()`."""
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

    def validate(self) raises:
        """Validate owned text and all stored mappings explicitly."""
        var expected_output_start = 0
        for index in range(len(self._mappings)):
            var mapping = self._mappings[index].copy()
            mapping.validate()
            if mapping._output_start != expected_output_start:
                raise Error("output mappings must be ordered and gap-free")
            if not _is_utf8_boundary(self._text, mapping._output_end):
                raise Error("output mapping range must end at a UTF-8 boundary")
            if mapping.has_source():
                if not _is_utf8_boundary(self._source, mapping._source_start):
                    raise Error("source mapping range must start at a UTF-8 boundary")
                if not _is_utf8_boundary(self._source, mapping._source_end):
                    raise Error("source mapping range must end at a UTF-8 boundary")
            expected_output_start = mapping._output_end
        if expected_output_start != self._text.byte_length():
            raise Error("output mappings must cover the transformed text")

    def source_text(self) -> String:
        """Return a copy of the original source text."""
        return self._source.copy()

    def text(self) -> String:
        """Return a copy of the transformed text."""
        return self._text.copy()

    def text_byte_length(self) -> Int:
        """Return the transformed UTF-8 byte length without copying text."""
        return self._text.byte_length()

    def text_equals(self, value: StringSlice) -> Bool:
        """Compare transformed text without constructing a detached copy."""
        return self._text == value

    def has_same_text(self, other: Self) -> Bool:
        """Compare two transformed values without copying either string."""
        return self._text == other._text

    def mapping_count(self) -> Int:
        """Return the number of mapping spans."""
        return len(self._mappings)

    def mapping(self, index: Int) raises -> SourceMapping:
        """Return a mapping, rejecting an invalid index."""
        if index < 0 or index >= len(self._mappings):
            raise Error("source mapping index is out of range")
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
        if output_start < 0 or output_end <= output_start:
            raise Error("matched output range must be nonnegative and non-empty")
        if not _is_utf8_boundary(self._text, output_start):
            raise Error("matched output start must be a UTF-8 boundary")
        if not _is_utf8_boundary(self._text, output_end):
            raise Error("matched output end must be a UTF-8 boundary")

        var ranges = List[SourceRange]()
        var index = _first_mapping_ending_after(self._mappings, output_start)
        while index < len(self._mappings):
            var mapping = self._mappings[index].copy()
            if mapping._output_start >= output_end:
                break
            if mapping.has_source():
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
