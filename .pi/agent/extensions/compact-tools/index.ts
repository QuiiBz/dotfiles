import { homedir } from 'node:os'
import { stripVTControlCharacters } from 'node:util'
import { ToolExecutionComponent, UserMessageComponent, type ExtensionAPI, type ToolRenderers } from '@earendil-works/pi-coding-agent'
import { truncateToWidth, visibleWidth, wrapTextWithAnsi } from '@earendil-works/pi-tui'

// Symbol.for keeps already-rendered rows recognizable across /reload.
const ROW = Symbol.for('dotfiles.pi.compact-tools.row')
interface RowState { error?: string }

function stripControls(text: string): string {
  // Remove OSC explicitly: Bun's stripVTControlCharacters can misparse titles.
  return stripVTControlCharacters(text.replace(/(?:\x1b\]|\u009d)[\s\S]*?(?:\x07|\x1b\\|\u009c|$)/g, ''))
}

function oneLine(value: unknown): string {
  return stripControls(String(value ?? '').slice(0, 2000))
    .replace(/[\u0000-\u001f\u007f-\u009f]/g, ' ')
    .replace(/\s+/g, ' ').trim()
}

function shortPath(value: unknown, cwd: string): string {
  const path = oneLine(value)
  const root = cwd.replace(/\/$/, '')
  const home = homedir()
  if (path === root) return '.'
  if (path.startsWith(`${root}/`)) return path.slice(root.length + 1)
  if (path === home) return '~'
  if (path.startsWith(`${home}/`)) return `~${path.slice(home.length)}`
  return path
}

function summarize(args: Record<string, unknown>, cwd: string): string {
  if (typeof args.command === 'string') return oneLine(args.command)
  if (typeof args.path === 'string') {
    let path = shortPath(args.path, cwd)
    if (typeof args.offset === 'number' || typeof args.limit === 'number') {
      const start = typeof args.offset === 'number' ? args.offset : 1
      path += `:${start}${typeof args.limit === 'number' ? `–${start + args.limit - 1}` : ''}`
    }
    if (typeof args.pattern === 'string') path += ` · ${oneLine(args.pattern)}`
    if (Array.isArray(args.edits)) path += ` · ${args.edits.length} edits`
    if (typeof args.content === 'string') path += ` · ${args.content.split('\n').length} lines`
    return path
  }
  if (Array.isArray(args.questions)) {
    return oneLine(args.questions[0]?.question)
  }
  const keys = ['action', 'subject', 'query', 'pattern', 'url', 'name', 'id']
  const values = keys.filter(key => args[key] != null).slice(0, 2)
    .map(key => oneLine(args[key]))
  // Unknown tools still get a useful hint, without dumping JSON or large payloads.
  return values.length ? values.join(' · ') : Object.keys(args).slice(0, 3).join(' · ')
}

function renderers(toolName: string): ToolRenderers {
  return {
    renderShell: 'self',
    renderCall(args, theme, context) {
      const state: RowState = context.state[ROW] ??= {}
      const params = args && typeof args === 'object' ? args as Record<string, unknown> : {}
      const summary = summarize(params, context.cwd)
      const name = oneLine(toolName.replace(/^(functions|multi_tool_use)\./, ''))
      return {
        invalidate() {},
        render(width: number): string[] {
          if (width <= 0) return []
          const icon = context.isError ? '×'
            : !context.isPartial ? '✓'
            : context.executionStarted ? '◌' : '·'
          const title = `${theme.fg('muted', icon)} ${theme.fg('text', theme.bold(name))}`
          const duration = context.durationMs == null ? ''
            : context.durationMs < 1000 ? `${Math.round(context.durationMs)}ms`
            : `${(context.durationMs / 1000).toFixed(1)}s`
          const tail = state.error ? theme.fg('text', ` · ${state.error}`)
            : duration ? theme.fg('dim', ` · ${duration}`) : ''
          // Reserve room for the failure hint, even with a very long command/path.
          const suffix = truncateToWidth(tail, Math.max(0, Math.floor(width * 0.4)))
          const body = summary ? `${title} ${theme.fg('muted', summary)}` : title
          return [truncateToWidth(body, Math.max(0, width - visibleWidth(suffix))) + suffix]
        },
      }
    },
    renderResult(result, { expanded }, theme, context) {
      const state: RowState = context.state[ROW] ??= {}
      const text = result.content.filter(block => block.type === 'text')
        .map(block => block.text).join('\n')
      state.error = context.isError ? oneLine(text) || 'failed' : undefined
      if (!expanded) return { invalidate() {}, render: () => [] }

      // Keep expanded results borderless too. Include edit diffs when available.
      const details = result.details as { diff?: string } | undefined
      const output = !context.isError && typeof details?.diff === 'string' ? details.diff : text
      const clean = stripControls(output)
        .replace(/[\u0000-\u0008\u000b-\u001f\u007f-\u009f]/g, '')
      return {
        invalidate() {},
        render(width: number): string[] {
          if (!clean || width <= 0) return []
          return clean.split('\n').flatMap(line =>
            wrapTextWithAnsi(theme.fg('text', line), width))
        },
      }
    },
  }
}

// Pi 1.1 adds a blank line even for renderShell: 'self'. There is no public
// spacing hook, so narrowly adapt tagged tool rows and add one blank line below
// user message boxes. Restore both on shutdown/reload.
function applyTranscriptSpacing(): () => void {
  const prototype = ToolExecutionComponent.prototype
  const originalRender = prototype.render
  const originalMouse = prototype.handleMouse
  const userPrototype = UserMessageComponent.prototype
  const originalUserRender = userPrototype.render
  function spacedUserRender(this: UserMessageComponent, width: number): string[] {
    const lines = originalUserRender.call(this, width)
    return lines.length ? [...lines, ''] : lines
  }
  type Internals = { rendererState: { [ROW]?: RowState }; expanded: boolean }
  function compactRender(this: ToolExecutionComponent, width: number): string[] {
    const lines = originalRender.call(this, width)
    const row = this as unknown as Internals
    if (!row.rendererState?.[ROW]) return lines
    const start = lines[0] === '' ? 1 : 0
    // Inline images belong to the expanded view, never the one-line summary.
    return row.expanded ? lines.slice(start) : lines.slice(start, start + 1)
  }
  const compactMouse: typeof originalMouse = function (this: ToolExecutionComponent, event) {
    const row = this as unknown as Internals
    return originalMouse.call(this, row.rendererState?.[ROW] ? { ...event, y: event.y + 1 } : event)
  }
  prototype.render = compactRender
  prototype.handleMouse = compactMouse
  userPrototype.render = spacedUserRender
  return () => {
    if (prototype.render === compactRender) prototype.render = originalRender
    if (prototype.handleMouse === compactMouse) prototype.handleMouse = originalMouse
    if (userPrototype.render === spacedUserRender) userPrototype.render = originalUserRender
  }
}

export default function (pi: ExtensionAPI) {
  // Renderer-only override: execution, schemas and model-facing results stay intact.
  pi.registerToolRenderer(toolName => renderers(toolName))
  let restore: (() => void) | undefined
  pi.on('session_start', (_event, ctx) => {
    if (ctx.mode === 'tui' && !restore) restore = applyTranscriptSpacing()
  })
  pi.on('session_shutdown', () => {
    restore?.()
    restore = undefined
  })
}
