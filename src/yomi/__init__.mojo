"""CJK phonetic representations with exact source-byte mappings."""

from .korean import decompose_hangul, hangul_choseong
from .representation import PhoneticRepresentation, SourceMapping, SourceRange
