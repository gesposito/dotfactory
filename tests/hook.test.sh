#!/bin/sh
# Tests for the scripts in plugin/scripts.
# Run from anywhere: sh tests/hook.test.sh
#
# Each test builds a throwaway brain and project and points the scripts at it
# with DOTFACTORY_BRAIN, so no real brain is ever read.

set -u
repo=$(cd "$(dirname "$0")/.." && pwd)
hook=$repo/plugin/scripts/session-start.sh
status=$repo/plugin/scripts/status.sh
pane=$repo/plugin/scripts/pane-data.sh
brain_path=$repo/plugin/scripts/brain-path.sh

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
t=$(printf '\t')
export DOTFACTORY_BRAIN="$tmp/brain"

failed=0
check() { # check <description> <command...>
  _what=$1
  shift
  if "$@"; then
    echo "ok    $_what"
  else
    echo "FAIL  $_what"
    failed=1
  fi
}
has() { printf '%s' "$out" | grep -qF -- "$1"; }
lacks() { ! has "$1"; }

# A fresh brain and an empty project for each test. The brain has one
# preferences file for every project and two that name marker files.
setup() {
  rm -rf "$tmp/brain" "$tmp/project" "$tmp/other-tool"
  mkdir -p "$tmp/brain/prefs" "$tmp/brain/tools" "$tmp/project" "$tmp/other-tool"
  printf '# General preferences\n' >"$tmp/brain/prefs/general.md"
  printf -- '---\nmarkers: Cargo.toml\n---\n\n# Rust preferences\n- RUST-RULE\n' \
    >"$tmp/brain/prefs/rust.md"
  printf -- '---\nmarkers: package.json tsconfig.json\n---\n\n# JS preferences\n- JS-RULE\n' \
    >"$tmp/brain/prefs/javascript.md"
}
write_tool() { # write_tool <name> <frontmatter line...>
  _name=$1
  shift
  {
    echo '---'
    echo "name: $_name"
    for _line in "$@"; do echo "$_line"; done
    echo '---'
    echo
    echo '## What it does'
  } >"$tmp/brain/tools/$_name.md"
}
# One tool of each kind, plus one that is the project itself and one whose folder is gone.
write_tools() {
  write_tool other-tool "path: $tmp/other-tool" "description: TOOL-DESC"
  write_tool naming "session: namer" "description: NAMING-DESC"
  write_tool release "description: RELEASE-DESC"
  write_tool this-tool "path: $tmp/project" "description: SELF-DESC"
}
run_hook() { # run_hook <source>
  out=$(printf '{"hook_event_name":"SessionStart","source":"%s"}' "$1" |
    CLAUDE_PROJECT_DIR="$tmp/project" sh "$hook")
  code=$?
}

setup
run_hook startup
check "empty folder: suggests /dotfactory:new" has "/dotfactory:new"
check "empty folder: names the brain folder" has "$tmp/brain"
check "empty folder: loads no preferences that need a marker" lacks "RULE"
check "heading-only preferences file is not printed" lacks "General preferences"
check "exits 0" [ "$code" -eq 0 ]

setup
touch "$tmp/project/Cargo.toml"
run_hook startup
check "project with Cargo.toml: loads the file that names it" has "RUST-RULE"
check "project with Cargo.toml: skips files that name other markers" lacks "JS-RULE"
check "a file's frontmatter is not printed" lacks "markers:"
check "non-empty folder: no /dotfactory:new suggestion" lacks "/dotfactory:new"

setup
touch "$tmp/project/tsconfig.json"
run_hook startup
check "any one of a file's markers is enough" has "JS-RULE"

setup
touch "$tmp/project/Cargo.toml"
run_hook resume
check "resumed session: prints nothing" [ -z "$out" ]
run_hook compact
check "after compaction: prints preferences again" has "RUST-RULE"

setup
printf -- '- GENERAL-RULE\n' >>"$tmp/brain/prefs/general.md"
printf '# Writing\n- WRITING-RULE\n' >"$tmp/brain/prefs/writing.md"
mkdir "$tmp/project/src"
run_hook startup
check "a file with no markers loads in every project" has "GENERAL-RULE"
check "that holds for any file name, not only general" has "WRITING-RULE"

# Nothing in the plugin lists languages: a new kind of project is one new file.
setup
printf -- '---\nmarkers: Package.swift\n---\n- SWIFT-RULE\n' >"$tmp/brain/prefs/swift.md"
mkdir "$tmp/project/src"
run_hook startup
check "a new kind of project: skipped where its marker is absent" lacks "SWIFT-RULE"
touch "$tmp/project/Package.swift"
run_hook startup
check "a new kind of project: loaded where its marker is present" has "SWIFT-RULE"

setup
write_tools
touch "$tmp/project/README.md"
run_hook startup
check "tools: a repo" has "- other-tool [repo]: TOOL-DESC"
check "tools: an expert session" has "- naming [session namer]: NAMING-DESC"
check "tools: written notes" has "- release [notes]: RELEASE-DESC"
check "tools: skips the tool this session is in" lacks "SELF-DESC"
check "tools: says how to consult an expert" has "message its session by name"

setup
touch "$tmp/project/Cargo.toml" "$tmp/project/package.json"
for file in general rust javascript; do
  i=0
  while [ $i -lt 400 ]; do
    echo "- a long preference line number $i that pads the file" >>"$tmp/brain/prefs/$file.md"
    i=$((i + 1))
  done
done
i=0
while [ $i -lt 60 ]; do
  write_tool "tool-$i" "path: /nowhere/$i" "description: a tool description that takes up some room"
  i=$((i + 1))
done
run_hook startup
check "oversized brain: output stays under 10,000 characters" [ "${#out}" -lt 10000 ]
check "oversized brain: says where the rest is" has "Read the rest in"
check "oversized brain: counts the tools it left out" has "more. List them with"

setup
i=0
while [ $i -lt 40 ]; do
  printf -- '- rule %s of a preferences file that applies to every project\n' "$i" \
    >"$tmp/brain/prefs/topic-$i.md"
  i=$((i + 1))
done
mkdir "$tmp/project/src"
run_hook startup
check "many preferences files: output stays under 10,000 characters" [ "${#out}" -lt 10000 ]
check "many preferences files: says some didn't fit" has "more preferences file(s) apply here"

setup
rm -rf "$tmp/brain"
run_hook startup
check "no brain yet: says so" has "doesn't exist yet"
check "no brain yet: still names where it will be" has "$tmp/brain"
check "no brain yet: still suggests /dotfactory:new in an empty folder" has "/dotfactory:new"
check "no brain yet: still exits 0" [ "$code" -eq 0 ]

# Where the brain is. DOTFACTORY_BRAIN wins, then a "brain" folder next to the
# plugin folder, then ~/.config/dotfactory/brain.
mkdir -p "$tmp/checkout/plugin" "$tmp/checkout/brain" "$tmp/lonely/plugin"
out=$(DOTFACTORY_BRAIN="$tmp/elsewhere" CLAUDE_PLUGIN_ROOT="$tmp/checkout/plugin" sh "$brain_path")
check "brain location: DOTFACTORY_BRAIN wins" [ "$out" = "$tmp/elsewhere" ]
out=$(env -u DOTFACTORY_BRAIN CLAUDE_PLUGIN_ROOT="$tmp/checkout/plugin" sh "$brain_path")
check "brain location: next to the plugin folder" has "/checkout/brain"
out=$(env -u DOTFACTORY_BRAIN CLAUDE_PLUGIN_ROOT="$tmp/lonely/plugin" XDG_CONFIG_HOME="$tmp/config" sh "$brain_path")
check "brain location: the default" [ "$out" = "$tmp/config/dotfactory/brain" ]

setup
write_tools
write_tool gone "path: /nowhere/gone" "description: x"
write_tool undescribed "session: someone"
printf '# Projects\n\n- alpha: first project\n- beta\n' >"$tmp/brain/projects.md"
out=$(sh "$status")
check "status: flags a tool whose folder is gone" has "PROBLEM: gone points at a folder"
check "status: flags a tool with no description" has "PROBLEM: undescribed has no 'description:'"
check "status: shows how each tool is reached" has "naming [session namer]: NAMING-DESC"
check "status: says where a marker file loads" has "rust: 1 line(s), loads in projects that have: Cargo.toml"
check "status: says a file with no markers loads everywhere" has "general: empty, loads in every project"
check "status: counts projects" has "Projects: 2 recorded"
check "status: a brain inside no repository of its own is flagged" has "not a git repository of its own"
git init -q "$tmp/brain"
out=$(sh "$status")
check "status: a brain that is its own repository reports its changes" has "uncommitted change(s)"

# pane-data.sh feeds the dotfactory pane. hooks/pane.tsx depends on these exact records.
setup
write_tools
write_tool gone "path: /nowhere/gone" "description: x"
touch "$tmp/project/Cargo.toml"
printf '# Projects\n\n- alpha: first project\n- beta\n' >"$tmp/brain/projects.md"
out=$(sh "$pane" "$tmp/project")
check "pane data: names the brain folder" has "brain${t}$tmp/brain"
check "pane data: a file with nothing saved" has "pref${t}general${t}empty${t}0"
check "pane data: a file that applies here" has "pref${t}rust${t}loaded${t}1"
check "pane data: a file that isn't for this folder" has "pref${t}javascript${t}skipped${t}0"
check "pane data: the tool this project is" has "tool${t}this-tool${t}SELF-DESC${t}here${t}repo"
check "pane data: a repo" has "tool${t}other-tool${t}TOOL-DESC${t}other${t}repo"
check "pane data: an expert session" has "tool${t}naming${t}NAMING-DESC${t}other${t}session namer"
check "pane data: written notes" has "tool${t}release${t}RELEASE-DESC${t}other${t}notes"
check "pane data: project with a purpose" has "project${t}alpha${t}first project"
check "pane data: project without a purpose" has "project${t}beta${t}"
check "pane data: passes on status problems" has "problem${t}gone points at a folder"
rm -rf "$tmp/brain"
out=$(sh "$pane" "$tmp/project")
check "pane data: no brain yet gives only the brain record" [ "$out" = "brain${t}$tmp/brain" ]

if [ "$failed" -eq 0 ]; then echo "All tests passed."; else echo "Some tests FAILED."; fi
exit "$failed"
