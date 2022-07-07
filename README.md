# Breaking Abcmint using Beullens' attack on Rainbow

Authors:
 - [Matthias J. Kannwischer](https://kannwischer.eu/)
 - [Lorenz Panny](https://yx7.cc/)
  
---

This repository demonstrates that we have successfully forged a signature for the Abcmint address
[84cJso7keg6SHW4vbNVbXccimCZrz7WoESXTtw12b5UsWqmm5](https://abcscan.io/#/Addressinformation?data=84cJso7keg6SHW4vbNVbXccimCZrz7WoESXTtw12b5UsWqmm5).

We extracted the public key corresponding to the address from the Abcmint blockchain and used a slightly tweaked variant of [Ward Beullens' attack](https://ia.cr/2022/214) and [his corresponding software](https://github.com/WardBeullens/BreakingRainbow)
to recover the corresponding private key.
The three 24-core servers we used were somewhat more powerful than Ward's laptop (of breaking-Rainbow-in-a-weekend fame), hence we expected roughly 5 hours of wall-clock time to solve one `Rainbow(16,32,32,32)` public key. We got lucky and found the key after only about 3 hours.

The recovered private key was then used to sign a message in the format of Abcmint's message-signing functionality, specified in https://github.com/abcmint/abcmint/blob/44dba015e2622a05a5af04e220d72a784dc48607/src/rpcwallet.cpp#L292. It could easily be used in the same way to sign transactions, but we have refrained from doing so.

The forged signature is:
```
address:   "84cJso7keg6SHW4vbNVbXccimCZrz7WoESXTtw12b5UsWqmm5"
message:   "There is no pot of gold at the end of the Rainbow." (ASCII)
signature: "TqERiKoFpkDEOEUGrq2WfH/XvTxP8dzbUxUpD1UyTUyLnVUaZcqW9IV+bTLIuamWS+XVKFcslYHLnxNcjcjnCA==" (Base64)
```

The Abcmint client should in theory allow you to verify this signature by entering the data above.
However, this functionality seems to be implemented incorrectly: It errors with "private key for the entered address is not available". Indeed, verification of signed messages only seems to work if you have the corresponding private key in your wallet, rendering the feature rather pointless.

As a workaround, we show below how to verify the signature using either our Sage script or the verification routines from the Abcmint codebase.

## Sage
```
sage verify.sage
```

prints

```
$ sage verify.sage
msg:   There is no pot of gold at the end of the Rainbow.
sig:   TqERiKoFpkDEOEUGrq2WfH/XvTxP8dzbUxUpD1UyTUyLnVUaZcqW9IV+bTLIuamWS+XVKFcslYHLnxNcjcjnCA==
h(pk): 84cJso7keg6SHW4vbNVbXccimCZrz7WoESXTtw12b5UsWqmm5
Signature is valid
```


## C++ implementation using the Abcmint codebase
```
make
./verify
```

prints

```
addr=84cJso7keg6SHW4vbNVbXccimCZrz7WoESXTtw12b5UsWqmm5
sig=TqERiKoFpkDEOEUGrq2WfH/XvTxP8dzbUxUpD1UyTUyLnVUaZcqW9IV+bTLIuamWS+XVKFcslYHLnxNcjcjnCA==
msg=There is no pot of gold at the end of the Rainbow.
Signature is valid!
```