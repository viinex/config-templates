#!/bin/bash

# Title: generate_ed25519_hex.sh
# Description: Generates a raw Ed25519 private key seed and its corresponding
# public key, outputting both in 32-byte hexadecimal format.

# --- Configuration ---
TEMP_PRIVATE_DER=$(mktemp)
TEMP_PUBLIC_DER=$(mktemp)
KEY_SIZE_BYTES=32

# Function to clean up temporary files on exit
cleanup() {
    rm -f "$TEMP_PRIVATE_DER" "$TEMP_PUBLIC_DER"
}
trap cleanup EXIT

echo "--- Ed25519 Key Generation Script ---"

# 1. Generate the Ed25519 key pair using OpenSSL
# We output in DER format (PKCS#8) as it is easier to parse raw bytes from.
openssl genpkey \
    -algorithm Ed25519 \
    -outform DER \
    -out "$TEMP_PRIVATE_DER" 2>/dev/null

if [ $? -ne 0 ]; then
    echo "Error: openssl key generation failed. Ensure OpenSSL supports Ed25519." >&2
    exit 1
fi

# 2. Extract the Public Key (in DER format)
# This converts the private key DER structure into the public key DER structure (SubjectPublicKeyInfo).
openssl pkey \
    -in "$TEMP_PRIVATE_DER" \
    -inform DER \
    -pubout \
    -outform DER \
    -out "$TEMP_PUBLIC_DER" 2>/dev/null

# 3. Extract and format the Private Key Seed (32 bytes)
# The Ed25519 private key seed is typically the last 32 bytes of the PKCS#8 DER structure.
RAW_PRIVATE_HEX=$(
    tail -c $KEY_SIZE_BYTES "$TEMP_PRIVATE_DER" | \
    xxd -p | \
    tr -d '\n'
)

# 4. Extract and format the Public Key (32 bytes)
# The raw public key is typically the last 32 bytes of the SubjectPublicKeyInfo DER structure.
RAW_PUBLIC_HEX=$(
    tail -c $KEY_SIZE_BYTES "$TEMP_PUBLIC_DER" | \
    xxd -p | \
    tr -d '\n'
)

# 5. Output results
echo ""
echo "Private Key Seed (32 bytes / 64 hex characters):"
echo "$RAW_PRIVATE_HEX"
echo ""
echo "Public Key (32 bytes / 64 hex characters):"
echo "$RAW_PUBLIC_HEX"
echo ""

# The cleanup function will run automatically due to the 'trap cleanup EXIT' command
echo "Temporary files cleaned up successfully."

exit 0
