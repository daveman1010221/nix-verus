# Verus from its release tag: rust_verify, the verus driver and cargo-verus, built with the toolchain the release pins,
# then vstd built, and verified, by them (Verus's BUILD.md, "Build with Cargo"; source/Makefile.toml). The release layout is
# Verus's own: the driver finds rust_verify, vstd.vir and the builtin libraries beside it. The wrappers tell it not to look
# for rustup (VERUS_USE_RUSTUP=0) and give it the pinned toolchain and Z3 instead.
{
  lib,
  stdenv,
  fetchFromGitHub,
  makeRustPlatform,
  makeWrapper,
  git,
  pkg-config,
  zstd,
  release,
  toolchain,
  z3,
}:
let
  rustPlatform = makeRustPlatform {
    cargo = toolchain;
    rustc = toolchain;
  };
  # The date in the release's version, 0.YYYY.MM.DD.sha.
  releaseDate =
    let
      parts = lib.splitString "." release.version;
    in
    "${builtins.elemAt parts 1}-${builtins.elemAt parts 2}-${builtins.elemAt parts 3}T00:00:00Z";
  # As rustup names it, which the driver is stamped with.
  toolchainName = "${release.rust}-${stdenv.hostPlatform.rust.rustcTarget}";
  src = fetchFromGitHub {
    owner = "verus-lang";
    repo = "verus";
    rev = release.rev;
    hash = release.hash;
  };
in
stdenv.mkDerivation {
  pname = "verus";
  inherit (release) version;
  inherit src;

  cargoRoot = "source";
  cargoDeps = rustPlatform.importCargoLock {
    lockFile = "${src}/source/Cargo.lock";
    outputHashes = {
      "getopts-0.2.21" = "sha256-N/QJvyOmLoU5TabrXi8i0a5s23ldeupmBUzP8waVOiU=";
    };
  };

  nativeBuildInputs = [
    rustPlatform.cargoSetupHook
    toolchain
    makeWrapper
    pkg-config
    git
  ];
  # zstd-sys, by way of the release-archive tooling's dependencies.
  buildInputs = [ zstd ];

  # What rust_verify's build script stamps into it (otherwise read from git).
  VARGO_BUILD_VERSION = release.version;
  VARGO_BUILD_SHA = release.rev;
  VARGO_BUILD_PROFILE = "release";

  buildPhase = ''
    runHook preBuild
    # rust_verify's build script reads its version from git whatever else it is told: the source, committed once, dated
    # from the release's own version, so that the build stays the same every time.
    export GIT_AUTHOR_DATE=${releaseDate} GIT_COMMITTER_DATE=${releaseDate}
    git init -q
    git add -A
    git -c user.name=nix-verus -c user.email=nix-verus@localhost commit -q -m "verus ${release.version}"
    cd source
    export HOME=$TMPDIR
    # rust_verify links rustc's own libraries; at build and at run time they are the toolchain's.
    export LD_LIBRARY_PATH=${toolchain}/lib
    ln -s ${z3}/bin/z3 z3

    # The verus crate's build script asks rustup for the active toolchain, to stamp its name into the driver. There is no
    # rustup here: the toolchain is the pinned one, and a stand-in says so.
    mkdir -p $TMPDIR/shim
    cat > $TMPDIR/shim/rustup <<SHIM
    #!${stdenv.shell}
    echo "${toolchainName} (overridden by the nix-verus build)"
    SHIM
    chmod +x $TMPDIR/shim/rustup
    export PATH=$TMPDIR/shim:$PATH
    export VARGO_TOOLCHAIN=${toolchainName}

    cargo build --release --offline -p rust_verify -p verus -p cargo-verus

    export PATH=$PWD/target-verus/release:$PATH
    export VERUS_USE_RUSTUP=0
    export VERUS_Z3_PATH=$PWD/z3
    cargo-verus build --release --offline --manifest-path vstd/Cargo.toml
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/verus $out/bin
    cp -R target-verus/release/. $out/lib/verus/
    rm -rf $out/lib/verus/{.fingerprint,incremental,build,examples}
    find $out/lib/verus -name '*.d' -delete
    rm -f $out/lib/verus/z3
    ln -s ${z3}/bin/z3 $out/lib/verus/z3

    for tool in verus cargo-verus; do
      makeWrapper $out/lib/verus/$tool $out/bin/$tool \
        --set VERUS_USE_RUSTUP 0 \
        --set-default VERUS_Z3_PATH ${z3}/bin/z3 \
        --prefix LD_LIBRARY_PATH : ${toolchain}/lib \
        --prefix PATH : ${toolchain}/bin:$out/lib/verus \
        --set-default CARGO ${toolchain}/bin/cargo
    done
    runHook postInstall
  '';

  passthru = {
    inherit toolchain z3;
    vstd = release.vstd;
  };

  meta = {
    description = "Verus: verified Rust, by SMT, at release ${release.version}";
    homepage = "https://github.com/verus-lang/verus";
    license = lib.licenses.mit;
    mainProgram = "verus";
    platforms = lib.platforms.linux;
  };
}
