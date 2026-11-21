#!/bin/sh
# Prints a changelog for a repository: the commit subjects since its last tag.

repo=${1:?usage: changelog.sh <repo>}
last=$(git -C "$repo" describe --tags --abbrev=0 2>/dev/null) || last=""
git -C "$repo" log --pretty='- %s' ${last:+"$last"..HEAD}
