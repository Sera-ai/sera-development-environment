#!/bin/bash
# Array of target directories
TARGET_DIRS=( "./be_Builder" "./be_Router" "./be_Socket" "./be_Sequencer" "./fe_Catalog" "./fe_Builder" )

# Function to generate SSL certificate in a specified directory
generate_ssl_certificate() {
    local dir="$1"
    echo "Generating SSL certificate in $dir"

    # Navigate to the target directory
    mkdir -p "$dir/certs" && cd "$dir/certs"

    # Generate the SSL certificate and key
    openssl req -x509 -out localhost.crt -keyout localhost.key \
        -newkey rsa:2048 -nodes -sha256 \
        -subj '/CN=localhost' -extensions EXT -config <( \
        printf "[dn]\nCN=localhost\n[req]\n\
        distinguished_name = dn\n[EXT]\n\
        subjectAltName=DNS:localhost\nkeyUsage=digitalSignature\n\
        extendedKeyUsage=serverAuth")
}

# Loop through each directory and generate SSL certificate
for dir in "${TARGET_DIRS[@]}"; do
    generate_ssl_certificate "$dir"
done
