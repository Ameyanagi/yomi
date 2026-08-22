"""Deterministic pinyin representations for Chinese search."""

from std.collections import List

from ..representation import PhoneticRepresentation, SourceMapping
from ._pinyin_data import (
    _PINYIN_RECORD_BYTES,
    _PINYIN_RECORD_COUNT,
    _PINYIN_TABLE,
)


comptime _FULL = 0
comptime _JOINED = 1
comptime _INITIALS = 2


struct ChinesePolyphoneMode(Copyable, Equatable, ImplicitlyCopyable):
    """Control common single-character alternate pinyin readings."""

    var _value: Int

    comptime NONE = ChinesePolyphoneMode(_value=0)
    comptime COMMON = ChinesePolyphoneMode(_value=1)

    def __init__(out self, *, _value: Int):
        self._value = _value

    def __eq__(self, other: Self) -> Bool:
        return self._value == other._value


struct _PinyinUnit(Copyable):
    var _code_point: Int
    var _readings: List[String]
    var _source_start: Int
    var _source_end: Int

    def __init__(
        out self,
        code_point: Int,
        var readings: List[String],
        source_start: Int,
        source_end: Int,
    ):
        self._code_point = code_point
        self._readings = readings^
        self._source_start = source_start
        self._source_end = source_end


def _hex_digit(value: Int) -> Int:
    if value >= 48 and value <= 57:
        return value - 48
    return value - 65 + 10


def _table_code_point(index: Int) -> Int:
    var table = StringSlice(_PINYIN_TABLE)
    var cursor = index * _PINYIN_RECORD_BYTES
    var value = 0
    for offset in range(6):
        value = value * 16 + _hex_digit(ord(table[byte=cursor + offset]))
    return value


def _table_reading(index: Int, reading_index: Int) -> String:
    var table = StringSlice(_PINYIN_TABLE)
    var start = index * _PINYIN_RECORD_BYTES + 6 + reading_index * 6
    var end = start + 6
    while end > start and table[byte=end - 1] == " ":
        end -= 1
    return String(table[byte=start:end])


def _lookup_readings(code_point: Int, max_readings: Int) -> List[String]:
    """Find up to three readings with an allocation-free binary table probe."""
    var lower = 0
    var upper = _PINYIN_RECORD_COUNT
    while lower < upper:
        var middle = lower + (upper - lower) // 2
        var candidate = _table_code_point(middle)
        if candidate < code_point:
            lower = middle + 1
        else:
            upper = middle

    var readings = List[String](capacity=max_readings)
    if lower >= _PINYIN_RECORD_COUNT:
        return readings^
    if _table_code_point(lower) != code_point:
        return readings^
    for reading_index in range(max_readings):
        var reading = _table_reading(lower, reading_index)
        if reading.byte_length() == 0:
            break
        readings.append(reading^)
    return readings^


def _first_code_point(text: StringSlice) -> Int:
    for value in text.codepoints():
        return Int(value.to_u32())
    return -1


def _scan_units(source: StringSlice, max_readings: Int) -> List[_PinyinUnit]:
    var units = List[_PinyinUnit]()
    var source_cursor = 0
    for code_point_slice in source.codepoint_slices():
        var source_end = source_cursor + code_point_slice.byte_length()
        var code_point = _first_code_point(code_point_slice)
        var readings = _lookup_readings(code_point, max_readings)
        if len(readings) > 0:
            units.append(
                _PinyinUnit(
                    code_point,
                    readings^,
                    source_cursor,
                    source_end,
                )
            )
        source_cursor = source_end

    _apply_chongqing_primary(units)
    return units^


def _single_reading(value: StringSlice) -> List[String]:
    var readings = List[String](capacity=1)
    readings.append(String(value))
    return readings^


def _apply_chongqing_primary(mut units: List[_PinyinUnit]):
    """Match Yuru's small phrase exception for the common city name."""
    if len(units) < 2:
        return
    for index in range(len(units) - 1):
        if (
            units[index]._code_point == 0x91CD
            and units[index + 1]._code_point == 0x5E86
            and units[index]._source_end == units[index + 1]._source_start
        ):
            units[index]._readings = _single_reading("chong")
            units[index + 1]._readings = _single_reading("qing")


def _primary_readings(units: List[_PinyinUnit]) -> List[String]:
    var selected = List[String](capacity=len(units))
    for index in range(len(units)):
        selected.append(units[index]._readings[0].copy())
    return selected^


def _append_mapped(
    value: StringSlice,
    source_start: Int,
    source_end: Int,
    mut output: String,
    mut mappings: List[SourceMapping],
    mut output_cursor: Int,
) raises:
    var output_end = output_cursor + value.byte_length()
    output += value
    mappings.append(
        SourceMapping(
            output_cursor,
            output_end,
            source_start,
            source_end,
        )
    )
    output_cursor = output_end


def _append_separator(
    mut output: String,
    mut mappings: List[SourceMapping],
    mut output_cursor: Int,
) raises:
    output += " "
    mappings.append(SourceMapping.unmapped(output_cursor, output_cursor + 1))
    output_cursor += 1


def _append_initial(
    value: StringSlice,
    source_start: Int,
    source_end: Int,
    mut output: String,
    mut mappings: List[SourceMapping],
    mut output_cursor: Int,
) raises:
    for initial in value.codepoint_slices():
        _append_mapped(
            initial,
            source_start,
            source_end,
            output,
            mappings,
            output_cursor,
        )
        return


def _build_representation(
    source: StringSlice,
    units: List[_PinyinUnit],
    selected: List[String],
    form: Int,
) raises -> PhoneticRepresentation:
    var output = String()
    var mapping_capacity = len(units)
    if form == _FULL and mapping_capacity > 0:
        mapping_capacity = mapping_capacity * 2 - 1
    var mappings = List[SourceMapping](capacity=mapping_capacity)
    var output_cursor = 0
    for index in range(len(units)):
        if form == _FULL and index > 0:
            _append_separator(output, mappings, output_cursor)
        if form == _INITIALS:
            _append_initial(
                selected[index],
                units[index]._source_start,
                units[index]._source_end,
                output,
                mappings,
                output_cursor,
            )
        else:
            _append_mapped(
                selected[index],
                units[index]._source_start,
                units[index]._source_end,
                output,
                mappings,
                output_cursor,
            )
    return PhoneticRepresentation(String(source), output^, mappings^)


def _push_unique(
    mut output: List[PhoneticRepresentation],
    var representation: PhoneticRepresentation,
    max_count: Int,
):
    if len(output) >= max_count:
        return
    for index in range(len(output)):
        if output[index]._text == representation._text:
            return
    output.append(representation^)


def _push_sequence(
    source: StringSlice,
    units: List[_PinyinUnit],
    selected: List[String],
    mut output: List[PhoneticRepresentation],
    max_count: Int,
) raises:
    if len(output) >= max_count:
        return
    _push_unique(
        output,
        _build_representation(source, units, selected, _FULL),
        max_count,
    )
    if len(output) >= max_count:
        return
    _push_unique(
        output,
        _build_representation(source, units, selected, _JOINED),
        max_count,
    )
    if len(output) >= max_count:
        return
    _push_unique(
        output,
        _build_representation(source, units, selected, _INITIALS),
        max_count,
    )


def _primary_representation(
    source: StringSlice, form: Int
) raises -> PhoneticRepresentation:
    var units = _scan_units(source, 1)
    var selected = _primary_readings(units)
    return _build_representation(source, units, selected, form)


def pinyin_full(source: StringSlice) raises -> PhoneticRepresentation:
    """Return primary pinyin with unmapped spaces between syllables."""
    return _primary_representation(source, _FULL)


def pinyin_joined(source: StringSlice) raises -> PhoneticRepresentation:
    """Return primary pinyin without separators."""
    return _primary_representation(source, _JOINED)


def pinyin_initials(source: StringSlice) raises -> PhoneticRepresentation:
    """Return the first scalar of every primary pinyin syllable."""
    return _primary_representation(source, _INITIALS)


def pinyin_representations(
    source: StringSlice,
    max_count: Int = 8,
    polyphone: ChinesePolyphoneMode = ChinesePolyphoneMode.COMMON,
) raises -> List[PhoneticRepresentation]:
    """Build capped search representations in Yuru-compatible order.

    Each reading sequence contributes full, joined, and initials forms, with
    duplicate text removed. `COMMON` adds one single-character substitution at
    a time, ordered first by reading index and then by source position. No
    combinations are generated, so work remains linear in the number of mapped
    source scalars under the explicit `max_count` cap.
    """
    if max_count < 0:
        raise Error("max_count must be nonnegative; got " + String(max_count))
    var output = List[PhoneticRepresentation](capacity=max_count)
    if max_count == 0:
        return output^

    var reading_limit = 3
    if polyphone == ChinesePolyphoneMode.NONE or max_count <= 3:
        reading_limit = 1
    var units = _scan_units(source, reading_limit)
    if len(units) == 0:
        return output^
    var selected = _primary_readings(units)
    _push_sequence(source, units, selected, output, max_count)
    if polyphone == ChinesePolyphoneMode.NONE:
        return output^

    var max_readings = 1
    for index in range(len(units)):
        max_readings = max(max_readings, len(units[index]._readings))
    for reading_index in range(1, max_readings):
        for unit_index in range(len(units)):
            if reading_index >= len(units[unit_index]._readings):
                continue
            var primary = selected[unit_index].copy()
            selected[unit_index] = units[unit_index]._readings[reading_index].copy()
            _push_sequence(source, units, selected, output, max_count)
            selected[unit_index] = primary^
            if len(output) >= max_count:
                return output^
    return output^
