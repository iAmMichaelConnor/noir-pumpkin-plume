load('constants.sage')

# Arguments:
# - F, a field object, e.g., F = GF(2^521 - 1)
# - A and B, the coefficients of the curve y^2 = x^3 + A * x + B
def find_z_sswu(F, A, B):
    R.<xx> = F[]                       # Polynomial ring over F
    g = xx^3 + F(A) * xx + F(B)        # y^2 = g(x) = x^3 + A * x + B
    ctr = F.gen()
    while True:
        for Z_cand in (F(ctr), F(-ctr)):
            # Criterion 1: Z is non-square in F.
            if is_square(Z_cand):
                continue
            # Criterion 2: Z != -1 in F.
            if Z_cand == F(-1):
                continue
            # Criterion 3: g(x) - Z is irreducible over F.
            if not (g - Z_cand).is_irreducible():
                continue
            # Criterion 4: g(B / (Z * A)) is square in F.
            if is_square(g(B / (Z_cand * A))):
                return Z_cand
        ctr += 1



BLS12_381_z_iso = find_z_sswu(BLS12_381_Fq, BLS12_381_ISO_A, BLS12_381_ISO_B)
print("BLS12_381_ISO_z = ", BLS12_381_z_iso)
SECP256K1_z_iso = find_z_sswu(SECP256K1_Fq, SECP256K1_ISO_A, SECP256K1_ISO_B)
print("SECP256K1_ISO_z = ", SECP256K1_z_iso)
GRUMPKIN_z_iso = find_z_sswu(GRUMPKIN_Fq, GRUMPKIN_ISO_A, GRUMPKIN_ISO_B)
print("GRUMPKIN_ISO_z = ", GRUMPKIN_z_iso)