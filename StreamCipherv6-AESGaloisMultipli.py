# Stream Cipher v6 - AES Galois Multiplier 3

def xtime(d: int) -> int:
       
       # Extract bits from the input byte 'd'
        d0 = (d >> 0) & 1 
        d1 = (d >> 1) & 1
        d2 = (d >> 2) & 1
        d3 = (d >> 3) & 1
        d4 = (d >> 4) & 1
        d5 = (d >> 5) & 1
        d6 = (d >> 6) & 1
        d7 = (d >> 7) & 1

        # e = {d[6], d[5], d[4], d[3]⊕d[7], d[2]⊕d[7], d[1], d[0]⊕d[7], d[7]}
        e7 = d6
        e6 = d5
        e5 = d4
        e4 = d3 ^ d7  
        e3 = d2 ^ d7
        e2 = d1
        e1 = d0 ^ d7
        e0 = d7

        # Combine the bits into a single byte 
        e = (e7 << 7) | (e6 << 6) | (e5 << 5) | (e4 << 4) | (e3 << 3) | (e2 << 2) | (e1 << 1) | (e0 << 0)
        
        return e

# Galois multiplication
def S(a: int) -> int: 
   
    # Extract bytes from most significant A[0] to least significant A[3]
    a0 = (a >> 24) & 0xFF
    a1 = (a >> 16) & 0xFF
    a2 = (a >> 8) & 0xFF
    a3 = a & 0xFF

    # Calculate f = xtime(A[2] ⊕ A[3]) ⊕ A[3] ⊕ A[0] ⊕ A[1]
    f = xtime(a2 ^ a3) ^ a3 ^ a0 ^ a1
    return f 
    
class StreamCipherV6():

    # Initialize the cipher with a fixed-length 32-bit key
    def __init__(self, key: int): 
        self.key = key & 0xFFFFFFFF

    # Process the input data byte by byte, applying the encryption/decryption law
    def process(self, data: bytes) -> bytes:
        output = bytearray()
        
        for i, byte in enumerate(data):
            # 32-bit Counter Block CB[i] = (K + i) mod 2^32 
            CB_i = (self.key + i) & 0xFFFFFFFF
            
            # Generate f = S(CB[i])
            f = S(CB_i)
            
            # Encryption/decryption law: Data[i] ⊕ S(CB[i])
            output_byte = byte ^ f
            output.append(output_byte)
            
        return bytes(output)

""""
if __name__ == "__main__":

    K = 0xEA010801
    plaintext = b"This is a test message for the Stream Cipher" 
    ciphertext = StreamCipherV6(K).process(plaintext)
    decrypted = StreamCipherV6(K).process(ciphertext)

    if decrypted == plaintext:
        print("Decryption successful, plaintext matches original.")
"""

# Test Vectors for ModelSim

import os

if __name__ == "__main__":
    
    # Generates a random key 32-bit (4 byte)
    random_key_bytes = os.urandom(4)
    K = int.from_bytes(random_key_bytes, byteorder='big')
   
    cipher = StreamCipherV6(K)
    
    # Generates a random plaintext of random lenght (under 64 bytes)
    num_test_bytes = 64
    plaintext = os.urandom(num_test_bytes)
    
    ciphertext = cipher.process(plaintext)

    current_script_dir = os.path.dirname(os.path.abspath(__file__))
    target_dir = os.path.abspath(os.path.join(current_script_dir, "..", "..", "project_930II_2025_2026_palandri", "modelsim", "tv"))
    os.makedirs(target_dir, exist_ok=True)
     
    # {K:02X} HEX conversion of 2 cipher bytes
    # {K:08X} creates the 8-digit hexadecimal representation of the key, zero-padded if necessary
    
    # Key saving
    with open(os.path.join(target_dir, "key.txt"), "w") as f_key:
        f_key.write(f"{K:08X}\n")
        
    # Plaintext saving
    with open(os.path.join(target_dir, "ptxt.txt"), "w") as f_ptxt:
        for byte in plaintext:
            f_ptxt.write(f"{byte:02X}\n")
            
    # Cyphertext saving
    with open(os.path.join(target_dir, "ctxt.txt"), "w") as f_ctxt:
        for byte in ciphertext:
            f_ctxt.write(f"{byte:02X}\n")       