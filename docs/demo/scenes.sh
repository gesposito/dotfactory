#!/bin/sh
# The scenes of the recording. record.sh runs this inside asciinema, in a
# throwaway folder with an empty brain. Every command shown is run for real.

# In the recording, `claude` is Claude Code with the plugin loaded and with the
# approvals a person would click through already given. User settings are off,
# so a session sees this plugin and nothing personal.
claude() {
  command claude --plugin-dir "$DEMO_PLUGIN" --setting-sources project,local --model sonnet \
    --permission-mode acceptEdits --add-dir "$DOTFACTORY_BRAIN" \
    --allowedTools "Bash(cargo init *),Bash(cargo check *),Bash(cargo build *),Bash(git init *),Bash(ls *),Bash(date *)" \
    "$@"
}

pause() { perl -e 'select(undef, undef, undef, $ARGV[0])' "$1"; }

# Prints a line of narration.
say() {
  printf '\n\033[1;36m# %s\033[0m\n' "$1"
  pause 1.5
}

# Types a command the way a person would, then runs it.
run() {
  printf '\033[1;32m$\033[0m '
  perl -e '$| = 1; for (split //, $ARGV[0]) { print; select(undef, undef, undef, 0.025) } print "\n"' "$1"
  eval "$1"
  pause 2
}

say "dotfactory: what you'd otherwise repeat in every Claude Code session."

say "1. Save preferences: one for Rust projects, one for every project."
run 'claude -p "/dotfactory:remember In Rust projects, use edition 2021 and ask me before adding a dependency."'
run 'claude -p "/dotfactory:remember Write commit messages in the imperative mood."'

say "2. Register tools: a repo, written notes, and an expert session."
run 'claude -p "/dotfactory:add-tool ./release-kit"'
run 'claude -p "/dotfactory:add-tool Notes for naming: a project name is a colour and an animal joined by a hyphen, like teal-otter. Use it whenever a project needs a name."'
run 'claude -p "/dotfactory:add-tool session reviewer: my code-review expert. Send it a diff and what the change is for, and it replies with findings. I start it with: claude --name reviewer"'

say "3. See what the brain holds now."
run 'claude -p "/dotfactory:status"'

say "4. Start a project. It applies the preferences and uses the naming tool."
run 'claude -p "/dotfactory:new A command-line tool that counts words in text files. Rust."'

project=$(ls -d */ 2>/dev/null | grep -v '^release-kit/$' | head -n 1)
if [ -n "$project" ]; then
  run "cd ${project%/} && grep edition Cargo.toml"

  say "5. A later session in that project starts with all of it in view."
  run 'claude -p "From the dotfactory note only: which of my preferences apply here, and which tools can you call on?"'
fi

say "That's dotfactory."
pause 2
