#!/usr/bin/env bash

set -euo pipefail

metadata_only=false
if [[ "${1:-}" == "--metadata-only" ]]; then
  metadata_only=true
  shift
fi

if [[ $# -ne 1 ]]; then
  echo "usage: $0 [--metadata-only] vX.Y.Z" >&2
  exit 2
fi

tag="$1"
if [[ ! "$tag" =~ ^v([0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
  echo "release tag '$tag' must have the form vX.Y.Z" >&2
  exit 1
fi
version="${BASH_REMATCH[1]}"

if [[ "$metadata_only" == false ]]; then
  object_type="$(git cat-file -t "refs/tags/$tag" 2>/dev/null || true)"
  if [[ "$object_type" != "tag" ]]; then
    echo "release tag '$tag' must be an annotated tag" >&2
    exit 1
  fi

  tag_commit="$(git rev-list -n 1 "$tag")"
  head_commit="$(git rev-parse HEAD)"
  if [[ "$tag_commit" != "$head_commit" ]]; then
    echo "release tag '$tag' does not point to checked-out commit $head_commit" >&2
    exit 1
  fi

  release_commit="${GITHUB_SHA:-$tag_commit}"
  if [[ "$release_commit" != "$tag_commit" ]]; then
    echo "release event commit $release_commit does not match tag commit $tag_commit" >&2
    exit 1
  fi
  if ! git merge-base --is-ancestor "$release_commit" refs/remotes/origin/main; then
    echo "release commit $release_commit must already be on origin/main" >&2
    exit 1
  fi
fi

pixi_version="$(sed -n 's/^version = "\([^"]*\)"$/\1/p' pixi.toml)"
recipe_version="$(sed -n 's/^  version: "\([^"]*\)"$/\1/p' conda.recipe/recipe.yaml)"
if [[ "$pixi_version" != "$version" || "$recipe_version" != "$version" ]]; then
  echo "tag version '$version', Pixi version '$pixi_version', and recipe version '$recipe_version' must match" >&2
  exit 1
fi

if ! grep -Eq "^## \[$version\] - [0-9]{4}-[0-9]{2}-[0-9]{2}$" CHANGELOG.md; then
  echo "CHANGELOG.md needs a dated [$version] release heading" >&2
  exit 1
fi

if ! grep -qx 'mojo = "==1\.0\.0"' pixi.toml; then
  echo "pixi.toml must exactly pin Mojo 1.0.0" >&2
  exit 1
fi

recipe_compiler_pins="$(grep -Ec '^    - mojo-compiler =1\.0\.0$' conda.recipe/recipe.yaml || true)"
if [[ "$recipe_compiler_pins" -ne 3 ]]; then
  echo "the recipe must exactly pin mojo-compiler 1.0.0 for build, host, and run" >&2
  exit 1
fi

echo "release metadata for $tag is consistent"
