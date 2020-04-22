#!/bin/bash

# Find all TILS by searching for files ending in .md, excluding README.md
TILS=$(find . -name '*.md' | grep -vE 'README.md$')

while IFS=$'\n' read -r line; do
  head -n 1 $line  
done <<< "$TILS"
