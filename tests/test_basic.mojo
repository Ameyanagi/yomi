from yomi._scaffold import scaffold_name
from std.testing import TestSuite, assert_equal


def test_scaffold_name() raises:
    assert_equal(scaffold_name(), "yomi")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
