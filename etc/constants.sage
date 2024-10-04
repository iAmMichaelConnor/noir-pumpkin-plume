from sage.all import GF

# TODO: this page has kind of become a scatch pad for a few projects. Need to tidy it up.

# Useful resources:
# https://github.com/geometryxyz/secp256k1_hash_to_curve?tab=readme-ov-file
# https://github.com/cfrg/draft-irtf-cfrg-hash-to-curve/blob/main/poc/README.md
# https://www.rfc-editor.org/rfc/rfc9380

#offset_generator_final = offset_generator * 2^((NScalarSlices - 1) * 4)
#we hardcode NScalarSlices to 64 so it’s offset_generator * (2^252)
#i.e. it’s the offset_generator once it’s been passed through an MSM
def compute_final_offset_generator(G):
    n_scalar_slices = 64
    G_final = (2 ** ((n_scalar_slices - 1) * 4)) * G
    return G_final

# Secp256k1
SECP256K1_q = 2**256 - 2**32 - 977
SECP256K1_r = 115792089237316195423570985008687907852837564279074904382605163141518161494337
SECP256K1_Fq = GF(SECP256K1_q)

SECP256K1_A = 0
SECP256K1_B = 7
SECP256K1_E = EllipticCurve(SECP256K1_Fq, [SECP256K1_A, SECP256K1_B])

# Run `sage find_iso.sage`
SECP256K1_ISO_A = 28734576633528757162648956269730739219262246272443394170905244663053633733939
SECP256K1_ISO_B = 1771

# Run `sage find_z.sage`
SECP256K1_ISO_z =  115792089237316195423570985008687907853269984665640564039457584007908834671652

#################################################################

# BLS12-381
# https://hackmd.io/@benjaminion/bls12-381

z = -0xd201000000010000
h = (z - 1) ** 2 // 3 # cofactor
r = z ** 4 - z ** 2 + 1 # subgroup size
BLS12_381_r = r # subgroup size. I.e. scalar field size.
BLS12_381_q = z + h * r
BLS12_381_group_size = h * r
BLS12_381_Fq = GF(BLS12_381_q)

BLS12_381_A = 0
BLS12_381_B = 4
BLS12_381_E = EllipticCurve(BLS12_381_Fq, [BLS12_381_A, BLS12_381_B])

# Generator:
# https://github.com/zcash/librustzcash/blob/6e0364cd42a2b3d2b958a54771ef51a8db79dd29/pairing/src/bls12_381/README.md#generators
# https://hackmd.io/@benjaminion/bls12-381#Generators
# TODO: this might not suffice as an offset generator, since this is the canonical generator for the group, and perhaps the "offset generator" needs to be different from this!
BLS12_381_G = BLS12_381_E(3685416753713387016781088315183077757961620795782546409894578378688607592378376318836054947676345821548104185464507, 1339506544944476473020471379941921221584933875938349620426543736416511423956333506472724655353366534992391756441569)

# Computed with BLS12_381_E.gens()
BLS12_381_OFFSET_GENERATOR = BLS12_381_E(547267894408768087084154039555760353521479753946258632875036726158932984746527535614714820052060149146314557270019, 1835063209175869974242139117441761755355391001264886580587881843166918857183334906933623397100805888438647438806516)

BLS12_381_FINAL_OFFSET_GENERATOR = compute_final_offset_generator(BLS12_381_OFFSET_GENERATOR)

# Run `sage find_iso.sage`
BLS12_381_ISO_A = 12190336318893619529228877361869031420615612348429846051986726275283378313155663745811710833465465981901188123677
BLS12_381_ISO_B = 2906670324641927570491258158026293881577086121416628140204402091718288198173574630967936031029026176254968826637280

# Run `sage find_z.sage`
BLS12_381_ISO_z =  11

# AltBN254
# https://hackmd.io/@jpw/bn254

BN254_q = 21888242871839275222246405745257275088696311157297823662689037894645226208583
BN254_r = 21888242871839275222246405745257275088548364400416034343698204186575808495617

BN254_Fq = GF(BN254_q)
BN254_Fr = GF(BN254_r)

BN254_A = 0
BN254_B = 3
# [0, 3] are the A and B of the curve definition
# y^2 = x^3 + 0*x + 3
BN254_E = EllipticCurve(GF(BN254_q), [BN254_A, BN254_B])

BN254_G = BN254_E(1, 2)

# Derivation missing! Might need to regenerate this! (It was found, uncommented in Zac's bigcurve library.
BN254_OFFSET_GENERATOR = (0x0cfb80d7bbcaebb13bbabfc30184f59912f30f376a22bd3695abf4dcdfed66c6, 0x07f6a40d9e20debde026e47f8bfc4d3c41e53572d644c1e06f80ab52ef02fa2f)

BN254_FINAL_OFFSET_GENERATOR = compute_final_offset_generator(BN254_G)

#################################################################

# Grumpkin
GRUMPKIN_q = 21888242871839275222246405745257275088548364400416034343698204186575808495617 # this is the `field` type of Noir, and is the AltBN254 `r`. Grumpkin points are expressed as (Fq, Fq).
GRUMPKIN_r = 21888242871839275222246405745257275088696311157297823662689037894645226208583 # this is the AltBN254 `q`. It is larger than AltBN254 `r`. It it is the subgroup order of Grumpkin.
GRUMPKIN_Fq = GF(GRUMPKIN_q)
GRUMPKIN_Fr = GF(GRUMPKIN_r)

GRUMPKIN_A = 0
GRUMPKIN_B = -17
# [0, -17] are the A and B of the curve definition
# y^2 = x^3 + 0*x -17
GRUMPKIN_E = EllipticCurve(GF(GRUMPKIN_q), [GRUMPKIN_A, GRUMPKIN_B])

# Run `sage find_iso.sage`
GRUMPKIN_ISO_A = 9521675518340972136371180419475516128506432264909173462642171058873905238014
GRUMPKIN_ISO_B = 7859334032496563475294737297056535049192793054252435346689241684159591398730

# Run `sage find_z.sage`
GRUMPKIN_ISO_z =  14

# Using notation from wikipedia: https://en.wikipedia.org/wiki/Tonelli–Shanks_algorithm
GRUMPKIN_TONELLI_NON_RESIDUE = 5
GRUMPKIN_TONELLI_Q = 81540058820840996586704275553141814055101440848469862132140264610111 # 226 bits
GRUMPKIN_TONELLI_Q_PLUS_1_OVER_2 = 40770029410420498293352137776570907027550720424234931066070132305056 # 225 bits
GRUMPKIN_TONELLI_S = 28
GRUMPKIN_TONELLI_Z_POW_Q = 19103219067921713944291392827692070036145651957329286315305642004821462161904

# GRUMPKIN_P_MINUS_1_OVER_2 = 10944121435919637611123202872628637544274182200208017171849102093287904247808 # 253 bits

#################################################################


def int_to_120bit_limbs(num):
    limbs = []
    bits_per_limb = 120
    limb_mask = (1 << bits_per_limb) - 1
    while num > 0:
        # Extract the least significant 120 bits
        limb = num & limb_mask
        limbs.append(limb)
        # Shift the number right by 120 bits for the next limb
        num >>= bits_per_limb
    return [hex(l) for l in limbs]

def get_generators(E):
    # Not used: it's not matching the BLS12-381 generator spec.
    print([g.xy() for g in E.gens()])

def find_quadratic_non_residue(F):
    p = F.characteristic()
    for a in F:
        if legendre_symbol(a, p) == -1:
            print("Found a non-residue:", a)
            return a
    return None

def p_minus_1_over_2():
    return (GRUMPKIN_q - 1) // 2

def Q_plus_1_over_2():
    return (GRUMPKIN_TONELLI_Q + 1) // 2

def z_pow_Q():
    return power_mod(GRUMPKIN_TONELLI_NON_RESIDUE, GRUMPKIN_TONELLI_Q, GRUMPKIN_q)

def is_even(x):
    return x & 1 == 0

def get_Q_and_S():
    Q = GRUMPKIN_q - 1
    S = 0
    i = 0
    while is_even(Q):
        print(i)
        i += 1
        Q //= 2
        S += 1
    assert Q * (2 ** S) == GRUMPKIN_q - 1, "Nope"
    print("Q:", Q)
    print("S:", S)
    return (Q, S)


def check_constants():
    assert SECP256K1_E.order() == SECP256K1_r, "secp256k1 constants order mismatch"

    assert is_prime(BLS12_381_q), "not prime"
    assert is_prime(BLS12_381_r), "not prime"
    assert BLS12_381_E.order() == BLS12_381_group_size, "bls12_381 constants order mismatch"

    assert GRUMPKIN_E.order() == GRUMPKIN_r, "grumpkin constants order mismatch"

def find_i(t, q, M):
    i = 1
    t_pow_2_pow_i = (t * t) % q # t ^ (2 ^ 1) => i = 1
    while true:
        if i == 1000:
            return "Uh Oh!!!"
        if t_pow_2_pow_i == 1:
            return i
        t_pow_2_pow_i = (t_pow_2_pow_i * t_pow_2_pow_i) % q
        i += 1

# Compute sqrt(n)
def tonelli_shanks(n):
    # F = GRUMPKIN_Fq
    q = GRUMPKIN_q
    # n = F(n)
    Q = GRUMPKIN_TONELLI_Q
    Q_PLUS_1_OVER_2 = GRUMPKIN_TONELLI_Q_PLUS_1_OVER_2
    M = GRUMPKIN_TONELLI_S
    z = GRUMPKIN_TONELLI_NON_RESIDUE
    c = GRUMPKIN_TONELLI_Z_POW_Q

    t = power_mod(n, Q, q)
    R = power_mod(n, Q_PLUS_1_OVER_2, q)

    while true:
        if t == 0:
            return 0
        if t == 1:
            return R
        i = find_i(t, q, M)
        b = power_mod(c, power_mod(2, (M - i - 1), q), q)
        M = i
        c = power_mod(b, 2, q)
        t = (t * c) % q
        R = (R * b) % q
        
        
#print(p_minus_1_over_2())
def check_sqrts():
    i = 0
    while i < 100:
        x = GRUMPKIN_Fq.random_element()
        if x.is_square():
            x_sqrt = tonelli_shanks(x)
            x_sqrt_proper = x.sqrt()
            if x_sqrt == x_sqrt_proper:
                assert x_sqrt == x_sqrt_proper, "AAAAH"
            else:
                # We found the negative root.
                assert GRUMPKIN_q - x_sqrt == x_sqrt_proper, "AAAAH"
        i += 1

def point_to_120bit_limbs(P):
    return [int_to_120bit_limbs((P).x().lift()), int_to_120bit_limbs((P).y().lift())]

def print_bls12_381_test_data():
    P = BLS12_381_G
    print("P:", point_to_120bit_limbs(P))
    Two_P = 2 * P
    print("2P:", point_to_120bit_limbs(Two_P))
    Three_P = 3 * P
    print("3P:", point_to_120bit_limbs(Three_P))
    Neg_P = -P
    print(point_to_120bit_limbs(Neg_P))
    # r_sub_2 = BLS12_381_r - 2


def main():
    #print("BLS12_381_q:", int_to_120bit_limbs(BLS12_381_q))
    #print("BLS12_381_r:", int_to_120bit_limbs(BLS12_381_r))
    #r_sub_2 = BLS12_381_r - 2
    #print("BLS12_381_r - 2:", int_to_120bit_limbs(r_sub_2))
    #print("2 * BLS12_381_r:", int_to_120bit_limbs(2 * r))
    #print("r_sub_2 * BLS12_381_G", [int_to_120bit_limbs((r_sub_2 * BLS12_381_G).x().lift()), int_to_120bit_limbs((r_sub_2 * BLS12_381_G).y().lift())])
    #print("BLS12_381_G", [int_to_120bit_limbs((BLS12_381_G).x().lift()), int_to_120bit_limbs((BLS12_381_G).y().lift())])
    #print("2 * BLS12_381_G", [int_to_120bit_limbs((2 * BLS12_381_G).x().lift()), int_to_120bit_limbs((2 * BLS12_381_G).y().lift())])

    # print_bls12_381_test_data()
    a = GRUMPKIN_Fr(17)
    cubed_root_a = a.nth_root(3)
    assert cubed_root_a * cubed_root_a * cubed_root_a == a, "Uh oh"
    print(cubed_root_a)



main()