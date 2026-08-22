#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "usage: $0 PACKAGE VERSION SUBDIR" >&2
  exit 2
fi

expected_package=$1
expected_version=$2
expected_subdir=$3

artifacts=()
while IFS= read -r artifact; do
  artifacts+=("$artifact")
done < <(
  find "output/$expected_subdir" -maxdepth 1 -type f \
    -name "${expected_package}-${expected_version}-*.conda" -print
)

if [[ ${#artifacts[@]} -ne 1 ]]; then
  echo "expected one ${expected_package} ${expected_version} artifact for ${expected_subdir}, found ${#artifacts[@]}" >&2
  exit 1
fi

package_index=$(pixi run --locked rattler-build package inspect --json "${artifacts[0]}")
jq -e \
  --arg package "$expected_package" \
  --arg version "$expected_version" \
  --arg subdir "$expected_subdir" \
  '.index
    | .name == $package
      and .version == $version
      and .subdir == $subdir
      and .build_number == 0
      and .depends == ["mojo-compiler ==1.0.0"]' \
  <<<"$package_index" >/dev/null

printf 'validated %s\n' "${artifacts[0]}"
