use crate::hash_to_field::hash_to_field;
use crate::map_to_curve::map_to_curve;
use std::embedded_curve_ops::EmbeddedCurvePoint as Point;

pub(crate) fn hash_to_curve<let N: u32>(msg: [Field; N]) -> Point {
    let u: (Field, Field) = hash_to_field(msg);

    // Note: It's usually scalars Fr that are mapped to curves. Here, we're actually mapping Noir `Field` types, which are grumpkin's base field Fq elements. Grumpkin's |Fr| > |Fq| = |`Field`|.
    let Q0: Point = map_to_curve(u.0);
    let Q1: Point = map_to_curve(u.1);

    // Q: do we need to "map twice then add", if we're not using the "isogeny" approach to hashing to curve?
    Q0 + Q1
}
