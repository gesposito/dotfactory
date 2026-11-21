#!/bin/sh
# Records docs/demo.cast: the scenes in scenes.sh, run for real against a
# throwaway brain. Takes five to ten minutes.
#
#   sh docs/demo/record.sh
#
# Needs claude, cargo, git, perl and uvx (which runs asciinema without
# installing it).
#
# Every command in the recording ran as shown. Three things are done for the viewer:
#   - waits longer than 2 seconds are shortened
#   - the throwaway folder's long path is shown as ~/demo, and this checkout as ~/dotfactory
#   - sessions run with user settings off, so nothing personal is recorded

set -eu
here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../.." && pwd)
root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT

mkdir -p "$root/brain" "$root/code"
cp -R "$here/fixture/release-kit" "$root/code/release-kit"
chmod +x "$root/code/release-kit"/*.sh

export DOTFACTORY_BRAIN="$root/brain"
export DEMO_PLUGIN="$repo/plugin"
cd "$root/code"
uvx asciinema rec -q --overwrite --cols 100 --rows 32 -i 2 -t dotfactory \
  -c "sh $here/scenes.sh" "$root/demo.cast"

# Keep the brain the run produced, so docs can quote the real files.
rm -rf "$here/last-run-brain"
cp -R "$root/brain" "$here/last-run-brain"

# macOS reports the temporary folder under two names. Replace the longer first.
real=$(cd "$root" && pwd -P)
sed -e "s|$real|~/demo|g" -e "s|$root|~/demo|g" \
  -e "s|$repo|~/dotfactory|g" -e "s|$HOME|~|g" \
  "$root/demo.cast" >"$repo/docs/demo.cast"
echo "wrote docs/demo.cast"
