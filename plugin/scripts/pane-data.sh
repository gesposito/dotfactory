#!/bin/sh
# Prints what the dotfactory pane shows, for hooks/pane.tsx to parse.
# Usage: pane-data.sh <project folder>
#
# One record per line, fields separated by tabs:
#   brain    <brain folder>
#   pref     <name>  loaded|empty|skipped  <lines>   skipped: not for this folder
#   tool     <name>  <description>  here|other  <reach>   reach: see lib.sh
#   project  <name>  <purpose>
#   problem  <text>                                  the PROBLEM lines of status.sh

set -u
here=$(dirname "$0")
. "$here/lib.sh"

project=${1:-$PWD}
tab=$(printf '\t')

brain=$(brain_dir)
printf 'brain\t%s\n' "$brain"
[ -d "$brain" ] || exit 0

for file in "$brain"/prefs/*.md; do
  [ -f "$file" ] || continue
  name=$(basename "$file" .md)
  if ! applies "$file" "$project"; then
    printf 'pref\t%s\tskipped\t0\n' "$name"
  elif has_content "$file"; then
    printf 'pref\t%s\tloaded\t%s\n' "$name" "$(content_lines "$file")"
  else
    printf 'pref\t%s\tempty\t0\n' "$name"
  fi
done

for file in "$brain"/tools/*.md; do
  [ -f "$file" ] || continue
  if [ "$(expand_home "$(field path "$file")")" = "$project" ]; then
    where=here
  else
    where=other
  fi
  printf 'tool\t%s\t%s\t%s\t%s\n' "$(basename "$file" .md)" "$(field description "$file")" "$where" "$(reach "$file")"
done

# Lines in projects.md look like "- name: purpose" or just "- name".
if [ -f "$brain/projects.md" ]; then
  sed -n -e "s/^- \([^:]*\): *\(.*\)\$/project${tab}\1${tab}\2/p" \
    -e "s/^- \([^:]*\)\$/project${tab}\1${tab}/p" "$brain/projects.md"
fi

sh "$here/status.sh" | sed -n "s/^ *PROBLEM: */problem${tab}/p"

exit 0
