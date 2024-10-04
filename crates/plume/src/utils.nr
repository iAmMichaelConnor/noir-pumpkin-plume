use dep::bignum::BigNum;
use dep::bignum::fields::bn254Fq::BNParams;
use std::embedded_curve_ops::EmbeddedCurveScalar as Scalar;

type F = BigNum<3, BNParams>;

global TWO_POW_128 = 0x100000000000000000000000000000000;
global TWO_POW_120 = 0x1000000000000000000000000000000;
global TWO_POW_112 = 0x10000000000000000000000000000;

// // The BN Fr Field size: don't change this.
// global BN254_FR_MODULUS: [Field; 3] = [
//     0x000000000000000000000000000000000033E84879B9709143E1F593F0000001, 0x00000000000000000000000000000000004E72E131A029B85045B68181585D28, 0x0000000000000000000000000000000000000000000000000000000000003064
// ];

pub(crate) fn poseidon2_hash<let N: u32>(inputs: [Field; N]) -> Field {
    std::hash::poseidon2::Poseidon2::hash(inputs, N)
}

// #[no_predicates]
// pub fn poseidon2_hash_with_separator<let N: u32, T>(
//     inputs: [Field; N],
//     separator: T
// ) -> Field where T: ToField {
//     // We manually hash the inputs here, since we cannot express with the type system a constant size inputs array of N + 1
//     let in_len = N + 1;
//     let two_pow_64 = 18446744073709551616;
//     let iv : Field = (in_len as Field) * two_pow_64;
//     let mut sponge = std::hash::poseidon2::Poseidon2::new(iv);
//     sponge.absorb(separator.to_field());

//     for i in 0..inputs.len() {
//         sponge.absorb(inputs[i]);
//     }

//     sponge.squeeze()
// }

// unconstrained fn __field_to_scalar_bytes(x: Field) -> ([u8; 16], [u8; 16]) {
//     let x_bytes = x.to_le_bytes(32);
//     let mut x_bytes_lo: [u8; 16] = [0; 16];
//     let mut x_bytes_hi: [u8; 16] = [0; 16];
//     for i in 0..16 {
//         x_bytes_lo[i] = x_bytes[i];
//         x_bytes_hi[i] = x_bytes[16 + i];
//     }
//     (x_bytes_lo, x_bytes_hi)
// }

// fn field_to_scalar(x: Field) -> Scalar {
//     let (x_bytes_lo, x_bytes_hi) = __field_to_scalar_bytes(x);
//     let mut lo: Field = x_bytes_lo[15] as Field;
//     let mut hi: Field = x_bytes_hi[15] as Field;
//     for i in 0..15 {
//         let j = 15 - 1 - i;
//         lo = lo * 256 + x_bytes_lo[j] as Field;
//         hi = hi * 256 + x_bytes_hi[j] as Field;
//     }
//     let x_check = lo + hi * TWO_POW_128;
//     assert(x == x_check);
//     Scalar {lo, hi}
// }

// unconstrained fn __field_to_scalar_limbs(x: Field) -> (Field, Field) {
//     let x_bytes = x.to_le_bytes(32);
//     let mut x_bytes_lo: [u8; 16] = [0; 16];
//     let mut x_bytes_hi: [u8; 16] = [0; 16];
//     let mut lo: Field = x_bytes_lo[15] as Field;
//     let mut hi: Field = x_bytes_hi[15] as Field;
//     for i in 0..15 {
//         let j = 15 - 1 - i;
//         lo = lo * 256 + x_bytes_lo[j] as Field;
//         hi = hi * 256 + x_bytes_hi[j] as Field;
//     }
//     (lo, hi)
// }

// fn field_to_scalar(x: Field) -> Scalar {
//     let (lo, hi) = __field_to_scalar_limbs(x);
//     // Range check the limbs
//     lo.assert_max_bit_size(128);
//     hi.assert_max_bit_size(128);
//     // Hmmmm missing a check to ensure this doesn't overflow. Ok, I should use Scalar::from_field
//     let x_check = lo + hi * TWO_POW_128;
//     assert(x == x_check);
//     Scalar {lo, hi}
// }

unconstrained fn __field_to_be_bytes(x: Field) -> [u8; 32] {
    let x_bytes_slice: [u8; 32] = x.to_be_bytes();
    let mut x_bytes = [0; 32];
    for i in 0..32 {
        x_bytes[i] = x_bytes_slice[i];
    }
    x_bytes
}

unconstrained fn __field_to_bignum(x: Field) -> F {
    let x_bytes = __field_to_be_bytes(x);
    BigNum::from_be_bytes(x_bytes)
}

unconstrained fn __field_to_bignum_limbs(x: Field) -> [Field; 3] {
    __field_to_bignum(x).limbs
}

// "Unsafe" because it only works for bignums with modulus larger than the BN Fr size.
// TODO: this isn't-yet secure. See comment within.
pub fn field_to_bignum_unsafe(x: Field) -> F {
    let __x_limbs = unsafe {
        __field_to_bignum_limbs(x)
    };
    // Range check the limbs
    __x_limbs[0].assert_max_bit_size(120);
    __x_limbs[1].assert_max_bit_size(120);
    __x_limbs[2].assert_max_bit_size(14);
    let mut check = __x_limbs[3 - 1];
    for i in 1..3 {
        // TODO: need to ensure this doesn't overflow, in a similar way as shown in noir_stdlib/src/field/bn254.nr 
        // Also see explanation here: https://github.com/noir-lang/noir/commit/1f9cad00c57ea257f57419d2446a46938beb19f9
        check = check * TWO_POW_120 + __x_limbs[3 - i - 1];
    }
    assert(check == x);

    BigNum { limbs: __x_limbs }
}

// DANGER: this assumes the input bignum is <= the Noir field size.
// Only use this if you _know_ the data being passed in is small enough and properly-formatted.
pub(crate) fn bignum_to_field_unsafe(x: F) -> Field {
    let mut result: Field = 0;
    result += x.limbs[3 - 1];
    for i in 1..3 {
        result *= TWO_POW_120;
        result += x.limbs[3 - i - 1];
    }
    result
}

unconstrained fn __get_x1_split_hint(x: F) -> (u8, Field) {
    let x1_bytes: [u8; 15] = x.limbs[1].to_le_bytes();
    let x1_le_byte_0 = x1_bytes[0];

    let mut x1_bytes_shifted_right = [0; 14];
    for i in 0..14 {
        x1_bytes_shifted_right[i] = x1_bytes[i+1];
    }

    let mut x1_byte_shifted_right: Field = x1_bytes_shifted_right[13] as Field;
    for i in 0..13 {
        let j = 13 - 1 - i;
        x1_byte_shifted_right = x1_byte_shifted_right * 256 + x1_bytes_shifted_right[j] as Field;
    }
    (x1_le_byte_0, x1_byte_shifted_right)
}

pub(crate) fn bignum_to_scalar(x: F) -> Scalar {
    // We assume the bignum limbs have already been checked to be < 120 bits.
    let (x1_le_byte_0, x1_byte_shifted_right) = unsafe {
        __get_x1_split_hint(x)
    };

    let x1_le_byte_0_as_field = x1_le_byte_0 as Field;

    x1_byte_shifted_right.assert_max_bit_size(112);

    let x1_check = x1_le_byte_0_as_field + x1_byte_shifted_right * 256;

    assert(x1_check == x.limbs[1]);

    let lo = x.limbs[0] + TWO_POW_120 * x1_le_byte_0_as_field;
    let hi = x1_byte_shifted_right + x.limbs[2] * TWO_POW_112;
    Scalar { lo, hi }
}

#[test]
fn test_bignum_to_field() {
    let x_n: F = BigNum::from_array([0x1234, 0x1234, 0x12]);
    println(f"x_n: {x_n}");
    let x: Field = bignum_to_field_unsafe(x_n);
    println(f"x: {x}");
}

#[test]
fn test_field_to_bignum() {
    let x: Field = 0x1234;
    println(f"x: {x}");
    let x_n: F = field_to_bignum_unsafe(x);
    println(f"x_n: {x_n}");
}

#[test]
fn test_bignum_to_scalar() {
    let x_n: F = BigNum::from_array([0x1234, 0x1234, 0x12]);
    println(f"x_n: {x_n}");
    let x_s: Scalar = bignum_to_scalar(x_n);
    println(f"x_s: {x_s}");
}
