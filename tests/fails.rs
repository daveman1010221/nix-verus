use vstd::prelude::*;

verus! {

fn max(a: u64, b: u64) -> (r: u64)
    ensures
        r > a && r >= b,
{
    if a >= b { a } else { b }
}

fn main() {}

} // verus!
