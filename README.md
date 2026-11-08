# nix-verus

[Verus](https://github.com/verus-lang/verus) (verified Rust, proved by an SMT solver) built from its release tag with Nix,
with the Rust toolchain and the Z3 the release pins, so that a proof is checked by the same verifier and solver everywhere.

## What it builds

| | |
|---|---|
| Verus | `0.2026.11.02.8bf68ee`, from its tag (`release.nix`) |
| Rust | `1.99.1` with `rustc-dev`, from its `rust-toolchain.toml` (by `oxalica/rust-overlay`) |
| Z3 | `4.16.0`, from its `source/tools/get-z3.sh` (nixpkgs' recipe at that version's source) |
| vstd | built and verified with Verus (2,159 proofs); a crate depends on `vstd = "=0.0.0-2026-11-01-0251"` |

Verus is built as its `BUILD.md` and `source/Makefile.toml` say: `rust_verify`, the `verus` driver and `cargo-verus`, then
`vstd`, verified by them. Two things the upstream build reads from a developer's machine are given instead: the
toolchain's name, which the `verus` crate's build script asks `rustup` for (a stand-in answers with the pinned one), and a
git repository, which `rust_verify`'s build script reads its version from (the source, committed once, dated from the
release's version).

`bin/verus` and `bin/cargo-verus` wrap the release layout: they set `VERUS_USE_RUSTUP=0` (Verus's own way of trusting the
environment's toolchain), give it the pinned toolchain's libraries and `cargo`, and default `VERUS_Z3_PATH` to the pinned
Z3.

## Use

```sh
nix build .#verus            # the release, at ./result
nix shell .#verus -c verus file.rs
nix shell .#verus -c cargo-verus verify -p my_crate   # a crate with [package.metadata.verus] verify = true
nix flake check              # a true postcondition proves; a false one is refused
```

As an input:

```nix
inputs.nix-verus.url = "github:daveman1010221/nix-verus";
# packages.${system}.verus, .toolchain, .z3
```

A crate that opts in (`[package.metadata.verus] verify = true`, depending on `vstd`) still builds with plain `cargo`; its
proofs are erased. `cargo verus verify` fetches `vstd` from crates.io, at the pin above.

## Bumping

Change `release.nix` to the new release: its tag's commit and hash (`nix flake prefetch
github:verus-lang/verus/release/<version>`), the `channel` of its `rust-toolchain.toml`, the `z3_version` of its
`source/tools/get-z3.sh` (and that tag's hash), and the `version` of its `source/vstd/Cargo.toml`. The `getopts` git
dependency's hash in `pkgs/verus.nix` changes when its `Cargo.lock` does. Then `nix flake check`.
