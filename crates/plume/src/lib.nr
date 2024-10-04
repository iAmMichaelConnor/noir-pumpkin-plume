pub(crate) mod utils;
pub(crate) mod hash_to_curve;
pub(crate) mod hash_to_field;
pub(crate) mod map_to_curve;

use dep::bignum::fields::bn254Fq::BNParams;
use dep::bignum::BigNum;
use crate::utils::{poseidon2_hash, field_to_bignum_unsafe, bignum_to_field_unsafe, bignum_to_scalar};
use crate::hash_to_curve::hash_to_curve;
use std::embedded_curve_ops::EmbeddedCurvePoint as Point;
use std::embedded_curve_ops::EmbeddedCurveScalar as Scalar;
use std::embedded_curve_ops::{
    multi_scalar_mul,
    multi_scalar_mul_slice,
    // fixed_base_scalar_mul
};
use std::hash::{derive_generators, from_field_unsafe}; // For Grumpkin only.
// use crate::ec_ops::{Point, scalar_mul, point_add};

// TODO: hard-code this, once you know it! Use the test below.

// Copied over from embedded_curve_ops.nr fixed_base_scalar_mul function. TODO: that function should allow us to pass our own constants, and we should derive something different from the hard-coded value you see below.
// TODO: this actually needs to match the generator that's been used for keys.
// EDIT: using fixed_base_scalar_mul ended up being _more_ expensive! Why?
global G = Point { x: 1, y: 17631683881184975370165255887551781615748388533673675138860, is_infinite: false };

type ScalarWithOps = BigNum<3, BNParams>;

unconstrained fn __field_to_bool(x: Field) -> bool {
    x as bool
}

fn msm(scalars: [Scalar], points: [Point]) -> Point {
    let point_array = multi_scalar_mul_slice(points, scalars);
    // `as bool` seemed to give a huge blowup in constraints here...
    let is_infinite: bool = unsafe {
        __field_to_bool(point_array[2])
    };
    assert(is_infinite as Field == point_array[2]);

    Point { x: point_array[0], y: point_array[1], is_infinite }
    // BUG: calling multi_scalar_mul returns [Field;3], even though the function should return a Point. It's probably something to do with the weird pub(crate) syntax or the foreign call annotation?
    // multi_scalar_mul([P], [s])
}

fn scalar_mul(s: Scalar, P: Point) -> Point {
    let point_array = multi_scalar_mul_slice(&[P], &[s]);
    // `as bool` seemed to give a huge blowup in constraints here...
    let is_infinite: bool = unsafe {
        __field_to_bool(point_array[2])
    };
    assert(is_infinite as Field == point_array[2]);

    Point { x: point_array[0], y: point_array[1], is_infinite }
    // BUG: calling multi_scalar_mul returns [Field;3], even though the function should return a Point. It's probably something to do with the weird pub(crate) syntax or the foreign call annotation?
    // multi_scalar_mul([P], [s])
}

fn compute_H<let N: u32, let N_PLUS_2: u32>(msg: [Field; N], Pk: Point) -> Point {
    // static_assert(N_PLUS_2 == N + 2); // try again when you upgrade the version of nargo.
    let mut input: [Field; N_PLUS_2] = [0; N_PLUS_2];
    for i in 0..N {
        input[i] = msg[0];
    }
    input[N] = Pk.x;
    input[N+1] = Pk.y;
    hash_to_curve(input)
}

// For testing only!
unconstrained pub fn compute_nullifier(sk: Scalar, H: Point) -> Point {
    scalar_mul(sk, H)
}

// For testing, not for production use, because it requires sk!!!
// `msg` for Aztec purposes will be a note hash.
unconstrained pub fn compute_plume_proof<let N: u32, let N_PLUS_2: u32>(sk_f: Field, msg: [Field; N], r_n: ScalarWithOps) -> (Point, Point, Point, Point, Scalar) {
    let sk: Scalar = Scalar::from_field(sk_f);
    let sk_n: ScalarWithOps = field_to_bignum_unsafe(sk_f);
    let r: Scalar = bignum_to_scalar(r_n);

    let Pk: Point = scalar_mul(sk, G);
    let H: Point = compute_H::<_, N_PLUS_2>(msg, Pk);
    let Nullifier: Point = compute_nullifier(sk, H);

    let rG: Point = scalar_mul(r, G);
    let rH: Point = scalar_mul(r, H);

    let A = Pk;
    let B = Nullifier;
    let A2 = rG;
    let B2 = rH;

    let c_f: Field = poseidon2_points::<6, 2*6>([G, H, A, B, A2, B2]);
    let c_n: ScalarWithOps = field_to_bignum_unsafe(c_f);

    let s_n: ScalarWithOps = r_n + (sk_n * c_n);
    let s: Scalar = bignum_to_scalar(s_n);

    (A, B, A2, B2, s)
}

pub fn verify_plume_proof<let N: u32, let N_PLUS_2: u32>(msg: [Field; N], A: Point, B: Point, A2: Point, B2: Point, s: Scalar) {
    let Pk = A;
    let H = compute_H::<N, N_PLUS_2>(msg, Pk);
    let c_f: Field = poseidon2_points::<6, 2*6>([G, H, A, B, A2, B2]);
   
    let c: Scalar = Scalar::from_field(c_f);

    // Negating the point is more efficient than negating the non-native scalar c:
    let neg_A: Point = Point { x: A.x, y: -(A.y), is_infinite: A.is_infinite };
    let neg_B: Point = Point { x: B.x, y: -(B.y), is_infinite: B.is_infinite };

    // TODO: cheaper to do fixed-base scalar mul for s*G.
    // TODO: understand why it wasn't cheaper to do fixed-based scalar mul!
    assert(A2 == msm(&[s, c], &[G, neg_A]));
    assert(B2 == msm(&[s, c], &[H, neg_B]));
    // assert(A2 == scalar_mul(s, G) - scalar_mul(c, A));
    // assert(B2 == scalar_mul(s, H) - scalar_mul(c, B));
}

// global GRUMPKIN_Q_MINUS_1_OVER_2 = 10944121435919637611123202872628637544274182200208017171849102093287904247808; // For grumpkin base prime 21888242871839275222246405745257275088548364400416034343698204186575808495617

// fn get_y_sign(P: Point) -> Field{
//     let y = P.y;
//     if y.lt(GRUMPKIN_Q_MINUS_1_OVER_2) {
//         1
//     } else {
//         0
//     }
// }

// fn combine_signs_into_field<let N: u32>(signs: [Field; N]) -> Field {
//     // static_assert(N < 254);
//     let mut out: Field = signs[N - 1];
//     for i in 0..N - 1 {
//         let j = N - 2 - i;
//         out = out * 2 + signs[j];
//     }
//     out
// }

// fn compress_points<let N: u32, let N_PLUS_1: u32>(points: [Point; N]) -> [Field; N_PLUS_1] {
//     let mut signs: [Field; N] = [0; N];
//     for i in 0..N {
//         signs[i] = get_y_sign(points[i]);
//     }
//     let signs_as_field = combine_signs_into_field(signs);
//     let mut out: [Field; N_PLUS_1] = [0; N_PLUS_1];
//     for i in 0..N {
//         out[i] = points[i].x;
//     }
//     out[N] = signs_as_field;
//     out
// }

fn poseidon2_points<let N: u32, let TWO_N: u32>(points: [Point; N]) -> Field {
    // static_assert(TWO_N == 2 * N);
    let mut input: [Field; TWO_N] = [0; TWO_N];
    for i in 0..N {
        let j = 2 * i;
        input[j] = points[i].x;
        input[j + 1] = points[i].y;
    }
    poseidon2_hash(input)
    // Compressing the points costs a fortune because of the check for each point that y < (p-1)/2 (each comparison costs ~190 gates).
    // poseidon2_hash(compress_points::<_, N_PLUS_1>(points))
}

#[test]
fn test_plume() {
    let sk_f = 0x1234;
    let msg = [0x2345; 1];
    // TODO: replace BigNum<3, BNParams> with ScalarWithOps and see it break, and open an issue on github.
    let r: ScalarWithOps = BigNum::from_array([0x1234, 0x1234, 0x12]);
    let (A, B, A2, B2, s) = unsafe {
        compute_plume_proof::<1, 1+2>(sk_f, msg, r)
    };

    verify_plume_proof::<1, 1+2>(msg, A, B, A2, B2, s);
}

