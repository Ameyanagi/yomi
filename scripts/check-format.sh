#!/usr/bin/env bash
set -euo pipefail

format_check_dir=$(mktemp -d "${TMPDIR:-/tmp}/yomi-format-check.XXXXXX")
cleanup() {
  if [[ -n "${format_check_dir:-}" && -d "$format_check_dir" ]]; then
    rm -rf -- "$format_check_dir"
  fi
}
trap cleanup EXIT

source_files=()
formatted_files=()
while IFS= read -r -d '' source_file; do
  formatted_file="$format_check_dir/$source_file"
  mkdir -p "$(dirname "$formatted_file")"
  cp "$source_file" "$formatted_file"
  source_files+=("$source_file")
  formatted_files+=("$formatted_file")
done < <(find src tests examples conda.recipe -type f -name '*.mojo' -print0)

mojo format --quiet -l 88 "${formatted_files[@]}"
status=0
for index in "${!source_files[@]}"; do
  if ! cmp --silent "${source_files[$index]}" "${formatted_files[$index]}"; then
    printf '%s\n' "Formatting required: ${source_files[$index]}" >&2
    diff -u "${source_files[$index]}" "${formatted_files[$index]}" || true
    status=1
  fi
done

if [[ $status -ne 0 ]]; then
  printf '%s\n' 'Run `pixi run format` to apply Mojo formatting.' >&2
  exit "$status"
fi
printf '%s\n' 'Mojo formatting check passed.'
