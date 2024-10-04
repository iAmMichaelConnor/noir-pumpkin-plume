load('constants.sage')
load('hash_to_field.sage')
load('map_to_curve.sage')
load('iso_map.sage')

# Get msg in byte format
def HashToCurve_Secp256k1(msg):
    # return bytes
    u = HashToField_Secp256k1(msg)

    # Maps to the isogeny curve
    Q0 = MapToCurve_Secp256k1_isogeny(u[0])
    Q1 = MapToCurve_Secp256k1_isogeny(u[1])

    # TODO: add sanity checks that Q0 and Q1 are actually on the isogeny curve, and not the "proper" curve

    return (SECP256K1_E(IsoMap_Secp256k1(Q0)) + SECP256K1_E(IsoMap_Secp256k1(Q1))).xy()

# Get msg in byte format
def HashToCurve_Bls12_381(msg):
    # return bytes
    u = HashToField_Bls12_381(msg)

    # Maps to the isogeny curve
    Q0 = MapToCurve_Bls12_381_isogeny(u[0])
    Q1 = MapToCurve_Bls12_381_isogeny(u[1])

    # TODO: add sanity checks that Q0 and Q1 are actually on the isogeny curve, and not the "proper" curve

    return (BLS12_381_E(IsoMap_Bls12_381(Q0)) + BLS12_381_E(IsoMap_Bls12_381(Q1))).xy()

# Pass msg as an array of fields
def HashToCurve_Grumpkin(msg):
    # return bytes
    u = HashToField_Grumpkin(msg)

    # Maps to the isogeny curve
    #Q0 = MapToCurve_Grumpkin_isogeny(u[0])
    #Q1 = MapToCurve_Grumpkin_isogeny(u[1])
    Q0 = MapToCurve_Grumpkin(u[0])
    Q1 = MapToCurve_Grumpkin(u[1])

    # TODO: add sanity checks that Q0 and Q1 are actually on the isogeny curve, and not the "proper" curve

    # return (GRUMPKIN_E(IsoMap_Grumpkin(Q0)) + GRUMPKIN_E(IsoMap_Grumpkin(Q1))).xy()
    return (GRUMPKIN_E(Q0) + GRUMPKIN_E(Q1)).xy()
