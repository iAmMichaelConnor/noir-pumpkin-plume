use std::embedded_curve_ops::EmbeddedCurvePoint as Point;
use std::embedded_curve_ops::EmbeddedCurveScalar as Scalar;
use plume::{compute_plume_proof, verify_plume_proof};
use dep::bignum::fields::bn254Fq::BNParams;
use dep::bignum::BigNum;
type ScalarWithOps = BigNum<3, BNParams>;

pub fn main(msg: [Field; 1], Pk: Point, nullifier: Point, A2: Point, B2: Point, s: Scalar) -> pub bool {
    for _i in 0..10 {
        verify_plume_proof::<1, 1+2>(msg, Pk, nullifier, A2, B2, s);
    }
    true
    // Choose your plume variant and comment the other
    // plume_v1(msg, c, s, pk, nullifier);
    // plume_v2(msg, c, s, pk, nullifier);
}

#[test]
fn test_main() {
    let sk_f = 0x1234;
    let msg = [0x2345; 1];
    // TODO: replace BigNum<3, BNParams> with ScalarWithOps and see it break, and open an issue on github.
    let r: ScalarWithOps = BigNum::from_array([0x1234, 0x1234, 0x12]);
    let (A, B, A2, B2, s) = unsafe {
        compute_plume_proof::<1, 1+2>(sk_f, msg, r)
    };

    verify_plume_proof::<1, 1+2>(msg, A, B, A2, B2, s);
}
