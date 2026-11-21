// Tests for the dotfactory pane. Run with: claude plugin test plugin
//
// Nothing real runs here. Each `on` below stands in for Claude Code itself, so
// the script's output is whatever the test says it is.
//
// Every surface checks a drawing by its own rules, so each state the pane can
// be in is mounted on all four. The one surface-specific view, the desktop
// app's minimized pane, has its own test.

import { expect, test } from 'claude-code/testing'

const SURFACES = ['terminal', 'desktop', 'vscode', 'mobile'] as const

const PANE = {
  plugin: 'dotfactory',
  component: 'Pane',
  requestId: 'dotfactory',
  props: {
    title: 'dotfactory',
    isFocused: false,
    bodyColumns: 40,
    placement: 'dock',
    scroll: { offset: 0, bodyRows: 30 },
    view: {},
  },
} as const

// The person typing /dotfactory at the prompt.
const SLASH_DOTFACTORY = {
  command: 'dotfactory',
  args: '',
  origin: { kind: 'composer' },
  presentation: { isFullscreen: true, columns: 160 },
} as const

// What Claude Code answers when the plugin runs a script.
const scriptOutput = (stdout: string, exitCode = 0, stderr = '') => ({
  value: { exitCode, stdout, stderr, isStdoutTruncated: false, isStderrTruncated: false },
})

// A brain with something in every section, seen from a registered tool's folder.
// It has one tool of each kind: a repo, an expert session and written notes.
const RECORDS = [
  'brain\t/repo/brain',
  'pref\tgeneral\tempty\t0',
  'pref\trust\tloaded\t3',
  'pref\tswift\tskipped\t0',
  'tool\tads\tAds and keyword reports\tother\trepo',
  'tool\tmine\tThe tool this session is in\there\trepo',
  'tool\tnaming\tProposes project names\tother\tsession namer',
  'tool\trelease\tSteps to publish a project\tother\tnotes',
  'project\tatlas\ta mapping tool',
  'project\tbare',
  'problem\tgone points at a folder that does not exist.',
].join('\n')

// A brain with nothing in it yet.
const EMPTY_RECORDS = 'brain\t/repo/brain'

test('the pane shows what the script reports, on every surface', async ($, on) => {
  let argv: readonly string[] = []
  on('ui.open', () => ({ value: { isPlaced: true } }))
  on('session.root', () => ({ value: '/project' }))
  on('process.run', (_, e) => {
    argv = e.argv

    return scriptOutput(RECORDS)
  })

  const ran = await $.command.run(SLASH_DOTFACTORY)
  expect(ran.text).toBe('The dotfactory pane is open.')
  expect(argv[0]?.endsWith('/scripts/pane-data.sh')).toBe(true)
  expect(argv[1]).toBe('/project')

  for (const surface of SURFACES) {
    const ui = await $.ui.mount({ ...PANE, surface })
    const text = async (pattern: RegExp) => (await ui.find({ type: 'Text', text: pattern }))?.text

    expect(await text(/^rust/)).toBe('rust: 3 lines loaded')
    expect(await text(/^general/)).toBe('general: nothing saved yet')
    expect(await text(/^swift/)).toBe('swift: not for this folder')
    expect(await text(/^ads/)).toBe('ads (repo)')
    expect(await text(/keyword/)).toBe('Ads and keyword reports')
    expect(await text(/^mine/)).toBe('mine (repo, this project)')
    expect(await text(/^naming/)).toBe('naming (session namer)')
    expect(await text(/^release/)).toBe('release (notes)')
    expect(await text(/^atlas/)).toBe('atlas: a mapping tool')
    expect(await text(/^bare/)).toBe('bare')
    expect(await text(/^gone/)).toBe('gone points at a folder that does not exist.')
    expect(await text(/^Brain/)).toBe('Brain: /repo/brain')
    await ui.unmount()
  }
})

test('an empty brain says so in each section, on every surface', async ($, on) => {
  on('ui.open', () => ({ value: { isPlaced: true } }))
  on('session.root', () => ({ value: '/project' }))
  on('process.run', () => scriptOutput(EMPTY_RECORDS))
  await $.command.run(SLASH_DOTFACTORY)

  for (const surface of SURFACES) {
    const ui = await $.ui.mount({ ...PANE, surface })
    const text = async (pattern: RegExp) => (await ui.find({ type: 'Text', text: pattern }))?.text

    expect(await text(/saved/)).toBe('None saved.')
    expect(await text(/registered/)).toBe('None registered.')
    expect(await text(/recorded/)).toBe('None recorded.')
    expect(await text(/Needs fixing/)).toBe(undefined)
    await ui.unmount()
  }
})

test('each button runs its slash command, on every surface', async ($, on) => {
  const ran: string[] = []
  on('ui.open', () => ({ value: { isPlaced: true } }))
  on('session.root', () => ({ value: '/project' }))
  on('process.run', () => scriptOutput(RECORDS))
  on('ui.close', () => ({ value: undefined }))
  // /dotfactory itself is answered by the plugin; every other command lands here.
  on('command.run', (_, e) => {
    ran.push(`/${e.command}${e.args}`)

    return { text: '' }
  })
  await $.command.run(SLASH_DOTFACTORY)

  for (const surface of SURFACES) {
    ran.length = 0
    const ui = await $.ui.mount({ ...PANE, surface })
    for (const key of ['new', 'remember', 'add-tool', 'status']) await ui.press({ key })

    expect(ran).toEqual(['/dotfactory:new', '/dotfactory:remember', '/dotfactory:add-tool', '/dotfactory:status'])
    await ui.unmount()
  }
})

test('the tool button says what it will do in this folder, on every surface', async ($, on) => {
  let records = RECORDS
  on('ui.open', () => ({ value: { isPlaced: true } }))
  on('session.root', () => ({ value: '/project' }))
  on('process.run', () => scriptOutput(records))

  // RECORDS has a tool marked "here": this folder is already registered.
  await $.command.run(SLASH_DOTFACTORY)
  for (const surface of SURFACES) {
    const ui = await $.ui.mount({ ...PANE, surface })
    expect((await ui.find({ key: 'add-tool' }))?.text).toBe("Update this project's tool entry")
    await ui.unmount()
  }

  records = EMPTY_RECORDS
  await $.command.run(SLASH_DOTFACTORY)
  for (const surface of SURFACES) {
    const ui = await $.ui.mount({ ...PANE, surface })
    expect((await ui.find({ key: 'add-tool' }))?.text).toBe('Add this project as a tool')
    await ui.unmount()
  }
})

test('a command that cannot be run goes in the prompt box instead, on every surface', async ($, on) => {
  const toasts: string[] = []
  const drafts: string[] = []
  on('ui.open', () => ({ value: { isPlaced: true } }))
  on('session.root', () => ({ value: '/project' }))
  on('process.run', () => scriptOutput(RECORDS))
  on('ui.close', () => ({ value: undefined }))
  on('command.run', () => {
    throw new Error('no such command')
  })
  on('prompt.fill', (_, e) => {
    drafts.push(e.text)

    return { isFilled: true, text: e.text, cursor: e.text.length }
  })
  on('ui.toast', (_, e) => {
    toasts.push(e.text)

    return { value: undefined }
  })
  await $.command.run(SLASH_DOTFACTORY)

  for (const surface of SURFACES) {
    toasts.length = 0
    drafts.length = 0
    const ui = await $.ui.mount({ ...PANE, surface })
    await ui.press({ key: 'status' })

    expect(drafts).toEqual(['/dotfactory:status '])
    expect(toasts.length).toBe(1)
    expect(toasts[0]).toMatch(/^\/dotfactory:status didn't start \(.*\)\. It's in the prompt box: press Enter to run it\.$/)
    await ui.unmount()
  }
})

test('with no prompt box to fill, the toast says to type the command, on every surface', async ($, on) => {
  const toasts: string[] = []
  on('ui.open', () => ({ value: { isPlaced: true } }))
  on('session.root', () => ({ value: '/project' }))
  on('process.run', () => scriptOutput(RECORDS))
  on('ui.close', () => ({ value: undefined }))
  on('command.run', () => {
    throw new Error('no such command')
  })
  // A dialog is open, or the session draws no prompt box.
  on('prompt.fill', () => ({ isFilled: false, refusal: 'dialog', text: '', cursor: 0 }))
  on('ui.toast', (_, e) => {
    toasts.push(e.text)

    return { value: undefined }
  })
  await $.command.run(SLASH_DOTFACTORY)

  for (const surface of SURFACES) {
    toasts.length = 0
    const ui = await $.ui.mount({ ...PANE, surface })
    await ui.press({ key: 'new' })

    expect(toasts.length).toBe(1)
    expect(toasts[0]).toMatch(/^\/dotfactory:new didn't start \(.*\)\. Type it at the prompt\.$/)
    await ui.unmount()
  }
})

test('a script that fails is reported in the pane, on every surface', async ($, on) => {
  on('ui.open', () => ({ value: { isPlaced: true } }))
  on('session.root', () => ({ value: '/project' }))
  on('process.run', () => scriptOutput('', 2, 'boom'))
  await $.command.run(SLASH_DOTFACTORY)

  for (const surface of SURFACES) {
    const ui = await $.ui.mount({ ...PANE, surface })

    expect((await ui.find({ type: 'Text', text: /exited/ }))?.text).toBe('pane-data.sh exited with 2. boom')
    await ui.unmount()
  }
})

test('before /dotfactory has run, the pane says how to load it, on every surface', async $ => {
  for (const surface of SURFACES) {
    const ui = await $.ui.mount({ ...PANE, surface })

    expect((await ui.find({ type: 'Text' }))?.text).toBe('Run /dotfactory to load this pane.')
    expect(await ui.find({ key: 'new' })).toBe(undefined)
    await ui.unmount()
  }
})

test('an open pane is refreshed when a turn ends, on every surface', async ($, on) => {
  let runs = 0
  on('ui.open', () => ({ value: { isPlaced: true } }))
  on('ui.panes', () => ({
    value: [{ id: 'dotfactory', title: 'dotfactory', isShown: true, isFocused: false, isPlaced: true }],
  }))
  on('session.root', () => ({ value: '/project' }))
  on('process.run', () => {
    runs += 1

    return scriptOutput(`pref\tgeneral\tloaded\t${runs}`)
  })
  on('turn.complete', () => ({ text: 'done' }))

  await $.command.run(SLASH_DOTFACTORY)
  await $.turn.complete({ answer: 'done', durationMs: 1, isAborted: false, turnId: 'turn-1', reason: 'answer' })

  for (const surface of SURFACES) {
    const ui = await $.ui.mount({ ...PANE, surface })
    expect((await ui.find({ type: 'Text', text: /^general/ }))?.text).toBe('general: 2 lines loaded')
    await ui.unmount()
  }
})

test('a closed pane costs nothing when a turn ends', async ($, on) => {
  let runs = 0
  on('ui.panes', () => ({ value: [] }))
  on('process.run', () => {
    runs += 1

    return scriptOutput('')
  })
  on('turn.complete', () => ({ text: 'done' }))

  await $.turn.complete({ answer: 'done', durationMs: 1, isAborted: false, turnId: 'turn-1', reason: 'answer' })
  expect(runs).toBe(0)
})

// What I type after pressing a button is meant for Claude. Claude Code has no
// call to move the keyboard to the prompt, so the pane closes and reopens
// without asking for it.
test('/dotfactory takes the keyboard and a button press gives it back, on every surface', async ($, on) => {
  const calls: string[] = []
  on('ui.open', (_, e) => {
    calls.push(e.focus ? 'open with the keyboard' : 'open without the keyboard')

    return { value: { isPlaced: true } }
  })
  on('ui.close', (_, e) => {
    calls.push(`close ${e.id}`)

    return { value: undefined }
  })
  on('session.root', () => ({ value: '/project' }))
  on('process.run', () => scriptOutput(RECORDS))
  on('command.run', () => ({ text: '' }))

  await $.command.run(SLASH_DOTFACTORY)
  expect(calls).toEqual(['open with the keyboard'])

  for (const surface of SURFACES) {
    calls.length = 0
    const ui = await $.ui.mount({ ...PANE, surface })
    await ui.press({ key: 'remember' })

    expect(calls).toEqual(['close dotfactory', 'open without the keyboard'])
    await ui.unmount()
  }
})

test('a pane holding the keyboard says how to give it back, on every surface', async ($, on) => {
  on('ui.open', () => ({ value: { isPlaced: true } }))
  on('session.root', () => ({ value: '/project' }))
  on('process.run', () => scriptOutput(RECORDS))
  await $.command.run(SLASH_DOTFACTORY)

  for (const surface of SURFACES) {
    let ui = await $.ui.mount({ ...PANE, surface, props: { ...PANE.props, isFocused: true } })
    expect((await ui.find({ type: 'Text', text: /Esc/ }))?.text).toBe(
      'The keyboard is in this pane. Esc returns to the prompt.',
    )
    await ui.unmount()

    ui = await $.ui.mount({ ...PANE, surface })
    expect(await ui.find({ type: 'Text', text: /Esc/ })).toBe(undefined)
    await ui.unmount()
  }
})

// The desktop app can minimize a pane to a small widget, where clicks may not
// reach it. Only that surface has this seat.
test('minimized on the desktop app, the pane is a glance with no buttons', async ($, on) => {
  let records = RECORDS
  on('ui.open', () => ({ value: { isPlaced: true } }))
  on('session.root', () => ({ value: '/project' }))
  on('process.run', () => scriptOutput(records))
  const WIDGET = {
    ...PANE,
    surface: 'desktop',
    props: { ...PANE.props, placement: 'widget', anchoredEdges: ['bottom', 'right'] },
  } as const

  await $.command.run(SLASH_DOTFACTORY)
  let ui = await $.ui.mount(WIDGET)
  expect((await ui.find({ type: 'Text', text: /preference/ }))?.text).toBe('1 preference file, 4 tools')
  expect((await ui.find({ type: 'Text', text: /problem/ }))?.text).toBe('1 problem')
  expect(await ui.find({ key: 'new' })).toBe(undefined)
  expect(await ui.find({ type: 'Text', text: /^Projects$/ })).toBe(undefined)
  await ui.unmount()

  // With nothing wrong, the problem line is left out.
  records = EMPTY_RECORDS
  await $.command.run(SLASH_DOTFACTORY)
  ui = await $.ui.mount(WIDGET)
  expect((await ui.find({ type: 'Text', text: /preference/ }))?.text).toBe('0 preference files, 0 tools')
  expect(await ui.find({ type: 'Text', text: /problem/ })).toBe(undefined)
  await ui.unmount()
})

// The terminal seats a pane beside the transcript in its fullscreen layout,
// and above the prompt on its main screen. Both get the full view.
test('above the prompt on the terminal, the pane is still the full view', async ($, on) => {
  on('ui.open', () => ({ value: { isPlaced: true } }))
  on('session.root', () => ({ value: '/project' }))
  on('process.run', () => scriptOutput(RECORDS))
  await $.command.run(SLASH_DOTFACTORY)

  const ui = await $.ui.mount({ ...PANE, surface: 'terminal', props: { ...PANE.props, placement: 'inline' } })
  expect((await ui.find({ key: 'status' }))?.text).toBe('Status report')
  expect((await ui.find({ type: 'Text', text: /^rust/ }))?.text).toBe('rust: 3 lines loaded')
  await ui.unmount()
})
