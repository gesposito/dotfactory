# dotfactory

A Claude Code plugin (`plugin/`). See `README.md` for what each part does.

- **The plugin stays generic.** It must not name a language, a tool, a product, a person or a path on someone's machine. Anything of that kind belongs in a brain file, which is data. The only exceptions are the author, owner and copyright lines. This repository is meant to be public.
- **The brain is not part of this repository.** `brain/` is ignored here and is a git repository of its own. It is the user's data: change it only through the `/dotfactory:*` skills or when asked. Never copy its content into `plugin/`, `tests/` or the README.
- After changing anything in `plugin/`, run `sh tests/hook.test.sh`, `claude plugin test plugin` and `claude plugin validate plugin`. The last one also type-checks `hooks/pane.tsx` and its test.
- `plugin/scripts/session-start.sh` must always exit 0 and print under 10,000 characters. Claude Code discards a failing hook's output and cuts anything longer.
- The scripts are POSIX `sh` and must run on macOS's `/bin/sh`. No bash-only syntax, no `jq`.
- `plugin/hooks/pane.tsx` only draws. It gets its data from `plugin/scripts/pane-data.sh`, so change what the pane shows in the script and in `plugin/types/index.d.ts`, and keep the records the two agree on in step.
- Skill files are instructions for another Claude session with no context from this one. Write them to stand alone.
