#!/bin/bash

# Use the MAXMIND_LICENSE_KEY from environment variable
if [ -z "$MAXMIND_LICENSE_KEY" ]; then
    echo "Error: MAXMIND_LICENSE_KEY environment variable is not set."
    exit 1
fi

# Function to download and verify a database
download_and_verify() {
    local edition_id=$1
    
    echo "Downloading $edition_id database and SHA256 checksum..."
    wget "https://download.maxmind.com/app/geoip_download?edition_id=$edition_id&license_key=$MAXMIND_LICENSE_KEY&suffix=tar.gz" -O "$edition_id.tar.gz"
    wget "https://download.maxmind.com/app/geoip_download?edition_id=$edition_id&license_key=$MAXMIND_LICENSE_KEY&suffix=tar.gz.sha256" -O "$edition_id.tar.gz.sha256"

    echo "Verifying SHA256 checksum for $edition_id..."
    # Extract the filename from the .sha256 file and use it for verification
    sha256_file=$(cat "$edition_id.tar.gz.sha256")
    expected_filename=$(echo "$sha256_file" | awk '{print $2}')
    expected_hash=$(echo "$sha256_file" | awk '{print $1}')
    
    # Rename the downloaded file to match the expected filename
    mv "$edition_id.tar.gz" "$expected_filename"
    
    # Verify the hash
    echo "$expected_hash $expected_filename" | sha256sum -c -

    echo "Extracting $edition_id database..."
    tar -xzf "$expected_filename"

    echo "Moving $edition_id.mmdb to current directory..."
    mv "$edition_id"*/"$edition_id.mmdb" .

    # Clean up
    rm "$expected_filename"
}

# Main script
echo "Starting MaxMind database update..."

# Download, verify, and extract databases
download_and_verify "GeoLite2-ASN"
download_and_verify "GeoLite2-City"
download_and_verify "GeoLite2-Country"

# Clean up unnecessary files, but keep .sha256.txt files
echo "Cleaning up unnecessary files..."
rm -rf GeoLite2-*/*.txt GeoLite2-*.tar.gz
rm -rf GeoLite2-ASN_* GeoLite2-City_* GeoLite2-Country_*

echo "Simulation completed. Check the current directory for .mmdb and .sha256.txt files."
