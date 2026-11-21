---
name: add-tool
description: Register a tool in my shared brain so sessions in every project know it exists and when to use it. A tool is a repo to run, an expert (another Claude Code session to consult), or written notes for a job. Use when I say a repo, a session or a procedure should be available to my other projects, or ask to add, register or update a tool or an expert.
argument-hint: "[a folder path | session <name> | what the notes cover]"
---

# Register a tool

A tool is anything my sessions can call on for a job. Your task is to write one tool's entry into my brain folder.

My brain folder is the one the session-start note names ("The user's shared brain folder is …"). If that note isn't in this conversation, run `${CLAUDE_PLUGIN_ROOT}/scripts/brain-path.sh` to print it. It's called BRAIN below.

## The three kinds of tool

| Kind | What it is | How a session uses it |
|---|---|---|
| Repo | Code in a folder | Runs its commands |
| Expert | Another Claude Code session of mine, with its own knowledge and context | Messages it by name with a question, and waits for the reply |
| Notes | Steps written in the entry itself | Follows them |

What I said decides the kind:

- A folder path means a repo.
- `session <name>` means an expert.
- A description of steps means notes.
- Nothing at all means the current project, as a repo.

If it's unclear, ask me.

## How the entry gets used

- At the start of every session, a hook prints one line per tool: its name, its kind and its `description`. That line decides whether a session reaches for the tool at all.
- A session that wants the tool then reads the rest of the file. The body has to be enough to use the tool without asking me.

## Steps

1. Learn what the tool does.
   - **Repo:** read its README, its manifest and its entry points. Only read. Don't run it, because tools can cost money or change things. Don't open files that hold secrets, such as `.env` files or a `secrets/` folder. `.env.example` is fine and is the place to learn variable names.
   - **Expert:** ask me what it knows and what it needs to be sent. If I say so, you may instead send that session one message asking it to describe both.
   - **Notes:** use what I told you, and ask for any step that's missing.
2. Write `BRAIN/tools/<name>.md` in the shape below. If the file already exists, update it instead of starting over.
3. Show me the `description` line and ask whether it's right.

## Shape of the file

Each line between the two `---` lines must stay on one line, because the hook reads them line by line. Leave out `session:` and `path:` when they don't apply.

```markdown
---
name: <a short name for the job, or the repo's folder name>
description: <at most 200 characters: what it does and when to reach for it>
session: <the session's name, for an expert>
path: <absolute path of the repo, or of the folder an expert runs in>
---

## What it does

Two or three sentences.

## How to use it

Repo: the exact commands, written to work from another project's folder. Say which only read, and which cost money or change things.
Expert: what to send it, including the context it needs, and what comes back.
Notes: the steps.

## Needs

Runtime, the names of credentials or environment variables, and other repos it depends on. Leave this section out if there's nothing.

## If it isn't available

For an expert: how I start its session, and what to do meanwhile. Leave this section out for the other kinds.
```

Never copy the value of a credential into this file, only its name.
