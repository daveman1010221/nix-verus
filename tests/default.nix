# That the built Verus proves what is true and refuses what is not: one function whose postcondition holds, and the same
# with one that does not.
{ runCommand, verus }:
{
  proves = runCommand "verus-proves" { nativeBuildInputs = [ verus ]; } ''
    verus ${./holds.rs}
    touch $out
  '';
  refuses = runCommand "verus-refuses" { nativeBuildInputs = [ verus ]; } ''
    if verus ${./fails.rs}; then
      echo "verus accepted a postcondition that does not hold" >&2
      exit 1
    fi
    touch $out
  '';
}
