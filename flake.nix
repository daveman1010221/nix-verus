{
  description = "Verus (verified Rust) built from its release tag, with its pinned Rust toolchain and Z3";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, rust-overlay, ... }:
  let
    # Verus's prebuilt releases are for Ubuntu x86_64, macOS and Windows; this builds from source, on Linux.
    systems = [ "x86_64-linux" "aarch64-linux" ];
    forAllSystems = f: nixpkgs.lib.genAttrs systems (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ rust-overlay.overlays.default ];
        };
      in f { inherit pkgs system; }
    );
  in {
    packages = forAllSystems ({ pkgs, ... }:
      let
        release = import ./release.nix;
        # The private toolchain Verus verifies with, as its rust-toolchain.toml pins it: rust_verify links rustc's own
        # crates (rustc-dev).
        toolchain = pkgs.rust-bin.stable.${release.rust}.minimal.override {
          extensions = [ "rustc-dev" "llvm-tools" "rustfmt" ];
        };
        z3 = pkgs.callPackage ./pkgs/z3.nix { inherit release; };
        verus = pkgs.callPackage ./pkgs/verus.nix { inherit release toolchain z3; };
      in {
        inherit toolchain z3 verus;
        default = verus;
      });

    checks = forAllSystems ({ pkgs, system }:
      pkgs.callPackage ./tests { verus = self.packages.${system}.verus; });

    formatter = forAllSystems ({ pkgs, ... }: pkgs.alejandra);
  };
}
