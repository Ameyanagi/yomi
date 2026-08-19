#!/usr/bin/env bash
set -euo pipefail

find src tests examples conda.recipe -type f -name '*.mojo' -print0 \
  | xargs -0 mojo format -l 88
