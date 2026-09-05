from std.testing import TestSuite, assert_equal, assert_raises, assert_true
from yomi import SearchKeyBundle, SearchKeyKind
from yomi.japanese.ipadic import IpadicReadingProvider


def _has(
    bundle: SearchKeyBundle, kind: SearchKeyKind, text: StringSlice
) raises -> Bool:
    for index in range(bundle.count()):
        var key = bundle.key(index)
        if key.kind() == kind and key.text_equals(text):
            return True
    return False


def test_names_and_alternatives() raises:
    var provider = IpadicReadingProvider("tests/fixtures/ipadic/readings.tsv")
    assert_equal(provider.entry_count(), 10)
    provider.validate()
    var names = provider.candidate_keys("佐藤")
    assert_true(_has(names, SearchKeyKind.JAPANESE_KANA, "さとう"))
    assert_true(_has(names, SearchKeyKind.JAPANESE_ROMAJI, "satou"))
    var ambiguous = provider.candidate_keys("日本")
    assert_true(_has(ambiguous, SearchKeyKind.JAPANESE_KANA, "にっぽん"))
    assert_true(_has(ambiguous, SearchKeyKind.JAPANESE_KANA, "にほん"))


def test_longest_match_and_exact_source_byte_projection() raises:
    var provider = IpadicReadingProvider("tests/fixtures/ipadic/readings.tsv")
    var source = String("🙂佐藤・日本")
    var bundle = provider.candidate_keys(source)
    var kana_found = False
    var romaji_found = False
    for index in range(bundle.count()):
        var key = bundle.key(index)
        var value = key.representation()
        assert_equal(value.source_text(), source)
        value.validate()
        if key.text_equals("🙂さとう・にっぽん"):
            kana_found = True
            var ranges = value.source_ranges_for_output(4, 7)
            assert_equal(len(ranges), 1)
            assert_equal(ranges[0].start(), 4)
            assert_equal(ranges[0].end(), 10)
            var japan = value.source_ranges_for_output(16, 28)
            assert_equal(japan[0].start(), 13)
            assert_equal(japan[0].end(), 19)
        if key.text_equals("🙂satou・nippon"):
            romaji_found = True
            var ranges = value.source_ranges_for_output(4, 5)
            assert_equal(len(ranges), 1)
            assert_equal(ranges[0].start(), 4)
            assert_equal(ranges[0].end(), 10)
    assert_true(kana_found)
    assert_true(romaji_found)
    var longest = provider.candidate_keys("日本橋")
    assert_true(_has(longest, SearchKeyKind.JAPANESE_KANA, "にっぽんばし"))
    assert_true(_has(longest, SearchKeyKind.JAPANESE_KANA, "にほんばし"))
    var tokyo = provider.candidate_keys("東京大学")
    for index in range(tokyo.count()):
        var key = tokyo.key(index)
        if key.text_equals("とうきょうだいがく"):
            var value = key.representation()
            var ranges = value.source_ranges_for_output(0, 3)
            assert_equal(ranges[0].start(), 0)
            assert_equal(ranges[0].end(), 12)


def test_unknown_graphemes_and_compatibility_folds() raises:
    var provider = IpadicReadingProvider("tests/fixtures/ipadic/readings.tsv")
    var unknown = provider.candidate_keys("𠮷☃")
    for index in range(unknown.count()):
        var key = unknown.key(index)
        assert_true(key.text_equals("𠮷☃"))
        key.representation().validate()
    var mixed = provider.candidate_keys("Ａ佐藤ｶﾞ")
    assert_true(_has(mixed, SearchKeyKind.JAPANESE_KANA, "aさとうが"))
    assert_equal(provider.candidate_keys("").count(), 3)


def test_count_and_byte_caps_preserve_base_keys_and_bound_ambiguity() raises:
    var provider = IpadicReadingProvider("tests/fixtures/ipadic/readings.tsv")
    assert_equal(provider.candidate_keys("日本", 0).count(), 0)
    for cap in range(2, 9):
        var bundle = provider.candidate_keys("上田生田山田", cap)
        assert_true(bundle.count() <= cap)
        assert_true(bundle.key(0).kind() == SearchKeyKind.ORIGINAL)
        assert_true(bundle.key(1).kind() == SearchKeyKind.NORMALIZED)
    for byte_cap in range(0, 49):
        var bundle = provider.candidate_keys("日本", 8, byte_cap)
        var generated_bytes = 0
        for index in range(bundle.count()):
            var key = bundle.key(index)
            if (
                key.kind() != SearchKeyKind.ORIGINAL
                and key.kind() != SearchKeyKind.NORMALIZED
            ):
                generated_bytes += key.text_byte_length()
        assert_true(generated_bytes <= byte_cap)
    # The kana form cannot fit in the remaining five bytes, but its romaji can.
    var tight = provider.candidate_keys("佐藤", 8, 11)
    assert_true(_has(tight, SearchKeyKind.JAPANESE_ROMAJI, "satou"))
    assert_true(not _has(tight, SearchKeyKind.JAPANESE_KANA, "さとう"))
    assert_equal(provider.candidate_keys("日本", 8, 0).count(), 2)
    with assert_raises(contains="max_count must be zero or within [2, 8]"):
        _ = provider.candidate_keys("日本", 1)
    with assert_raises(contains="max_total_key_bytes must be nonnegative"):
        _ = provider.candidate_keys("日本", 8, -1)
    var first = provider.candidate_keys("生田")
    var second = provider.candidate_keys("生田")
    assert_true(_has(first, SearchKeyKind.JAPANESE_KANA, "いくた"))
    assert_true(_has(first, SearchKeyKind.JAPANESE_KANA, "いけだ"))
    assert_true(_has(first, SearchKeyKind.JAPANESE_KANA, "おいだ"))
    assert_equal(first.count(), second.count())
    for index in range(first.count()):
        assert_equal(first.key(index).text(), second.key(index).text())


def test_invalid_dictionary_files_raise_before_use() raises:
    with assert_raises(contains="IPADIC header must match"):
        _ = IpadicReadingProvider("tests/fixtures/ipadic/invalid-header.tsv")
    with assert_raises(contains="IPADIC surface must be unique"):
        _ = IpadicReadingProvider("tests/fixtures/ipadic/duplicate-surface.tsv")
    with assert_raises(contains="IPADIC reading must be unique"):
        _ = IpadicReadingProvider("tests/fixtures/ipadic/duplicate-reading.tsv")
    with assert_raises(contains="IPADIC dictionary must contain at least one surface"):
        _ = IpadicReadingProvider("tests/fixtures/ipadic/empty.tsv")


def test_dictionary_rejects_noncanonical_and_delimiter_heavy_input() raises:
    with assert_raises(contains="IPADIC readings must be in lexical order"):
        _ = IpadicReadingProvider("tests/fixtures/ipadic/unsorted.tsv")
    with assert_raises(contains="must not contain ASCII control characters"):
        _ = IpadicReadingProvider("tests/fixtures/ipadic/nul-reading.tsv")
    with assert_raises(contains="must not contain ASCII control characters"):
        _ = IpadicReadingProvider("tests/fixtures/ipadic/cr-surface.tsv")
    with assert_raises(contains="must contain a surface and 1..12 readings"):
        _ = IpadicReadingProvider("tests/fixtures/ipadic/many-fields.tsv")
    with assert_raises(contains="must contain a surface and 1..12 readings"):
        _ = IpadicReadingProvider("tests/fixtures/ipadic/many-lines.tsv")
    var provider = IpadicReadingProvider("tests/fixtures/ipadic/readings.tsv")
    provider._entries[String("日本")][0] = "にほん\r"
    with assert_raises(contains="must not contain ASCII control characters"):
        provider.validate()


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
