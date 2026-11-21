---
name: new
description: Start a new project the way I like it. Applies my saved preferences, uses the tools and experts I've registered for new projects (naming, licensing, repository setup or anything else), scaffolds the project and records it. Use when I say I'm starting a new project, app, tool or repo, or when the session-start note says the folder is empty.
argument-hint: "[what the project is for]"
---

# Start a new project

You're setting up a new project for me. This skill exists so I don't have to repeat myself: my preferences, the tools I can call on and the projects I've already started are all in my brain folder.

My brain folder is the one the session-start note names ("The user's shared brain folder is …"). If that note isn't in this conversation, run `${CLAUDE_PLUGIN_ROOT}/scripts/brain-path.sh` to print it. It's called BRAIN below.

## 1. Find out what's missing

You need three things. Ask only for the ones you can't tell from what I said, in one round of questions:

- **Purpose**: one or two sentences on what the project is for.
- **Kind**: the language or framework, for example Rust or TypeScript.
- **Location**: if the current folder is empty, the project goes here. Otherwise it goes in a new folder inside the current one.

## 2. Read my preferences

Read the files in `BRAIN/prefs/` that apply to this project. The session-start note can't have loaded them for a folder that is still empty.

- A file with no `markers:` line at its top applies to every project.
- A file with a `markers:` line applies when the project will contain one of the files it names. For example, `markers: Cargo.toml` applies to a Rust project.

Follow them for every choice below. Where they say nothing about a choice you have to make, use the ecosystem's usual default and note which default you picked, so I can correct it.

## 3. Use my tools

Look at the tools in the session-start note, or at the files in `BRAIN/tools/`. Each has a description that says when to use it.

A tool whose description says it helps when a project is started is part of this setup, whatever the job: naming, licensing, repository setup or something else I've registered. Read its file and use it the way the file says. An expert is a session you consult: send it the question and the context its file asks for, and wait for the reply.

Leave tools for other jobs alone. Where no tool covers a step below, do that step yourself.

## 4. Choose a name

Skip this step if I already gave a name.

The name must differ from every name in `BRAIN/projects.md` and from the folders that already exist next to where the project will live. Whoever proposes names needs both lists, plus the purpose and the kind.

- If one of my tools proposes names, use it and show me its candidates.
- Otherwise propose five yourself: lowercase letters, digits and hyphens only, short, and each a different kind of name so I get a real choice.

Let me pick one, ask for more, or type my own. If the project is going into the current folder and that folder already has a name, offer that name too. If I can't be asked, as in a non-interactive run, take the first candidate.

## 5. Scaffold

- Create the project folder if needed, named exactly as chosen.
- If we're in an empty folder whose name differs from the chosen name, scaffold here anyway and use the chosen name inside the project. Don't rename the folder you're running in. Give me the `mv` command for it at the end.
- Use the ecosystem's own init tool (`cargo init`, `bun init`, `npm init -y` and so on) instead of writing manifest files by hand. Then adjust the result to match my preferences.
- Run `git init` if the init tool didn't.
- Write a short `CLAUDE.md`: what the project is for, and the commands to build, test and run it.
- Stop there. The result is an empty project that builds: no features, and no example code beyond what the init tool creates.
- Don't commit unless my preferences say to.

## 6. Record the project

Add a line to `BRAIN/projects.md`. If the file doesn't exist, create it with a `# Projects` heading first.

`- <name>: <purpose in a few words> (<kind>, <YYYY-MM-DD>)`

## 7. Report

Tell me the name, the full path, what was created, which of my tools you used, any defaults you picked because my preferences said nothing, and the command to start working there (`cd <path> && claude`).

If I made choices during this setup that sound like lasting preferences, offer to save them with `/dotfactory:remember`.
