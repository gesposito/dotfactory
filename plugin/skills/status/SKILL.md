---
name: status
description: Show what my dotfactory brain currently holds, namely saved preferences, registered tools and projects, and flag anything that needs fixing. Use when I ask what dotfactory knows, what is set up, or why a preference or tool is not being picked up.
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/status.sh)
---

# dotfactory status

This is the current state of my brain folder:

```!
${CLAUDE_PLUGIN_ROOT}/scripts/status.sh
```

Show me that report as it is, in a code block. Then, only if a line starts with `PROBLEM`, say in one sentence each what to do about it.

If there is no report above, run `${CLAUDE_PLUGIN_ROOT}/scripts/status.sh` yourself and use its output.
