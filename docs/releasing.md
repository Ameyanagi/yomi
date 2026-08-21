# Releasing

1. Run `pixi run --locked check` and `pixi run --locked package` on a clean tree.
2. Update the changelog, compatibility notes, and package version.
3. Tag the exact tested commit as `vX.Y.Z`.
4. Replace the local `source.path` in the modular-community recipe submission
   with the repository URL and full 40-character tag commit SHA.
5. Reset the Conda build number to zero for a new version; increment it only
   when rebuilding the same source version.
6. Verify the tag workflow's package gate builds and tests the installed package
   on every supported target before it creates the source release.
7. Publish benchmark results only with the checked-in methodology.

The tag workflow creates a source archive only after both the normal check
matrix and a full Rattler package/install/smoke matrix pass. The smoke test must
exercise public transformed/source text, mapping endpoints, exact source-range
projection, and NFC/NFD choseong equivalence—not merely import the package.
Publishing to modular-community remains a separate reviewed operation.
