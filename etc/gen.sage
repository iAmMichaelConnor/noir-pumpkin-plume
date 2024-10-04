import os
from hashlib import sha256

load('utils.sage')
load('constants.sage') # E, GRUMPKIN_PRIME_r
load('hash_to_curve.sage') # HashToCurve
load('poseidon2.sage')


# msg_len is number of bytes.
def generate_random_r_sk_msg(msg_len: int):
    r = os.urandom(32)
    sk = os.urandom(32)
    msg = os.urandom(msg_len)
    return (list(r), list(sk), list(msg))

# msg_len is number of fields.
# TODO: Notice that we generate elements of Fq. That's not strictly correct, since they're often used as scalars in a scalar mul. Check this is secure.
def generate_random_r_sk_msg_grumpkin(msg_len: int):
    r = GRUMPKIN_Fr.random_element() # Fr because not used in poseidon2
    sk = GRUMPKIN_Fq.random_element()
    msg = [GRUMPKIN_Fq.random_element() for _ in range(msg_len)]
    return (r, sk, msg)

def plume_generate_test_case(version1: bool, msg_len: int):
    (r, sk, msg) = generate_random_r_sk_msg(msg_len)
    # consider converting msg to num as well!
    r = bytes_to_num(r)
    sk = bytes_to_num(sk)

    print("\nr", r)
    print("sk", sk)

    G = E.gens()[0]

    Pk = (sk * G).xy()
    print("Pk", Pk)
    Hxy = HashToCurve_Grumpkin(msg + compress_ec_point(Pk))

    H = E(Hxy[0], Hxy[1])
    N = (sk * Hp).xy()
    print("N", N)

    if version1:
        c = sha256_points([G, Pk, H, N, r*G, r*H])
    else:
        c = sha256_points([N, r*G, r*H])
    c.reverse()
    print("c", c)

    s = (r + sk * bytes_to_num(c)) % GRUMPKIN_PRIME_r
    print("s", c)

    Pk = point_to_bytes(Pk)
    N = point_to_bytes(N)
    return (msg, c, num_to_bytes(int(s)), Pk, N)

def check_plume_grumpkin(version1: bool, msg_len: int):
    E = GRUMPKIN_E
    Fr = GRUMPKIN_Fr
    Fq = GRUMPKIN_Fq

    (r, sk, msg) = generate_random_r_sk_msg_grumpkin(msg_len)
    print("\nr", r)
    print("sk", sk)

    G = E.gens()[0]

    Pk = Fr(sk.lift()) * G
    print("Pk", Pk)
    Hxy = HashToCurve_Grumpkin([*msg, Pk.x(), Pk.y()])
    print("Hxy", Hxy)

    H = E(Hxy[0], Hxy[1])
    N = Fr(sk.lift()) * H
    print("N", N)

    if version1:
        # TODO: we can compress these and pack the y-sign bits into a single field.
        c = poseidon2_points([G, H, Pk, N, r*G, r*H])
    else:
        c = poseidon2_points([N, r*G, r*H])

    print("c", c)

    # TODO: check the security of using an element of Fq for c, and then converting it to an element of Fr
    s = Fr(r + Fr(sk.lift()) * Fr(c.lift()) )
    print("s", s)

    A = Pk
    B = N 
    A_p = r*G
    B_p = r*H
    # prover sends: (A, A_p, B, B_p, s)
    # msg, G are known to the verifier

    # verifier does:
    Hxy2 = E(HashToCurve_Grumpkin([*msg, Pk.x(), Pk.y()]))
    H2 = E(Hxy2[0], Hxy2[1])

    c2 = poseidon2_points([G, H, A, B, A_p, B_p])

    assert A_p == s*G - Fr(c.lift())*A
    assert B_p == s*H - Fr(c.lift())*B
    print("Success! You just done a plume, mate!")
    return 1

def plume_generate_test_case_grumpkin(version1: bool, msg_len: int):
    E = GRUMPKIN_E
    Fr = GRUMPKIN_Fr

    (r, sk, msg) = generate_random_r_sk_msg_grumpkin(msg_len)
    print("\nr", r)
    print("sk", sk)

    G = E.gens()[0]

    Pk = sk * G
    print("Pk", Pk)
    Hxy = E(HashToCurve_Grumpkin([msg, Pk.x(), Pk.y()]))
    print("H", H)

    H = E(Hxy[0], Hxy[1])
    N = sk * H
    print("N", N)

    if version1:
        # TODO: we can compress these and pack the y-sign bits into a single field.
        c = poseidon2_points([G, Pk, H, N, r*G, r*H])
    else:
        c = poseidon2_points([N, r*G, r*Hp])

    print("c", c)

    # TODO: check the security of using an element of Fq for c, and then converting it to an element of Fr
    s = (r + sk * Fr(c)) % GRUMPKIN_PRIME_r
    print("s", s)

    return (msg, c, s, Pk, N)

def point_to_bytes(p):
    return (num_to_bytes(int(p[0])), num_to_bytes(int(p[1])))

def compress_ec_point(p):
    x = num_to_bytes(int(p[0]))
    y = num_to_bytes(int(p[1]))

    compressed = [(y[0] & 1) + 2] * 33
    for i in range(32):
        compressed[32-i] = x[i]
    return compressed

def sha256_points(points):
    res = []
    for p in points:
        res += compress_ec_point(p)
    return list(sha256(bytes(res)).digest())

def poseidon2_points(points):
    inputs = [GRUMPKIN_Fq(coord) for p in points for coord in [p.x(), p.y()]]
    return poseidon2_hash(inputs)

check_plume_grumpkin(true, 1)