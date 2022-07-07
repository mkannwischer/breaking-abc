#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include "api.h"
#include "sha2.h"

unsigned char pk[CRYPTO_PUBLICKEYBYTES];
unsigned char sig[CRYPTO_BYTES];

bool DecodeBase64(unsigned char *out, const char* in);

int main(void){
    char addr[] = "84cJso7keg6SHW4vbNVbXccimCZrz7WoESXTtw12b5UsWqmm5";
    char sigb64[] = "TqERiKoFpkDEOEUGrq2WfH/XvTxP8dzbUxUpD1UyTUyLnVUaZcqW9IV+bTLIuamWS+XVKFcslYHLnxNcjcjnCA==";
    char msg[] = "There is no pot of gold at the end of the Rainbow.";

    printf("addr=%s\n", addr);
    printf("sig=%s\n", sigb64);
    printf("msg=%s\n", msg);

    // read pk from file
    FILE *f = fopen(addr, "rb");  // r for read, b for binary
    fread(pk, sizeof(pk), 1, f);
    fclose(f);

    char strMessageMagic[] = "Abcmint Signed Message:\n";
    if(strlen(msg) >= 253) {
        printf("msglen >= 253 bytes needs varint encoding; not implementend\n");
        return -1;
    }
    unsigned char buf[300];
    unsigned char h[32];
    unsigned char *ptr = buf;

    // compute sha256(sha256(len(strMessageMagic), strMessageMagic, len(msg), msg))
    // see rpcwallet.cpp line 327
    ptr[0] = strlen(strMessageMagic);
    ptr += 1;
    memcpy(ptr, strMessageMagic, strlen(strMessageMagic));
    ptr += strlen(strMessageMagic);
    ptr[0] = strlen(msg);
    ptr += 1;
    memcpy(ptr, msg, strlen(msg));
    ptr += strlen(msg);
    sha256(h, buf, 1+strlen(strMessageMagic)+1+strlen(msg));
    sha256(h, h, 32);

    // decode signature
    DecodeBase64(sig, sigb64);

    // verify signature using abcmint code
    int rc = rainbow_verify(h, sig, pk);
    if(rc == 0){
        printf("Signature is valid!\n");
    } else {
        printf("Signature is invalid!\n");
    }
}