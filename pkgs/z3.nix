# Z3 at the version Verus pins (its source/tools/get-z3.sh): nixpkgs' recipe, at that version's source. Verus checks the
# solver's version, and its proofs are only as stable as the solver they were run on.
{ z3, fetchFromGitHub, release }:
(z3.override { pythonBindings = false; }).overrideAttrs (old: {
  version = release.z3.version;
  src = fetchFromGitHub {
    owner = "Z3Prover";
    repo = "z3";
    rev = "z3-${release.z3.version}";
    hash = release.z3.hash;
  };
  doInstallCheck = false;
})
