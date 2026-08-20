"""Internal canonical composition for standard kana voicing marks."""

from std.collections import Optional


comptime _DAKUTEN = 0x3099
comptime _HANDAKUTEN = 0x309A


def _compose_hiragana_voicing(base: Int, mark: Int) -> Optional[Int]:
    if mark == _DAKUTEN:
        if base == 0x3046:
            return 0x3094
        if base >= 0x304B and base <= 0x3053 and (base - 0x304B) % 2 == 0:
            return base + 1
        if base >= 0x3055 and base <= 0x305D and (base - 0x3055) % 2 == 0:
            return base + 1
        if base == 0x305F or base == 0x3061 or base == 0x3064:
            return base + 1
        if base == 0x3066 or base == 0x3068:
            return base + 1
        if base >= 0x306F and base <= 0x307B and (base - 0x306F) % 3 == 0:
            return base + 1
    elif mark == _HANDAKUTEN:
        if base >= 0x306F and base <= 0x307B and (base - 0x306F) % 3 == 0:
            return base + 2
    return None


def _compose_kana_voicing(base: Int, mark: Int) -> Optional[Int]:
    """Compose one standard kana base and combining voicing mark.

    The excluded wa-row combinations deliberately return ``None``. This helper
    keeps composition independent from romanization so the script converters
    can reuse exactly the same NFC/NFD policy.
    """
    if base >= 0x30A1 and base <= 0x30F6:
        var composed = _compose_hiragana_voicing(base - 0x60, mark)
        if composed:
            return composed.value() + 0x60
        return None
    return _compose_hiragana_voicing(base, mark)
