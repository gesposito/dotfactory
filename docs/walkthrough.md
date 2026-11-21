# Walkthrough

One example that uses every feature of dotfactory. Steps 1 to 5 are what the [recording](demo.svg) shows; the outputs and files quoted here are from that run. Steps 6 and 7 need more than one terminal command and aren't in the recording.

The example person:

- writes Rust, and has two habits they keep re-explaining to Claude;
- keeps a small repo of release scripts, `release-kit`;
- names projects after a colour and an animal;
- keeps a Claude Code session called `reviewer` open as a code-review expert.

Their brain starts empty.

The commands are shown as `claude -p "…"`, which runs one prompt and exits. Typing the same `/dotfactory:` command inside an interactive session does the same thing.

## 1. Save preferences

```sh
claude -p "/dotfactory:remember In Rust projects, use edition 2021 and ask me before adding a dependency."
claude -p "/dotfactory:remember Write commit messages in the imperative mood."
```

The first is about one kind of project, so it goes in a file that loads only in Rust projects. Claude picked the marker file itself and said so.

`brain/prefs/rust.md`:

```markdown
---
markers: Cargo.toml
---

# Rust preferences

- Use edition 2021 in Rust projects.
- Ask before adding a dependency to Cargo.toml.
```

The second holds everywhere, so it goes in a file with no markers.

`brain/prefs/general.md`:

```markdown
# General preferences

- Write git commit messages in the imperative mood (for example "Add parser", not "Added parser" or "Adds parser").
```

## 2. Register tools

A tool is anything a session can call on. There are three kinds, and this example has one of each.

**A repo**, by its path:

```sh
claude -p "/dotfactory:add-tool ./release-kit"
```

Claude read the README and the two scripts, ran nothing, and wrote `brain/tools/release-kit.md`. The entry lists each command, says which one only reads and which one pushes a tag, and tells future sessions to confirm with you before running the second.

**Notes**, by describing them:

```sh
claude -p "/dotfactory:add-tool Notes for naming: a project name is a colour and an animal joined by a hyphen, like teal-otter. Use it whenever a project needs a name."
```

`brain/tools/naming.md`:

```markdown
---
name: naming
description: Rules for naming a new project: a colour and an animal joined by a hyphen, like teal-otter. Use whenever a project needs a name.
---

## What it does

Gives the convention for naming projects, so every project name looks alike.

## How to use it

1. Pick a colour and an animal.
2. Join them with a hyphen, in lowercase: `<colour>-<animal>`, for example `teal-otter`.
3. Use that as the project name wherever one is needed (folder, repository, package).
4. If the name is already taken by another project, pick a different pair.
```

**An expert**, by its session name:

```sh
claude -p "/dotfactory:add-tool session reviewer: my code-review expert. Send it a diff and what the change is for, and it replies with findings. I start it with: claude --name reviewer"
```

`brain/tools/reviewer.md` records what to send the expert, what comes back, and what to do when its session isn't running.

Each time, Claude ends by showing the `description` line and asking whether it's right. That line is what every future session sees, so it's worth correcting.

## 3. See what the brain holds

```sh
claude -p "/dotfactory:status"
```

```
Brain folder: ~/demo/brain

Preferences
  general: 1 line(s), loads in every project
  rust: 2 line(s), loads in projects that have: Cargo.toml

Tools
  naming [notes]: Rules for naming a new project: a colour and an animal joined by a hyphen, like teal-otter. Use whenever a project needs a name.
  release-kit [repo]: Shell scripts to cut a git release: print a changelog from commits since the last tag, and tag and push v<version>. Use when preparing or publishing a release of any repo.
  reviewer [session reviewer]: Code-review expert session. Send it a diff and what the change is for; it replies with findings. Reach for it to get a second review of a change before committing or opening a PR.

Projects: none recorded

Git: the brain is not a git repository of its own, so changes to it aren't versioned (run 'git init' in it)
```

Anything that needs fixing shows as a line starting with `PROBLEM`, for example a tool whose folder no longer exists.

## 4. Start a project

```sh
claude -p "/dotfactory:new A command-line tool that counts words in text files. Rust."
```

From Claude's report:

- **Name:** `amber-heron`, the first of five candidates from the naming tool. In an interactive session you pick from the five.
- **Preferences applied:** Rust edition 2021, and no dependencies added.
- **Tools used:** `naming`. `release-kit` and `reviewer` were left alone, because neither is for starting a project.
- **Created:** the `cargo init` scaffold, a git repository, a short `CLAUDE.md`, and a line in `brain/projects.md`.
- **Not done:** nothing is committed, and there is no code beyond the scaffold.

The preference took effect. `cargo init` writes a newer edition by default:

```sh
$ cd amber-heron && grep edition Cargo.toml
edition = "2021"
```

`brain/projects.md`:

```markdown
# Projects

- amber-heron: command-line word counter for text files (Rust, 2026-11-21)
```

## 5. Open a later session

Nothing to run. Any session started in `amber-heron` from now on begins with a note that carries:

- `general.md`, because it has no markers;
- `rust.md`, because the folder has a `Cargo.toml`;
- one line per tool: its name, its kind and when to use it.

Asked what it already knew, a new session answered:

> **Preferences that apply**
>
> This is a Rust project, so both saved preference files apply:
> - **General:** Write git commit messages in the imperative mood, such as "Add parser".
> - **Rust:** Use edition 2021. Ask before adding any dependency to `Cargo.toml`.
>
> **Tools I can call on**
> - **naming** (notes): Rules for naming a new project, a colour and an animal joined by a hyphen.
> - **release-kit** (repo): Shell scripts that print a changelog from commits since the last tag, and tag and push `v<version>`.
> - **reviewer** (expert session): A code-review expert. I'd send it a diff and what the change is for, and it replies with findings. If that session isn't running, I'd tell you rather than guess its answer.

A session in a project with no `Cargo.toml` would get `general.md` and the same three tools, but not the Rust preferences.

## 6. Consult an expert

This step isn't in the recording, because it needs a second session running.

Say you finish a change in `amber-heron` and ask for a review. The session sees `reviewer` in its tool list and reads `brain/tools/reviewer.md`. It then messages the session named `reviewer` with the diff and what the change is for, waits for the reply, and shows you the findings.

- The expert answers from its own context, and with its own tools and permissions. Nothing it does runs in your project's session.
- It has to be running to answer. Start it with `claude --name reviewer` and leave it open, or send it to the background.
- If it isn't running, the session tells you so and carries on. It doesn't guess what the expert would have said.

The same expert serves every project. That is the point of registering it once.

## 7. Open the pane

Also not in the recording, because the pane is part of the interactive screen.

In an interactive session, `/dotfactory` opens a pane beside the conversation. It has a button for each of the four commands, then your preferences files and whether each applies to this folder, the tools, the projects, and any `PROBLEM` lines. Press `1` to `4` to run a command. See [the README](../README.md#the-panes-buttons) for the keys.

## The brain afterwards

```
brain/
  prefs/
    general.md         loads in every project
    rust.md            loads where there is a Cargo.toml
  tools/
    naming.md          notes
    release-kit.md     a repo
    reviewer.md        an expert session
  projects.md          amber-heron
```

Six small markdown files. Edit any of them by hand whenever you like.

## How the recording was made

`sh docs/demo/record.sh` runs the commands of steps 1 to 5 for real, in a throwaway folder with an empty brain. Three things are done for the viewer:

- Waits longer than two seconds are shortened. The real run takes several minutes.
- The throwaway folder's long path is shown as `~/demo`.
- Each session runs with user settings off and with file edits approved in advance, so the recording shows this plugin and nothing personal.

Claude's wording differs from run to run, so a new recording won't match this page word for word.
