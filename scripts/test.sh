#!/usr/bin/env bash
set -euo pipefail

for test_file in tests/test_*.mojo; do
  mojo run -I src -I tests "$test_file"
done

mkdir -p .pixi/test-bin
for example_file in examples/*.mojo; do
  example_name=$(basename "$example_file" .mojo)
  mojo build -I src "$example_file" -o ".pixi/test-bin/$example_name"
done
