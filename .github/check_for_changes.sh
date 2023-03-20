#!/bin/bash

diff --brief blogs.json new_blogs.json >/dev/null
CONTAINS_CHANGES=$?

if [ $CONTAINS_CHANGES -eq 1 ]; then
    echo "changes=true" >> $GITHUB_OUTPUT
else
    echo "changes=false" >> $GITHUB_OUTPUT
fi