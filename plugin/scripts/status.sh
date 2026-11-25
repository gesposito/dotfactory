#!/bin/sh
# Prints what the brain holds and flags anything that needs fixing.
# Used by /dotfactory:status. Lines that need action start with PROBLEM.

set -u
. "$(dirname "$0")/lib.sh"

brain=$(brain_dir)
if [ ! -d "$brain" ]; then
  echo "Brain folder: $brain (not created yet)"
  echo "It's created the first time something is saved with /dotfactory:remember or /dotfactory:add-tool."
  exit 0
fi
echo "Brain folder: $brain"

echo
echo "Preferences"
count=0
for file in "$brain"/prefs/*.md; do
  [ -f "$file" ] || continue
  count=$((count + 1))
  name=$(basename "$file" .md)
  markers=$(field markers "$file")
  if [ -n "$markers" ]; then
    where="loads in projects that have: $markers"
  else
    where="loads in every project"
  fi
  if has_content "$file"; then
    echo "  $name: $(content_lines "$file") line(s), $where"
  else
    echo "  $name: empty, $where"
  fi
  # Measured as the hook measures it: see the budgets in lib.sh.
  text=$(body "$file")
  if [ "${#text}" -gt "$PREFS_BUDGET" ]; then
    echo "  PROBLEM: $name.md is longer than the $PREFS_BUDGET characters a session can load, so sessions only see the start of it. Shorten it."
  fi
done
[ "$count" -eq 0 ] && echo "  none saved (add one with /dotfactory:remember)"

echo
echo "Tools"
count=0
for file in "$brain"/tools/*.md; do
  [ -f "$file" ] || continue
  count=$((count + 1))
  name=$(basename "$file" .md)
  path=$(expand_home "$(field path "$file")")
  description=$(field description "$file")
  echo "  $name [$(reach "$file")]: $description"
  if [ -n "$path" ] && [ ! -d "$path" ]; then
    echo "  PROBLEM: $name points at a folder that doesn't exist ($path). Fix 'path:' in $file or delete the file."
  fi
  if [ -z "$description" ]; then
    echo "  PROBLEM: $name has no 'description:' line, so sessions can't tell when to use it."
  fi
done
[ "$count" -eq 0 ] && echo "  none registered (add one with /dotfactory:add-tool)"

echo
if [ -f "$brain/projects.md" ]; then
  echo "Projects: $(grep -c '^- ' "$brain/projects.md") recorded"
else
  echo "Projects: none recorded"
fi

# The brain is personal, so it should be a git repository of its own and not a
# folder inside some other one.
echo
top=$(git -C "$brain" rev-parse --show-toplevel 2>/dev/null) || top=""
if [ -n "$top" ] && [ "$(cd "$top" && pwd -P)" = "$(cd "$brain" && pwd -P)" ]; then
  changes=$(git -C "$brain" status --porcelain | grep -c .)
  if [ "$changes" -eq 0 ]; then
    echo "Git: brain has no uncommitted changes"
  else
    echo "Git: brain has $changes uncommitted change(s)"
  fi
else
  echo "Git: the brain is not a git repository of its own, so changes to it aren't versioned (run 'git init' in it)"
fi

exit 0
