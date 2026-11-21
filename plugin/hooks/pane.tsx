// The dotfactory pane: what the brain gives this session, and a button for each
// /dotfactory: command. /dotfactory opens it. Its data comes from
// scripts/pane-data.sh, so the rules for what applies where live in one place
// (scripts/lib.sh), not here.

import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { Pref, Snapshot } from '../types'

const PANE = 'dotfactory'
const TITLE = 'dotfactory'

// Change the tag when Snapshot's fields change. A stored value outlives a
// reload of this file, and a new tag makes the new code ignore the old value.
const snapshot = atom({ plugin: 'dotfactory', key: 'snapshot' } as const, null, {
  shape: 'snapshot-2',
})

const failed = (why: string): Snapshot => ({
  brain: '',
  prefs: [],
  tools: [],
  projects: [],
  problems: [why],
})

const prefState = (word: string): Pref['state'] => (word === 'loaded' || word === 'skipped' ? word : 'empty')

// Turns the tab-separated records pane-data.sh prints into a Snapshot.
function parse(stdout: string): Snapshot {
  const result: Snapshot = { brain: '', prefs: [], tools: [], projects: [], problems: [] }
  for (const line of stdout.split('\n')) {
    const [kind, a = '', b = '', c = '', d = ''] = line.split('\t')
    if (kind === 'brain') result.brain = a
    if (kind === 'pref') result.prefs.push({ name: a, state: prefState(b), lines: Number(c) || 0 })
    if (kind === 'tool') result.tools.push({ name: a, description: b, isHere: c === 'here', reach: d || 'notes' })
    if (kind === 'project') result.projects.push({ name: a, purpose: b })
    if (kind === 'problem') result.problems.push(a)
  }

  return result
}

// Runs the script and stores what it found. Storing it redraws the pane.
async function refresh($: EngineInterface): Promise<void> {
  let next: Snapshot
  try {
    const script = `${$.plugin.root}/scripts/pane-data.sh`
    const ran = await $.process.run([script, await $.session.root()], { timeoutMs: 10_000 })
    next = ran.exitCode === 0 ? parse(ran.stdout) : failed(`pane-data.sh exited with ${ran.exitCode}. ${ran.stderr.trim()}`)
  } catch (error) {
    next = failed(`pane-data.sh could not run. ${String(error)}`)
  }
  await update($, snapshot, () => next)
}

const count = (n: number, word: string) => `${n} ${word}${n === 1 ? '' : 's'}`

const prefLine = (pref: Pref) => {
  if (pref.state === 'loaded') return `${pref.name}: ${count(pref.lines, 'line')} loaded`
  if (pref.state === 'skipped') return `${pref.name}: not for this folder`

  return `${pref.name}: nothing saved yet`
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: 'dotfactory',
      description: 'Show what my dotfactory brain gives this session, in a pane',
    })

    return next(e)
  })

  // /dotfactory opens the pane and asks for the keyboard, so a digit pressed next
  // goes to a button. Claude Code grants that only over an empty prompt box.
  on('command.run', { command: 'dotfactory' }, async $ => {
    await refresh($)
    const opened = await $.ui.open({ id: PANE, title: TITLE, focus: true })

    return { text: opened.isPlaced ? 'The dotfactory pane is open.' : `The dotfactory pane isn't shown yet: ${opened.reason}` }
  })

  // A turn can change the brain (/dotfactory:remember, /dotfactory:add-tool), so an
  // open pane is brought up to date when each turn ends.
  on('turn.complete', async ($, e, next) => {
    const done = await next(e)
    const panes = await $.ui.panes()
    if (panes.some(pane => pane.id === PANE)) await refresh($)

    return done
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const { Box, Button, Text } = $.ui.resolve(e)
    const data = await read($, snapshot)
    if (!data) return <Text dimColor>Run /dotfactory to load this pane.</Text>

    const loaded = data.prefs.filter(pref => pref.state === 'loaded')
    const isRegisteredTool = data.tools.some(tool => tool.isHere)

    // A button's press: runs the slash command as if I had typed it. The run is
    // queued until the session is idle, so the press doesn't wait for it.
    // Claude Code refuses $.prompt.submit for a text that starts with "/";
    // $.command.run is the call it allows for this.
    // If the command can't be run for me, it goes in the prompt box instead.
    const start = (command: string) => async () => {
      void $.command.run({ command }).catch(async (error: unknown) => {
        const isInPromptBox = await $.prompt.fill({ text: `/${command} ` }).then(
          filled => filled.isFilled,
          () => false,
        )
        $.ui.toast(
          isInPromptBox
            ? `/${command} didn't start (${String(error)}). It's in the prompt box: press Enter to run it.`
            : `/${command} didn't start (${String(error)}). Type it at the prompt.`,
        )
      })

      // The pane holds the keyboard while a button is pressed, but what I type
      // next is for Claude, and typing into the pane would press more buttons.
      // Claude Code has no call that gives the keyboard back to the prompt. A
      // pane that closes does give it back, and opening it again without
      // `focus` leaves it there. If either call fails, Esc still works.
      try {
        await $.ui.close({ id: PANE })
        await $.ui.open({ id: PANE, title: TITLE })
      } catch {
        // The pane stays as it was.
      }
    }

    // The desktop app's small form of a minimized pane: a glance, no lists.
    if (e.props.placement === 'widget') {
      return (
        <Box flexDirection="column">
          <Text>
            {count(loaded.length, 'preference file')}, {count(data.tools.length, 'tool')}
          </Text>
          {data.problems.length > 0 && <Text color="error">{count(data.problems.length, 'problem')}</Text>}
        </Box>
      )
    }

    return (
      <Box flexDirection="column">
        {data.problems.length > 0 && (
          <Box flexDirection="column" marginBottom={1}>
            <Text bold color="error">
              Needs fixing
            </Text>
            {data.problems.map(problem => (
              <Text color="error">{problem}</Text>
            ))}
          </Box>
        )}

        {/* The hotkeys are digits, not letters: a sentence typed into the pane
            by mistake then presses nothing. */}
        <Box flexDirection="column" marginBottom={1}>
          <Text bold>Actions</Text>
          <Button key="new" plain hotkey="1" onPress={start('dotfactory:new')}>
            New project
          </Button>
          <Button key="remember" plain hotkey="2" onPress={start('dotfactory:remember')}>
            Remember a preference
          </Button>
          <Button key="add-tool" plain hotkey="3" onPress={start('dotfactory:add-tool')}>
            {isRegisteredTool ? "Update this project's tool entry" : 'Add this project as a tool'}
          </Button>
          <Button key="status" plain hotkey="4" onPress={start('dotfactory:status')}>
            Status report
          </Button>
          {e.props.isFocused && <Text dimColor>The keyboard is in this pane. Esc returns to the prompt.</Text>}
        </Box>

        <Text bold>Preferences</Text>
        {data.prefs.length === 0 && <Text dimColor>None saved.</Text>}
        {data.prefs.map(pref => (
          <Text dimColor={pref.state !== 'loaded'}>{prefLine(pref)}</Text>
        ))}

        <Box flexDirection="column" marginTop={1}>
          <Text bold>Tools</Text>
          {data.tools.length === 0 && <Text dimColor>None registered.</Text>}
          {data.tools.map(tool => (
            <Box flexDirection="column">
              <Text>{tool.isHere ? `${tool.name} (${tool.reach}, this project)` : `${tool.name} (${tool.reach})`}</Text>
              <Text dimColor>{tool.description}</Text>
            </Box>
          ))}
        </Box>

        <Box flexDirection="column" marginTop={1}>
          <Text bold>Projects</Text>
          {data.projects.length === 0 && <Text dimColor>None recorded.</Text>}
          {data.projects.map(project => (
            <Text>{project.purpose ? `${project.name}: ${project.purpose}` : project.name}</Text>
          ))}
        </Box>

        <Box marginTop={1}>
          <Text dimColor>Brain: {data.brain}</Text>
        </Box>
      </Box>
    )
  })
}
