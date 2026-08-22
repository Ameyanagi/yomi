"""Typed search keys and Yuru-compatible query/candidate gates."""

from std.collections import List

from .representation import PhoneticRepresentation


struct SearchKeyKind(Copyable, Equatable, ImplicitlyCopyable):
    """Nominal kind for one candidate key or query variant.

    Candidate and query kinds deliberately share one nominal type because the
    compatibility relation consumes exactly one of each. Underscore-prefixed
    storage is private by convention; callers use the comptime constants.
    """

    var _value: Int

    comptime ORIGINAL = SearchKeyKind(_value=0)
    comptime NORMALIZED = SearchKeyKind(_value=1)
    comptime JAPANESE_KANA = SearchKeyKind(_value=2)
    comptime JAPANESE_ROMAJI = SearchKeyKind(_value=3)
    comptime CHINESE_PINYIN_FULL = SearchKeyKind(_value=4)
    comptime CHINESE_PINYIN_JOINED = SearchKeyKind(_value=5)
    comptime CHINESE_PINYIN_INITIALS = SearchKeyKind(_value=6)
    comptime KOREAN_ROMANIZED = SearchKeyKind(_value=7)
    comptime KOREAN_INITIALS = SearchKeyKind(_value=8)
    comptime KOREAN_KEYBOARD = SearchKeyKind(_value=9)
    comptime LEARNED_ALIAS = SearchKeyKind(_value=10)

    comptime QUERY_ORIGINAL = SearchKeyKind(_value=32)
    comptime QUERY_NORMALIZED = SearchKeyKind(_value=33)
    comptime QUERY_JAPANESE_KANA = SearchKeyKind(_value=34)
    comptime QUERY_JAPANESE_ROMAJI_TO_KANA = SearchKeyKind(_value=35)
    comptime QUERY_CHINESE_PINYIN = SearchKeyKind(_value=36)
    comptime QUERY_INITIALS = SearchKeyKind(_value=37)

    def __init__(out self, *, _value: Int):
        self._value = _value

    def __eq__(self, other: Self) -> Bool:
        return self._value == other._value

    def is_query(self) -> Bool:
        """Return whether this value is a query-variant kind."""
        return self._value >= 32

    def default_weight(self) -> Int:
        """Return Yuru's current default score adjustment for this kind."""
        if self == SearchKeyKind.ORIGINAL:
            return 3000
        if self == SearchKeyKind.NORMALIZED:
            return 2800
        if self == SearchKeyKind.JAPANESE_KANA:
            return 1700
        if self == SearchKeyKind.JAPANESE_ROMAJI:
            return 1800
        if self == SearchKeyKind.CHINESE_PINYIN_FULL:
            return 1750
        if self == SearchKeyKind.CHINESE_PINYIN_JOINED:
            return 1800
        if self == SearchKeyKind.CHINESE_PINYIN_INITIALS:
            return 1850
        if self == SearchKeyKind.KOREAN_ROMANIZED:
            return 1800
        if self == SearchKeyKind.KOREAN_INITIALS:
            return 1850
        if self == SearchKeyKind.KOREAN_KEYBOARD:
            return 1750
        if self == SearchKeyKind.LEARNED_ALIAS:
            return 2500
        if self == SearchKeyKind.QUERY_ORIGINAL:
            return 500
        if self == SearchKeyKind.QUERY_NORMALIZED:
            return 450
        if self == SearchKeyKind.QUERY_JAPANESE_KANA:
            return 350
        if self == SearchKeyKind.QUERY_JAPANESE_ROMAJI_TO_KANA:
            return 200
        if self == SearchKeyKind.QUERY_CHINESE_PINYIN:
            return 250
        if self == SearchKeyKind.QUERY_INITIALS:
            return 250
        return 0


def search_key_kinds_compatible(
    query: SearchKeyKind,
    candidate: SearchKeyKind,
) -> Bool:
    """Return whether a typed query may score one candidate-key kind.

    The relation mirrors Yuru's language gates. Keeping it in Yomi lets
    Yuragi reject unrelated CJK key pairs before invoking a matcher.
    """
    if query == SearchKeyKind.QUERY_ORIGINAL or query == SearchKeyKind.QUERY_NORMALIZED:
        return (
            candidate == SearchKeyKind.ORIGINAL
            or candidate == SearchKeyKind.NORMALIZED
            or candidate == SearchKeyKind.JAPANESE_ROMAJI
            or candidate == SearchKeyKind.CHINESE_PINYIN_FULL
            or candidate == SearchKeyKind.CHINESE_PINYIN_JOINED
            or candidate == SearchKeyKind.KOREAN_ROMANIZED
            or candidate == SearchKeyKind.KOREAN_INITIALS
            or candidate == SearchKeyKind.KOREAN_KEYBOARD
            or candidate == SearchKeyKind.LEARNED_ALIAS
        )
    if (
        query == SearchKeyKind.QUERY_JAPANESE_KANA
        or query == SearchKeyKind.QUERY_JAPANESE_ROMAJI_TO_KANA
    ):
        return candidate == SearchKeyKind.JAPANESE_KANA
    if query == SearchKeyKind.QUERY_CHINESE_PINYIN:
        return (
            candidate == SearchKeyKind.CHINESE_PINYIN_FULL
            or candidate == SearchKeyKind.CHINESE_PINYIN_JOINED
        )
    if query == SearchKeyKind.QUERY_INITIALS:
        return (
            candidate == SearchKeyKind.CHINESE_PINYIN_INITIALS
            or candidate == SearchKeyKind.KOREAN_INITIALS
            or candidate == SearchKeyKind.LEARNED_ALIAS
        )
    return False


struct SearchKey(Copyable):
    """One typed, source-preserving candidate key or query variant."""

    var _kind: SearchKeyKind
    var _representation: PhoneticRepresentation

    def __init__(
        out self,
        kind: SearchKeyKind,
        var representation: PhoneticRepresentation,
    ):
        self._kind = kind
        self._representation = representation^

    def kind(self) -> SearchKeyKind:
        """Return the nominal compatibility kind."""
        return self._kind

    def source_text(self) -> String:
        """Return a copy of the original text."""
        return self._representation.source_text()

    def text(self) -> String:
        """Return a copy of the searchable text."""
        return self._representation.text()

    def text_byte_length(self) -> Int:
        """Return the searchable UTF-8 byte length without copying text."""
        return self._representation.text_byte_length()

    def text_equals(self, value: StringSlice) -> Bool:
        """Compare searchable text without allocating a detached string."""
        return self._representation.text_equals(value)

    def has_same_text(self, other: Self) -> Bool:
        """Compare searchable text while intentionally ignoring key kind."""
        return self._representation.has_same_text(other._representation)

    def has_representation_text(self, other: PhoneticRepresentation) -> Bool:
        """Compare searchable text with a representation without copying."""
        return self._representation.has_same_text(other)

    def weight(self) -> Int:
        """Return the default score adjustment for this key's kind."""
        return self._kind.default_weight()

    def representation(self) -> PhoneticRepresentation:
        """Return a detached source-preserving representation."""
        return self._representation.copy()

    def take_representation(deinit self) -> PhoneticRepresentation:
        """Consume this key and return its owned representation without copying."""
        return self._representation^


struct SearchKeyBundle(Copyable):
    """A validated owned key list with an explicit construction cap."""

    var _keys: List[SearchKey]
    var _max_count: Int

    def __init__(
        out self,
        var keys: List[SearchKey],
        max_count: Int,
    ) raises:
        self._keys = keys^
        self._max_count = max_count
        self.validate()

    def validate(self) raises:
        """Validate the stored cap and count explicitly."""
        if self._max_count < 0:
            raise Error("max_count must be nonnegative; got " + String(self._max_count))
        if len(self._keys) > self._max_count:
            raise Error(
                "search key count must not exceed max_count "
                + String(self._max_count)
                + "; got "
                + String(len(self._keys))
            )

    def count(self) -> Int:
        """Return the number of keys in the bundle."""
        return len(self._keys)

    def max_count(self) -> Int:
        """Return the cap enforced when the bundle was constructed."""
        return self._max_count

    def key(self, index: Int) raises -> SearchKey:
        """Return one detached key, rejecting an invalid index."""
        if index < 0 or index >= len(self._keys):
            raise Error(
                "search key index must be within [0, "
                + String(len(self._keys))
                + "); got "
                + String(index)
            )
        return self._keys[index].copy()

    def snapshot(self) -> List[SearchKey]:
        """Return a detached copy of all keys."""
        return self._keys.copy()

    def take_keys(deinit self) -> List[SearchKey]:
        """Consume this bundle and return its owned key storage without copying."""
        return self._keys^
