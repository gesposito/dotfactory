# Shared by the scripts in this folder. Source it; don't run it.
#
# Nothing here knows about a particular language, tool or project. What applies
# where is written in the brain's own files.

# Budgets for what the session-start hook prints. Claude Code keeps at most
# 10,000 characters of a hook's output. The two budgets add up to 7,500, which
# leaves room for the fixed text around them (about 1,300 with a long brain path).
#
# Everything is measured with the shell's ${#text}: characters in a UTF-8
# locale, bytes otherwise. Bytes are never fewer than characters, so the total
# stays under Claude Code's limit either way. What matters is that text is
# measured and cut with the same unit.
PREFS_BUDGET=5500 # shared by every preferences file that applies
TOOLS_BUDGET=2000

# Turns a leading ~/ into the home folder.
expand_home() {
  case $1 in
    "~/"*) echo "$HOME/${1#\~/}" ;;
    *) echo "$1" ;;
  esac
}

# Prints the brain folder's path. The folder may not exist yet.
#   1. $DOTFACTORY_BRAIN, when set
#   2. a "brain" folder next to the plugin folder of a checkout
#      (laid out as <repo>/plugin and <repo>/brain)
#   3. ~/.config/dotfactory/brain
brain_dir() {
  if [ -n "${DOTFACTORY_BRAIN:-}" ]; then
    expand_home "$DOTFACTORY_BRAIN"
    return
  fi
  _root=${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}
  # A checkout has the marketplace file one level above the plugin folder. A
  # copy that Claude Code installed into its plugin cache doesn't, so nothing
  # that happens to sit beside such a copy is taken for a brain.
  if [ -f "$_root/../.claude-plugin/marketplace.json" ] && [ -d "$_root/../brain" ]; then
    (cd "$_root/../brain" && pwd)
  else
    echo "${XDG_CONFIG_HOME:-$HOME/.config}/dotfactory/brain"
  fi
}

# Prints a file's frontmatter: the lines between a first line of "---" and the
# next "---". Prints nothing for a file that doesn't start with "---".
frontmatter() {
  awk 'NR == 1 { if ($0 != "---") exit; next } $0 == "---" { exit } { print }' "$1"
}

# Prints a file without its frontmatter.
body() {
  awk 'NR == 1 && $0 == "---" { skip = 1; next }
       skip && $0 == "---" { skip = 0; next }
       !skip { print }' "$1"
}

# Prints one frontmatter field: field <name> <file>
field() {
  frontmatter "$2" | sed -n "s/^$1:[[:space:]]*//p" | head -n 1
}

# True if the file's body has a line that is neither blank nor a heading.
has_content() {
  [ -f "$1" ] && body "$1" | grep -qvE '^[[:space:]]*(#.*)?$'
}

# Counts those lines.
content_lines() {
  body "$1" | grep -cvE '^[[:space:]]*(#.*)?$'
}

# True if a preferences file applies in a project folder: applies <file> <project>
# A file with no "markers:" field applies everywhere. One with markers applies
# where the project folder has a file that matches at least one of them. A
# marker is a file name, such as Cargo.toml, or a pattern, such as *.csproj.
applies() {
  _markers=$(field markers "$1" | tr ',' ' ')
  [ -z "$_markers" ] && return 0
  # Split the list with pattern expansion off. Otherwise a pattern would be
  # expanded here, against whatever folder this script happens to run in.
  set -f
  set -- "$2" $_markers
  set +f
  _project=$1
  shift
  for _marker in "$@"; do
    # $_marker is unquoted on purpose: this is where a pattern is expanded,
    # inside the project folder. With no match the pattern stays as it is and
    # fails the test below.
    for _match in "$_project"/$_marker; do
      [ -e "$_match" ] && return 0
    done
  done
  return 1
}

# Says how a tool is reached: "session <name>", "repo" or "notes".
reach() {
  _session=$(field session "$1")
  if [ -n "$_session" ]; then
    echo "session $_session"
  elif [ -n "$(field path "$1")" ]; then
    echo "repo"
  else
    echo "notes"
  fi
}
