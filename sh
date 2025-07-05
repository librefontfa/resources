#!/bin/bash

# Exit on any error
set -e

# Variables
URL="https://example.com/fonts.tar.gz"  # Replace with the actual URL of the compressed file
FILENAME=$(basename "$URL")             # Extract filename from URL
DOWNLOAD_DIR="/tmp/librefont.ir"        # Download directory
CHECKSUM="expected_checksum_here"       # Replace with the actual checksum (e.g., SHA256)
CHECKSUM_TYPE="sha256sum"               # Checksum type (e.g., md5sum, sha256sum, etc.)
FONT_INSTALL_DIR="/usr/local/share/fonts"  # System-wide font installation directory

# Function to display error and exit
error_exit() {
    echo "Error: $1" >&2
    exit 1
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for required tools
for tool in wget tar unzip sha256sum; do
    if ! command_exists "$tool"; then
        error_exit "Required tool '$tool' is not installed. Please install it and try again."
    fi
done

# Create download directory if it doesn't exist
if [ ! -d "$DOWNLOAD_DIR" ]; then
    echo "Creating directory: $DOWNLOAD_DIR"
    mkdir -p "$DOWNLOAD_DIR" || error_exit "Failed to create directory $DOWNLOAD_DIR"
fi

# Download the file
echo "Downloading $FILENAME from $URL..."
wget -O "$DOWNLOAD_DIR/$FILENAME" "$URL" || error_exit "Failed to download $FILENAME"

# Verify checksum
echo "Verifying checksum of $FILENAME..."
if [ -n "$CHECKSUM" ]; then
    computed_checksum=$($CHECKSUM_TYPE "$DOWNLOAD_DIR/$FILENAME" | awk '{print $1}')
    if [ "$computed_checksum" != "$CHECKSUM" ]; then
        error_exit "Checksum verification failed! Expected: $CHECKSUM, Got: $computed_checksum"
    else
        echo "Checksum verification passed."
    fi
else
    echo "Warning: No checksum provided. Skipping verification."
fi

# Decompress the file
echo "Decompressing $FILENAME..."
cd "$DOWNLOAD_DIR" || error_exit "Failed to change to directory $DOWNLOAD_DIR"

case "$FILENAME" in
    *.tar.gz | *.tgz)
        tar -xzf "$FILENAME" || error_exit "Failed to decompress $FILENAME"
        ;;
    *.tar.bz2 | *.tbz2)
        tar -xjf "$FILENAME" || error_exit "Failed to decompress $FILENAME"
        ;;
    *.zip)
        unzip -o "$FILENAME" || error_exit "Failed to decompress $FILENAME"
        ;;
    *)
        error_exit "Unsupported file format: $FILENAME. Supported formats: .tar.gz, .tar.bz2, .zip"
        ;;
esac

# Find and install font files
echo "Installing fonts to $FONT_INSTALL_DIR..."
if [ ! -d "$FONT_INSTALL_DIR" ]; then
    echo "Creating font directory: $FONT_INSTALL_DIR"
    sudo mkdir -p "$FONT_INSTALL_DIR" || error_exit "Failed to create font directory $FONT_INSTALL_DIR"
fi

# Find all .ttf and .otf files in the decompressed content and copy them
find "$DOWNLOAD_DIR" -type f \( -name "*.ttf" -o -name "*.otf" \) -exec sudo cp {} "$FONT_INSTALL_DIR/" \; || error_exit "Failed to install fonts"

# Update font cache
echo "Updating font cache..."
sudo fc-cache -fv || error_exit "Failed to update font cache"

# Clean up
echo "Cleaning up temporary files..."
rm -rf "$DOWNLOAD_DIR" || error_exit "Failed to clean up temporary files"

echo "Font installation completed successfully!"
exit 0
