// The values the dotfactory pane keeps in the session's state.
// scripts/pane-data.sh produces them; hooks/pane.tsx parses and draws them.

// loaded: applies here and has content. empty: applies here, nothing saved yet.
// skipped: its markers say it isn't for this folder.
export type Pref = { name: string; state: 'loaded' | 'empty' | 'skipped'; lines: number }

// reach: how the tool is used. "repo", "session <name>" or "notes".
export type Tool = { name: string; description: string; isHere: boolean; reach: string }

export type Project = { name: string; purpose: string }

export type Snapshot = {
  brain: string
  prefs: Pref[]
  tools: Tool[]
  projects: Project[]
  problems: string[]
}

declare module 'claude-code' {
  interface PluginState {
    dotfactory: { snapshot: Shaped<Snapshot | null> }
  }
}
