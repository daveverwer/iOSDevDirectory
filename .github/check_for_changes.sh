#!/bin/bash
set -e

if diff -q -w blogs.json new_blogs.json > /dev/null 2>&1; then
    echo "changes=false" >> "$GITHUB_OUTPUT"
else
    echo "changes=true" >> "$GITHUB_OUTPUT"
fi