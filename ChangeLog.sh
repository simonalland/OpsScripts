#!/bin/bash

# Directories to Monitor
scanDirectory="/etc"

# Hash file location
hashFileLocation="/usr/scripts/changelog/hash"

# Make the ChangeLog directory
mkdir /usr/scripts/changelog

# Calculate the hash of the directory, use  a function for repeatability
calcHash() {
  find "$scanDirectory" -type f -exec md5sum {} + | md5sum | awk '{print $1}'
}

# Check if the hash file exists, if not then create it
if [ ! -f "$hashFileLocation" ]; then
    echo "Hash file not found. Creating new hash file."
    calcHash > "$hashFileLocation"
fi

# Calculate current hash values

currentHash=$(calcHash)

# Compare the hashes together, and upadte the file with the new hash value

prevHash=$(cat "$hashFileLocation")

if [ "$currentHash" != "$prevHash" ]; then
  echo "Contents have changed for the following location:" $scanDirectory
  echo "$currentHash" > "$hashFileLocation"
else
  echo "No Changes Found..."
fi
