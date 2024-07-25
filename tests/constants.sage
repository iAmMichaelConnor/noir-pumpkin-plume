from sage.all import Integer, GF

SECP256K1_PRIME = 2**256 - 2**32 - 977
E = EllipticCurve(GF(SECP256K1_PRIME), [0, 7])

FIELD = GF(SECP256K1_PRIME)