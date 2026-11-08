# The Verus release this flake builds, and what it pins: read from the release's own rust-toolchain.toml,
# source/tools/get-z3.sh and source/vstd/Cargo.toml.
{
  version = "0.2026.11.02.8bf68ee";
  rev = "8bf68ee741df833ea5d0fe6a2255126fdea87e47";
  hash = "sha256-xrqVYLYBCJISJhf4KPJ2U/92fDvTY9ks76z1zmzKUk8=";
  rust = "1.99.1";
  z3 = {
    version = "4.16.0";
    hash = "sha256-DnhX3kxggnFmyYwXEPBsBA1rh4oor1oIJR5TMJk/jvc=";
  };
  # What a crate verified with this release depends on, from crates.io.
  vstd = "0.0.0-2026-11-01-0251";
}
