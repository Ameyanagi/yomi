# Releasing

1. Set the same `X.Y.Z` version in `pixi.toml` and
   `conda.recipe/recipe.yaml`, keep all development and package compiler pins
   at the exact supported Mojo version, and add a dated changelog section.
2. Run `pixi lock --check`, `pixi run --locked check`, and
   `pixi run --locked package` on a clean tree.
3. Commit the release metadata and merge that exact tested commit into `main`.
4. Create and push an annotated tag on that commit:
   `git tag -a vX.Y.Z -m "Yomi vX.Y.Z"`. The release workflow rejects
   lightweight tags, commits outside
   `origin/main`, tag/version mismatches, missing dated changelog entries, and
   compiler pin drift.
5. Dispatch the central `Ameyanagi/mojo-channel` build for repository `yomi`,
   the immutable tag ref, and publishing enabled. That workflow rebuilds each
   supported native subdir, validates exact name/version/compiler metadata,
   and refuses to replace a different existing artifact.
6. Reset the Conda build number to zero for a new version; increment it only
   when rebuilding the same source version.
7. Verify the tag workflow's package gate builds and tests the installed package
   on every supported target before it creates the source release.
8. Publish benchmark results only with the checked-in methodology.

The tag workflow creates a source archive only after both the normal check
matrix and a full Rattler package/install/smoke matrix pass. The smoke test must
exercise public transformed/source text, mapping endpoints, exact source-range
projection, and NFC/NFD choseong equivalence—not merely import the package.
Publishing the three platform packages remains a separate, serialized,
reviewed channel operation after the source release succeeds.
