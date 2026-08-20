"""Source-preserving phonetic representation values."""

from std.collections import List


struct SourceRange(Copyable):
    """One non-empty half-open byte range in original source text.

    Values returned by a representation projection are ordered by source byte
    position. Standalone reads revalidate range shape after reachable storage
    mutation.
    """

    var _start: Int
    var _end: Int

    def __init__(out self, start: Int, end: Int) raises:
        self._start = start
        self._end = end
        self._validate()

    def _validate(self) raises:
        if self._start < 0 or self._end <= self._start:
            raise Error("source range must be nonnegative and non-empty")

    def start(self) raises -> Int:
        """Revalidate and return the inclusive source byte offset."""
        self._validate()
        return self._start

    def end(self) raises -> Int:
        """Revalidate and return the exclusive source byte offset."""
        self._validate()
        return self._end


struct SourceMapping(Copyable):
    """Map one non-empty UTF-8 output range to its original source range.

    All offsets are half-open byte offsets. A transformed source grapheme may
    occupy a different number of output bytes, so consumers must not assume
    that the two ranges have equal lengths. This standalone value validates
    range shape on every read; `PhoneticRepresentation` additionally validates
    the ranges against its owned source and transformed text.
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
        self._validate()

    def _validate(self) raises:
        if self._output_start < 0 or self._output_end <= self._output_start:
            raise Error("output mapping range must be nonnegative and non-empty")
        if self._source_start < 0 or self._source_end <= self._source_start:
            raise Error("source mapping range must be nonnegative and non-empty")

    def output_start(self) raises -> Int:
        """Revalidate and return the inclusive output byte offset."""
        self._validate()
        return self._output_start

    def output_end(self) raises -> Int:
        """Revalidate and return the exclusive output byte offset."""
        self._validate()
        return self._output_end

    def source_start(self) raises -> Int:
        """Revalidate and return the inclusive source byte offset."""
        self._validate()
        return self._source_start

    def source_end(self) raises -> Int:
        """Revalidate and return the exclusive source byte offset."""
        self._validate()
        return self._source_end


struct PhoneticRepresentation(Copyable):
    """Own source and transformed UTF-8 text plus ordered mappings.

    Mappings cover the transformed text from byte zero without gaps or
    overlaps and point only to valid source-text boundaries. Empty input has
    empty transformed text and no mappings.
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
        self._validate()

    def _validate(self) raises:
        var expected_output_start = 0
        for index in range(len(self._mappings)):
            var mapping = self._mappings[index].copy()
            mapping._validate()
            if mapping._output_start != expected_output_start:
                raise Error("output mappings must be ordered and gap-free")
            if not _is_utf8_boundary(self._text, mapping._output_end):
                raise Error("output mapping range must end at a UTF-8 boundary")
            if not _is_utf8_boundary(self._source, mapping._source_start):
                raise Error("source mapping range must start at a UTF-8 boundary")
            if not _is_utf8_boundary(self._source, mapping._source_end):
                raise Error("source mapping range must end at a UTF-8 boundary")
            expected_output_start = mapping._output_end
        if expected_output_start != self._text.byte_length():
            raise Error("output mappings must cover the transformed text")

    def source_text(self) raises -> String:
        """Return a copy of the original source text after revalidation."""
        self._validate()
        return self._source.copy()

    def text(self) raises -> String:
        """Revalidate the representation and return transformed text."""
        self._validate()
        return self._text.copy()

    def mapping_count(self) raises -> Int:
        """Revalidate and return the number of mapping spans."""
        self._validate()
        return len(self._mappings)

    def mapping(self, index: Int) raises -> SourceMapping:
        """Revalidate and return a mapping, rejecting an invalid index."""
        self._validate()
        if index < 0 or index >= len(self._mappings):
            raise Error("source mapping index is out of range")
        return self._mappings[index].copy()

    def mapping_snapshot(self) raises -> List[SourceMapping]:
        """Validate once and copy all mappings for linear-time enumeration.

        The returned list is detached from the representation. Each mapping
        still validates its own range shape on accessor calls, while callers
        avoid revalidating the complete representation for every index.
        """
        self._validate()
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
        self._validate()
        if output_start < 0 or output_end <= output_start:
            raise Error("matched output range must be nonnegative and non-empty")
        if not _is_utf8_boundary(self._text, output_start):
            raise Error("matched output start must be a UTF-8 boundary")
        if not _is_utf8_boundary(self._text, output_end):
            raise Error("matched output end must be a UTF-8 boundary")

        var ranges = List[SourceRange]()
        for index in range(len(self._mappings)):
            var mapping = self._mappings[index].copy()
            if (
                mapping._output_start < output_end
                and mapping._output_end > output_start
            ):
                ranges.append(SourceRange(mapping._source_start, mapping._source_end))

        _sort_source_ranges(ranges)
        return _merge_source_ranges(ranges^)


def _is_utf8_boundary(text: StringSlice, offset: Int) -> Bool:
    if offset < 0 or offset > text.byte_length():
        return False
    return text.is_codepoint_boundary(offset)


def _sort_source_ranges(mut ranges: List[SourceRange]):
    for index in range(1, len(ranges)):
        var value = ranges[index].copy()
        var cursor = index
        while cursor > 0:
            var previous = ranges[cursor - 1].copy()
            if previous._start < value._start or (
                previous._start == value._start and previous._end <= value._end
            ):
                break
            ranges[cursor] = previous.copy()
            cursor -= 1
        ranges[cursor] = value.copy()


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
