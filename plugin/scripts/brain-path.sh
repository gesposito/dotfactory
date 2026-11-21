#!/bin/sh
# Prints the brain folder's path. The skills run this when the session-start
# note, which also gives the path, is no longer in the conversation.

set -u
. "$(dirname "$0")/lib.sh"
brain_dir
