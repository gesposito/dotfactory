#!/bin/sh
# Tags a repository's current commit as v<version> and pushes the tag.

repo=${1:?usage: tag.sh <repo> <version>}
version=${2:?usage: tag.sh <repo> <version>}
git -C "$repo" tag "v$version" && git -C "$repo" push origin "v$version"
