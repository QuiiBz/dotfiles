import type { ExtensionAPI } from '@earendil-works/pi-coding-agent'
import { truncateToWidth, visibleWidth } from '@earendil-works/pi-tui'

// Match Codex's compact token counts (e.g. 1.23K, 12.3K, 123K).
function formatTokens(value: number): string {
  value = Math.max(0, value)
  if (value < 1000) return String(value)

  const [scale, suffix] = value >= 1e12 ? [1e12, 'T']
    : value >= 1e9 ? [1e9, 'B']
    : value >= 1e6 ? [1e6, 'M']
    : [1e3, 'K']
  const scaled = value / scale
  const decimals = scaled < 10 ? 2 : scaled < 100 ? 1 : 0
  return `${Number(scaled.toFixed(decimals))}${suffix}`
}

export default function (pi: ExtensionAPI) {
  let responseStartedAt: number | undefined
  let tokensPerSecond: number | undefined
  let requestRender: (() => void) | undefined

  pi.on('message_start', (event, ctx) => {
    if (ctx.mode !== 'tui' || event.message.role !== 'assistant') return
    responseStartedAt = performance.now()
  })

  pi.on('message_end', (event, ctx) => {
    if (ctx.mode !== 'tui' || event.message.role !== 'assistant') return
    const startedAt = responseStartedAt
    responseStartedAt = undefined
    if (startedAt === undefined) return

    // Output tokens / response wall time, including initial latency and reasoning,
    // but excluding tool execution and time between responses.
    const seconds = (performance.now() - startedAt) / 1000
    const output = event.message.usage.output
    if (seconds > 0 && output > 0) {
      tokensPerSecond = output / seconds
      requestRender?.()
    }
  })

  pi.on('session_switch', () => {
    responseStartedAt = undefined
    tokensPerSecond = undefined
    requestRender?.()
  })

  pi.on('session_start', (_event, ctx) => {
    responseStartedAt = undefined
    tokensPerSecond = undefined
    if (ctx.mode !== 'tui') return

    ctx.ui.setFooter((tui, theme) => {
      requestRender = () => tui.requestRender()
      return {
        dispose() { requestRender = undefined },
        invalidate() {},
        render(width: number): string[] {
          if (width < 2) return [' '.repeat(Math.max(0, width))]
          width -= 2 // Reserve one column at each edge.

          let input = 0
          let output = 0
          let uncachedInput = 0

          // Keep cumulative totals across compactions, like Pi's default footer.
          for (const entry of ctx.sessionManager.getEntries()) {
            if (entry.type !== 'message' || entry.message.role !== 'assistant') continue
            const usage = entry.message.usage
            // Pi separates cached input; Codex's input total includes it.
            input += usage.input + usage.cacheRead + usage.cacheWrite
            uncachedInput += usage.input + usage.cacheWrite
            output += usage.output
          }

          const parts: string[] = []
          const context = ctx.getContextUsage()
          if (context?.percent != null) {
            const remaining = Math.round(Math.max(0, Math.min(100, 100 - context.percent)))
            parts.push(`Context ${remaining}% left`)
          }

          // Codex's "used" count excludes cache reads.
          const used = uncachedInput + output
          if (used > 0) parts.push(`${formatTokens(used)} used`)
          parts.push(`${formatTokens(input)} in`, `${formatTokens(output)} out`)

          const model = ctx.model
          const reasoning = model?.reasoning ? pi.getThinkingLevel() : 'off'
          parts.push(`${model?.id ?? 'no-model'} ${reasoning}`)

          if (tokensPerSecond === undefined) {
            const content = truncateToWidth(parts.join(' · '), width, '...', true)
            return [theme.fg('dim', ` ${content} `)]
          }

          const right = truncateToWidth(`${tokensPerSecond.toFixed(1)} TPS`, width)
          const left = truncateToWidth(parts.join(' · '), Math.max(0, width - visibleWidth(right) - 2))
          const padding = ' '.repeat(Math.max(0, width - visibleWidth(left) - visibleWidth(right)))
          return [theme.fg('dim', ` ${left}${padding}${right} `)]
        },
      }
    })
  })
}
