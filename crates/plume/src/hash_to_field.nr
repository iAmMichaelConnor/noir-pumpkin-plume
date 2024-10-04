use crate::utils::poseidon2_hash;

pub(crate) fn hash_to_field<let N: u32>(msg: [Field; N]) -> (Field, Field) {
    let mut m: Field = poseidon2_hash(msg);
    let u_0: Field = poseidon2_hash([m, 0]);
    let u_1: Field = poseidon2_hash([m, 1]);
    (u_0, u_1)
}
