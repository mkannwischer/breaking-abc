#!/usr/bin/env sage
import base64
import hashlib
import struct

# be aware that this is not the usual base58, but contains modifications to the
# alphabet and checksum computation
import base58


addr = "84cJso7keg6SHW4vbNVbXccimCZrz7WoESXTtw12b5UsWqmm5"
msg = "There is no pot of gold at the end of the Rainbow."
sig = "TqERiKoFpkDEOEUGrq2WfH/XvTxP8dzbUxUpD1UyTUyLnVUaZcqW9IV+bTLIuamWS+XVKFcslYHLnxNcjcjnCA=="

print(f"msg:   {msg}")
print(f"sig:   {sig}")
print(f"h(pk): {addr}")

################################################################

# convert from Rainbow tower field to F_2[x]/(x^4 + x + 1)
F16.<y> = GF(16)
assert y^4+y+1 == 0
x = y^2+y
assert x^2+x+1 == 0

def nib2el(nib):
    assert 0 <= nib < 16
    a,b,c,d = ((nib>>i)&1 for i in range(4))
    return (a+b*x) + (c+d*x)*y

def bytesToGF16vec(t):
    t = [(t[i//2]>>i%2*4)&0xf for i in range(2*len(t))]
    return vector(map(nib2el, t))

################################################################

n = 96
m = 64

# read public key
pk = open(addr,'rb').read()
if pk[-1] != 0x10 or len(pk) != 152097:
    raise ValueError('not an ABCMint public key')

# verify that it is indeed the public key corresponding to addr
def hashPk(pk):
    h = hashlib.sha256(pk).digest()
    h = hashlib.sha256(h).digest()
    h = b'\x00' + h
    return base58.b58encode_check(h).decode()

assert hashPk(pk) == addr

# convert to GF(16) elements
pk = list(bytesToGF16vec(pk[:-1]))

def consume(count):
    global pk
    assert len(pk) >= count
    r, pk = pk[:count], pk[count:]
    return r

# split into linear, quadratic, and constant parts
linear = consume(n*m)
quadratic = consume(n*(n+1)//2*m)
constant = consume(m)
assert not pk

# convert to matrix, vector
b = matrix(F16, n, m, linear)
c = vector(constant)

Acoeffs = quadratic[::-1]
As = [matrix(F16, n, n) for _ in range(m)]
for i in range(n):
    for j in range(i+1):
        for k in range(m):
            As[k][i,j] = Acoeffs.pop()
assert not Acoeffs; del Acoeffs

# Rainbow public map
def pubmap(x):
    assert x in F16^n
    y = vector(x*A*x for A in As)
    y += x*b
    y += c
    assert y in F16^m
    return y

################################################################

# decode signature
sig = base64.b64decode(sig)
assert len(sig) == 64
salt = sig[48:]
sig = sig[:48]

# convert signature to GF(16)
sig = bytesToGF16vec(sig)

# apply public map to signature to obtain hash of message
h1 = pubmap(sig)

def encode_varint(value):
    if value < pow(2, 8) - 3:
        size = 1
        varint = bytes([value])
    else:
        if value < pow(2, 16):
            size = "<H"
            prefix = 253  # 0xFD
        elif value < pow(2, 32):
            size = "<I"
            prefix = 254  # 0xFE
        elif value < pow(2, 64):
            size = "<Q"
            prefix = 255  # 0xFF
        else:
            raise Exception("Wrong input data size")
        varint = bytes([prefix]) + struct.pack(size, value)

    return varint

# compute hash of the message and convert to GF(16)
def abchash(msg, salt):
    strMessageMagic = "Abcmint Signed Message:\n"
    strMessageMagicLength = encode_varint(len(strMessageMagic))

    strLength = encode_varint(len(msg))
    buf = strMessageMagicLength + bytes(strMessageMagic, "ascii") + strLength + bytes(msg, "ascii")
    t = hashlib.sha256(buf).digest()
    t = hashlib.sha256(t).digest()
    buf = t + salt
    return hashlib.sha256(buf).digest()

h0 = abchash(msg, salt)
h0 = bytesToGF16vec(h0)

if h0 == h1:
    print("Signature is valid")
else:
    print("Signature is invalid")

