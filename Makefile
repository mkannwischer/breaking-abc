
CXXFLAGS=-Iabcmint/src/pqcrypto/
SRC=abcmint/src/pqcrypto/*.cpp verify.c sha2.c b64.c

verify: $(SRC)
	g++ $(CXXFLAGS) $(SRC) -o $@

clean:
	rm -rf *.o verify