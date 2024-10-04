load('constants.sage')
load('utils.sage') # bytes_to_num

def MapToCurve_Secp256k1_isogeny(u):
    u = SECP256K1_Fq(bytes_to_num(u))
    return MapToCurve(u, SECP256K1_Fq, SECP256K1_ISO_A, SECP256K1_ISO_B, BLS12_381_ISO_z)

def MapToCurve_Bls12_381_isogeny(u):
    u = BLS12_381_Fq(bytes_to_num(u))
    return MapToCurve(u, BLS12_381_Fq, BLS12_381_ISO_A, BLS12_381_ISO_B, BLS12_381_ISO_z)

# Input a field element (int) to this one
def MapToCurve_Grumpkin_isogeny(u):
    u = GRUMPKIN_Fq(u)
    return MapToCurve(u, GRUMPKIN_Fq, GRUMPKIN_ISO_A, GRUMPKIN_ISO_B, GRUMPKIN_ISO_z)

# Uses a more efficient method from https://www.di.ens.fr/~fouque/pub/latincrypt12.pdf that works for BN curves
def MapToCurve_Grumpkin(t):
    Fq = GRUMPKIN_Fq
    b = Fq(GRUMPKIN_B)

    assert t != 0, "0 not yet supported" # TODO

    t = Fq(t)

    t_2 = t * t

    sqrt_neg_3 = Fq(-3).sqrt()
    
    zeta = (Fq(-1) + sqrt_neg_3) / Fq(2)
    v = zeta - (sqrt_neg_3 * t_2) / (Fq(1) + b + t_2)
    y = (Fq(1) + b + t_2) / (sqrt_neg_3 * t)

    x1 = Fq(v)
    s1 = Fq(x1*x1*x1 + b)
    x2 = Fq(-1 - v)
    s2 = Fq(x2*x2*x2 + b)
    x3 = Fq(1 + y*y)
    s3 = Fq(x3*x3*x3 + b)
    y1 = s1.sqrt()
    y2 = s2.sqrt()
    y3 = s3.sqrt()

    if s1.is_square():
        return (x1, y1)
    elif s2.is_square():
        return (x2, y2)
    elif s3.is_square():
        return (x3, y3)
    else:
        print("Should be unreachable")


def MapToCurve(u, Fq, a, b, z):
    a = Fq(a)
    b = Fq(b)
    z = Fq(z)
    u_2 = u * u
    u_4 = u_2 * u_2
    tv1 = Fq(( z * z * u_4 + z * u_2) ^ (-1))  # Mod mul inv at the end
    x1 = (-b / a) * (Fq(1) + tv1)

    gx1 = x1*x1*x1 + a*x1 + b
    x2 = z * u*u * x1
    gx2 = x2*x2*x2 + a*x2 + b
    (x, y) = XY2Selector(x1, x2, gx1, gx2, Fq)

    y = y if (int(u) & 1) == (int(y) & 1) else -Fq(y)
    return (x, y) 
    
def XY2Selector(x1, x2, gx1, gx2, Fq):
    q = Fq.characteristic()
    (gx1_is_square, gx1_sqrt) = mod_sqrt(gx1, q)
    (gx2_is_square, gx2_sqrt) = mod_sqrt(gx2, q)
    assert(gx1_is_square or gx2_is_square)
    return (x1, gx1_sqrt) if gx1_is_square else (x2, gx2_sqrt)

def mod_sqrt(num, q):
    # sqrt = num ** ((q + 1) // 4)
    F = GF(q)
    is_square = F(num).is_square()
    sqrt = F(num).sqrt() if is_square else 0
    if is_square:
        assert sqrt * sqrt == num # really double check it, haha
    return (is_square, sqrt)