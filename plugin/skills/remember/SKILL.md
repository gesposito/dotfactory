---
name: remember
description: Save one of my lasting preferences to my shared brain so every future session in every project follows it. Use when I say "remember", "from now on", "always" or "never" about how I like things done, or when I state a lasting preference about a language, tooling or how I work.
argument-hint: "[the preference]"
---

# Remember a preference

Save the preference I just stated to my brain folder.

If I haven't stated one, ask me what to remember before doing anything else. That happens when this runs with nothing after the command, for example from the dotfactory pane's button.

My brain folder is the one the session-start note names ("The user's shared brain folder is …"). If that note isn't in this conversation, run `${CLAUDE_PLUGIN_ROOT}/scripts/brain-path.sh` to print it. It's called BRAIN below.

A hook loads these files into new sessions. Whoever reads your line later has none of today's conversation, so write it to stand on its own.

## Where it goes

| The preference is about | File |
|---|---|
| One kind of project: a language, framework or toolchain | `BRAIN/prefs/<kind>.md`, for example `rust.md` |
| How one of my tools or experts should do its job | That tool's file in `BRAIN/tools/`, under a `## My preferences` heading |
| Anything else that holds across projects | `BRAIN/prefs/general.md` |
| Only the current project | Not the brain. Say so, and offer to put it in this project's `CLAUDE.md`. |

Look at the files that already exist before creating one. One file covers a whole ecosystem: a TypeScript preference goes in an existing `javascript.md`, not a new `typescript.md`.

## Files for one kind of project

Such a file starts with a `markers:` line, so it loads only in projects of that kind:

```markdown
---
markers: Cargo.toml
---

# Rust preferences
```

- `markers:` names files that only projects of that kind have, in the project's top folder.
- Name several, separated by spaces, when any one of them is enough: `markers: package.json tsconfig.json deno.json`.
- A file with no `markers:` line loads in every project. `general.md` is one of these.

When you create a new file of this kind, pick its markers yourself and tell me which you picked.

## How to write the preference

1. Read the target file first.
2. If a line already covers the same topic, change that line instead of adding another. If the new preference contradicts an old one, replace the old one and tell me what you replaced.
3. Write one bullet in this form: `- <the rule, in plain imperative words>. <the reason, if I gave one>.`
4. Keep the file short. The files that apply to a project share about 5,000 characters when a session loads them, so if a file is getting long, tell me and suggest lines to merge or drop.

Then confirm in one line: what you saved, and in which file.
