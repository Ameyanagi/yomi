"""Optional external IPADIC reading dictionary with exact source mappings."""

from std.collections import Dict, List

from ..representation import PhoneticRepresentation, SourceMapping
from ..search_key import SearchKey, SearchKeyBundle, SearchKeyKind
from .search import (
    _romanize_key,
    _scan_input_units,
    japanese_candidate_keys,
    japanese_kana_key,
)

comptime _HEADER = (
    "# yomi-ipadic-v1\tIPADIC-2.7.0-20070801\t61b90ba6e669dc2d7d533d4a80d206f3b31d52b1"
)
comptime _MAX_FILE_BYTES = 32 * 1024 * 1024
comptime _MAX_ENTRIES = 350_000


struct _ReadingToken(Copyable):
    var start: Int
    var end: Int
    var readings: List[String]

    def __init__(out self, start: Int, end: Int, var readings: List[String]):
        self.start = start
        self.end = end
        self.readings = readings^


def _append_budgeted(
    mut keys: List[SearchKey],
    kind: SearchKeyKind,
    var value: PhoneticRepresentation,
    max_count: Int,
    max_bytes: Int,
    mut generated_bytes: Int,
):
    if len(keys) >= max_count or value.text_byte_length() > max_bytes - generated_bytes:
        return
    for key in keys:
        if key.kind() == kind and key.has_representation_text(value):
            return
    generated_bytes += value.text_byte_length()
    keys.append(SearchKey(kind, value^))


def _validate_field(value: StringSlice, kind: StringSlice, maximum: Int) raises:
    if value.byte_length() == 0 or value.byte_length() > maximum:
        raise Error(
            String(
                "IPADIC ",
                kind,
                " bytes must be within [1, ",
                maximum,
                "]; got ",
                value.byte_length(),
            )
        )
    for scalar in value.codepoints():
        var code = scalar.to_u32()
        if code < 32 or code == 127:
            raise Error(
                String(
                    "IPADIC ",
                    kind,
                    " must not contain ASCII control characters; got code point ",
                    code,
                    "; regenerate with install_ipadic.py",
                )
            )


def _validate_readings(readings: List[String], surface: StringSlice) raises:
    if len(readings) < 1 or len(readings) > 12:
        raise Error(
            String("IPADIC reading count must be within [1, 12]; got ", len(readings))
        )
    for index in range(len(readings)):
        _validate_field(readings[index], "reading", 256)
        if index > 0:
            if readings[index - 1] == readings[index]:
                raise Error(
                    String(
                        "IPADIC reading must be unique for surface ",
                        surface,
                        "; got ",
                        readings[index],
                    )
                )
            if readings[index - 1] > readings[index]:
                raise Error(
                    String(
                        "IPADIC readings must be in lexical order for surface ",
                        surface,
                        "; got ",
                        readings[index - 1],
                        " before ",
                        readings[index],
                    )
                )


struct IpadicReadingProvider(Movable):
    """Load an explicitly installed dictionary; no implicit download or discovery.

    The installer verifies all pinned IPADIC inputs and the generated artifact.
    This loader bounds and validates the external TSV representation. Keep the
    installed file trusted: format validation is not signature verification.
    Direct mutation of underscore-prefixed storage is outside the contract.

    Segmentation is deterministic longest matching surface at each original
    grapheme boundary, not contextual MeCab morphology. All readings of that
    token are retained in lexical order, with bounded Cartesian alternatives.
    Unknown graphemes pass through the standard kana normalization unchanged
    apart from its documented compatibility folds.
    """

    var _entries: Dict[String, List[String]]
    var _max_surface_bytes: Int

    def __init__(out self, path: StringSlice) raises:
        """Load `readings.tsv` from the explicit opt-in installation path."""
        self._entries = Dict[String, List[String]]()
        self._max_surface_bytes = 0
        var contents: String
        with open(String(path), "r") as stream:
            contents = stream.read(_MAX_FILE_BYTES + 1)
        if contents.byte_length() > _MAX_FILE_BYTES:
            raise Error(
                "IPADIC file must be at most 33554432 bytes; regenerate with"
                " install_ipadic.py"
            )
        var lines = StringSlice(contents).split("\n", maxsplit=_MAX_ENTRIES + 1)
        if len(lines) == 0 or String(lines[0]) != _HEADER:
            raise Error(
                "IPADIC header must match pinned yomi-ipadic-v1; regenerate with"
                " install_ipadic.py"
            )
        for line_index in range(1, len(lines)):
            if lines[line_index].byte_length() == 0 and line_index == len(lines) - 1:
                continue
            var fields = lines[line_index].split("\t", maxsplit=13)
            if len(fields) < 2 or len(fields) > 13:
                raise Error(
                    String(
                        "IPADIC row ",
                        line_index,
                        " must contain a surface and 1..12 readings; got ",
                        len(fields),
                        " fields",
                    )
                )
            var surface = String(fields[0])
            _validate_field(surface, "surface", 78)
            if surface in self._entries:
                raise Error(String("IPADIC surface must be unique; got ", surface))
            var readings = List[String](capacity=len(fields) - 1)
            for field_index in range(1, len(fields)):
                var reading = String(fields[field_index])
                readings.append(reading^)
            _validate_readings(readings, surface)
            if len(self._entries) >= _MAX_ENTRIES:
                raise Error(
                    "IPADIC surface count must not exceed 350000; regenerate with"
                    " install_ipadic.py"
                )
            self._max_surface_bytes = max(
                self._max_surface_bytes, surface.byte_length()
            )
            self._entries[surface^] = readings^
        if len(self._entries) == 0:
            raise Error("IPADIC dictionary must contain at least one surface; got 0")

    def entry_count(self) -> Int:
        """Return loaded surface count without rescanning the dictionary."""
        return len(self._entries)

    def validate(self) raises:
        """Explicitly check storage after unusual direct field access."""
        if len(self._entries) == 0 or len(self._entries) > _MAX_ENTRIES:
            raise Error("IPADIC dictionary surface count must be within [1, 350000]")
        var maximum = 0
        for surface in self._entries:
            _validate_field(surface, "surface", 78)
            maximum = max(maximum, surface.byte_length())
            _validate_readings(self._entries[surface], surface)
        if maximum != self._max_surface_bytes:
            raise Error("IPADIC maximum surface length must match stored entries")

    def _tokens(self, source: StringSlice) raises -> List[_ReadingToken]:
        var units = _scan_input_units(source)
        var tokens = List[_ReadingToken]()
        var position = 0
        while position < len(units):
            var start = units[position]._source_start
            var chosen_end = position + 1
            var chosen = String()
            var scan = position
            while scan < len(units):
                var end = units[scan]._source_end
                if end - start > self._max_surface_bytes:
                    break
                var surface = String(source[byte=start:end])
                if surface in self._entries:
                    chosen = surface^
                    chosen_end = scan + 1
                scan += 1
            var readings: List[String]
            if chosen.byte_length() > 0:
                readings = self._entries[chosen].copy()
            else:
                readings = [String(source[byte = start : units[position]._source_end])]
            tokens.append(
                _ReadingToken(start, units[chosen_end - 1]._source_end, readings^)
            )
            position = chosen_end
        return tokens^

    def candidate_keys(
        self,
        source: StringSlice,
        max_count: Int = 8,
        max_total_key_bytes: Int = 1024,
    ) raises -> SearchKeyBundle:
        """Append dictionary kana/romaji to the existing unified candidate bundle.

        Existing base and generated keys retain priority. All generated bytes,
        including built-in keys, share the requested budget; required original
        and normalized keys are exempt. At most `max_count` dictionary reading
        combinations are visited in lexical mixed-radix order. This caps work
        even when token ambiguities have an exponential Cartesian product.
        """
        var base = japanese_candidate_keys(source, max_count, max_total_key_bytes)
        var keys = base^.take_keys()
        if (
            len(keys) >= max_count
            or max_total_key_bytes == 0
            or source.byte_length() == 0
        ):
            return SearchKeyBundle(keys^, max_count)
        var generated_bytes = 0
        for key in keys:
            if (
                key.kind() != SearchKeyKind.ORIGINAL
                and key.kind() != SearchKeyKind.NORMALIZED
            ):
                generated_bytes += key.text_byte_length()
        if generated_bytes >= max_total_key_bytes:
            return SearchKeyBundle(keys^, max_count)
        var tokens = self._tokens(source)
        var choices = List[Int](length=len(tokens), fill=0)
        for _ in range(max_count):
            var text = String()
            var mappings = List[SourceMapping](capacity=len(tokens))
            for index in range(len(tokens)):
                var kana = japanese_kana_key(tokens[index].readings[choices[index]])
                var piece = kana.text()
                var start = text.byte_length()
                text += piece
                mappings.append(
                    SourceMapping(
                        start,
                        text.byte_length(),
                        tokens[index].start,
                        tokens[index].end,
                    )
                )
            var kana = PhoneticRepresentation(String(source), text^, mappings^)
            var romaji = _romanize_key(source, kana)
            _append_budgeted(
                keys,
                SearchKeyKind.JAPANESE_KANA,
                kana^,
                max_count,
                max_total_key_bytes,
                generated_bytes,
            )
            _append_budgeted(
                keys,
                SearchKeyKind.JAPANESE_ROMAJI,
                romaji^,
                max_count,
                max_total_key_bytes,
                generated_bytes,
            )
            if len(keys) >= max_count:
                break
            var digit = len(choices) - 1
            while digit >= 0:
                choices[digit] += 1
                if choices[digit] < len(tokens[digit].readings):
                    break
                choices[digit] = 0
                digit -= 1
            if digit < 0:
                break
        return SearchKeyBundle(keys^, max_count)
