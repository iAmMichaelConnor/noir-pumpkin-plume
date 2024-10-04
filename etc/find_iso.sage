# execute this with: `sage find_iso.sage`
import sage.schemes.elliptic_curves.isogeny_small_degree as isd
from sage.schemes.elliptic_curves.ell_curve_isogeny import compute_isogeny_kernel_polynomial
load('constants.sage') # E, check_constants

# look for isogenous curves having j-invariant not in {0, 1728}

# Code pulled (and then significantly edited) from the appendix of this paper: https://eprint.iacr.org/2019/403.pdf

# Caution: this can take a while!
def find_iso(_E):
    i = 0
    for p_test in primes(100):
        print("i", i)
        i += 1
        print("p_test (aka the 'degree' of the isogeny)", p_test)
        isos = [ i for i in isd.isogenies_prime_degree(_E, p_test)
                 if i.codomain().j_invariant() not in (0, 1728) ]
        if len(isos) > 0:
            iso = isos[2].dual() # picking the 2nd one lines up with the constants of the isogeny curves in standards for secp256k1 and bls12-381. That might be a coincidence, it might not be.
            if (- iso.rational_maps()[1])(1, 1) > iso.rational_maps()[1](1, 1):
                iso.switch_sign()
            return iso 
    return None

def compute_already_found_iso(_E, prime_idx):
    p = Primes().unrank(prime_idx)
    isos = [ i for i in isd.isogenies_prime_degree(_E, p)
                 if i.codomain().j_invariant() not in (0, 1728) ]
    if len(isos) > 0:
        iso = isos[2].dual() # picking the 2nd one lines up with the constants of the isogeny curves in standards for secp256k1 and bls12-381. That might be a coincidence, it might not be.
        if (- iso.rational_maps()[1])(1, 1) > iso.rational_maps()[1](1, 1):
                iso.switch_sign()
        return iso 
    return None

def pretty_print_iso_rational_map(curve_name, data):
    print(f"\n\n{curve_name}_ISO_RATIONAL_MAP = {{")
    for key, value in data.items():
        if isinstance(value, list):  # Handle lists of hex strings
            print(f"    '{key}': [", end="")
            print(", ".join(f"0x{int(v, 16):x}" if isinstance(v, str) else f"0x{v:x}" for v in value), end="],\n")
        elif isinstance(value, str):  # Handle individual hex strings
            print(f"    '{key}': 0x{int(value, 16):x},")
        else:  # Handle individual hex integers
            print(f"    '{key}': 0x{value:x},")
    print("}")

def check_bls12_381_iso(iso):
    # E_prime_from_boneh = EllipticCurve(F, [0x144698a3b8e9433d693a02c96d4982b0ea985383ee66a8d8e8981aefd881ac98936f8da0e0f97f5cf428082d584c1d, 0x12e2908d11688030018b12e8753eee3b2016c1f0f24f4070a0b9c14fcef35ef55a23215a316ceaa5d1cc48e98e172be0])

    # the following integers are base36-encoded to compress horizontally
    vv = [ "12rutfybsn0bkhh9qg5qlfrpugmxe5czd757bmomkcfj8qj94vfcibfpfz6778pphed5apz4t"
        , "74t8nxvndcq4fsu3byqf2ubacd8zpfj5htxn621zauzk8jeti9eg3iakb1qzc44dbo59g94ue8"
        , "793jv4j16d1k90qpfb51iyn9gbkoakins8196hj0rcw750ya3xz7bklkkyi2zsf1alzxka0q2v"
        , "wjf4r8fn0t5ud2l8mj6qtxj6vwqkfv403p6t8rrlalpyli69k7yrbkyfqv3h3k4bup3ef0vqo"
        , "798csdr2a2qwd6hz4bjkll53bbxbr7ndhgwi663wezfptv82hqp2iae52dm4atf4z2xgzaar09"
        , "3i0ielgn7to06ad2bvkigqmaxy3k9yn6fqgkh2hks4qt2xrlsgy6s45tc32fwk2ar4e8yajsjo"
        , "1rqju5l2fizu0w476g37nhlfwgbsfyyltl53doespo31onzy21q72irl9s7s4p051r2160gw3p"
        , "1"]
    a_prime = int(vv[0], base=36)
    b_prime = int(vv[1], base=36)
    kernel_poly = [ int(v, base=36) for v in vv[2:] ]

    Expeceted_E_prime = EllipticCurve(BLS12_381_Fq, [a_prime, b_prime])
    assert Expeceted_E_prime.order() == BLS12_381_E.order()

    expected_iso = EllipticCurveIsogeny(Expeceted_E_prime, kernel_poly, codomain=BLS12_381_E, degree=11)
    # print("ISOOOO", iso)
    # print("ISOOOO", expected_iso)
    # assert expected_iso == iso, "iso mismatch"

def check_secp256k1_iso(iso):
    Ap = 0x3f8731abdd661adca08a5558f0f5d272e953d363cb6f0e5d405447c01a444533
    Bp = 1771

    Expected_Ep = EllipticCurve(SECP256K1_Fq, [Ap, Bp])

    expected_iso = EllipticCurveIsogeny(E=SECP256K1_E, kernel=None, codomain=Expected_Ep, degree=3).dual()
    if (- iso.rational_maps()[1])(1, 1) > iso.rational_maps()[1](1, 1):
        iso.switch_sign()

    assert iso == expected_iso, "iso mismatch"

def get_iso_rational_map_data(iso, curve_name):
    iso_rational_maps = iso.rational_maps()

    ## you can also access the rational maps separately
    xmap = iso_rational_maps[0]
    ymap = iso_rational_maps[1]

    ## and also their numerators and denominators
    xmap_num = xmap.numerator()
    xmap_den = xmap.denominator()
    ymap_num = ymap.numerator()
    ymap_den = ymap.denominator()
    iso_rational_map_data = {
        "xmap_num_coeffs": [hex(c) for c in reversed(xmap_num.coefficients())],
        "xmap_den_coeffs": [hex(c) for c in reversed(xmap_den.coefficients())],
        "ymap_num_coeffs": [hex(c) for c in reversed(ymap_num.coefficients())],
        "ymap_den_coeffs": [hex(c) for c in reversed(ymap_den.coefficients())]
    }

    pretty_print_iso_rational_map(curve_name, iso_rational_map_data)

    return iso_rational_map_data


CURVE_CHOICE = "GRUMPKIN"
ALREADY_FOUND_ISO = false
def start():
    check_constants()
    match CURVE_CHOICE:
        case "BLS12_381":
            if ALREADY_FOUND_ISO:
                # put whatever index for which `find_iso()` succeeded
                actual_prime_index = 4
                isogeny_degree = 11
                iso = compute_already_found_iso(BLS12_381_E, actual_prime_index)
            else:
                iso = find_iso(BLS12_381_E)
            check_bls12_381_iso(iso)
        case "SECP256K1":
            if ALREADY_FOUND_ISO:
                actual_prime_index = 1
                isogeny_degree = 3
                iso = compute_already_found_iso(SECP256K1_E, actual_prime_index)
            else:
                iso = find_iso(SECP256K1_E)
            check_secp256k1_iso(iso)
        case "GRUMPKIN":
            iso = find_iso(GRUMPKIN_E)
        case _:
            return "Unknown"
    
    E_prime = iso.dual().codomain()
    A_prime = E_prime.a4()
    B_prime = E_prime.a6()
    print(f"\n\n{CURVE_CHOICE}_ISO_A = {A_prime}")
    print(f"\n\n{CURVE_CHOICE}_ISO_B = {B_prime}")
    iso_rational_map_data = get_iso_rational_map_data(iso, CURVE_CHOICE)
    
start()