from yomi._scaffold import scaffold_name
from std.testing import assert_equal


def main() raises:
    assert_equal(scaffold_name(), "yomi")
