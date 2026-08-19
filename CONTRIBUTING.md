# Contributing

Thanks for helping build Yomi.

## Development setup

1. Install Pixi.
2. Run `pixi install --locked`.
3. Run `pixi run check` before opening a pull request.

Use `pixi run format` to format Mojo sources. Do not edit `pixi.lock` directly;
update dependencies through Pixi and commit the resulting lock change.

## Changes

- Keep pull requests focused on one behavior or architectural decision.
- Add focused tests before fixing behavioral bugs.
- Treat compiler warnings as defects.
- Do not add runtime dependencies in Python, Rust, C, or C++ without an accepted
  design discussion.
- Keep generated files deterministic and record source version, checksum,
  license, generator command, and update procedure.
- Update the changelog and compatibility notes for user-visible changes.
- Benchmark performance work with checked-in methodology; do not add unsupported
  superiority claims.

## Public APIs

Root-package exports are deliberate compatibility commitments. Keep internal
implementation out of `src/yomi/__init__.mojo` until its contract is
documented and tested.
