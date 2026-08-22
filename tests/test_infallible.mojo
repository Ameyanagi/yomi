from std.testing import TestSuite, assert_equal

from yomi import (
    compose_hangul,
    decompose_hangul,
    decompose_hangul_compatibility,
    hangul_choseong,
    to_hiragana,
    to_katakana,
    to_romaji,
)


def _call_all_transforms_without_raises() -> String:
    var result = to_romaji("カ").text()
    result += to_hiragana("カ").text()
    result += to_katakana("か").text()
    result += compose_hangul("ㅎㅏㄴ").text()
    result += decompose_hangul("한").text()
    result += decompose_hangul_compatibility("한").text()
    result += hangul_choseong("한").text()
    return result^


def test_public_transforms_are_callable_without_raises() raises:
    assert_equal(
        _call_all_transforms_without_raises(),
        "kaかカ한한ㅎㅏㄴㅎ",
    )


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
