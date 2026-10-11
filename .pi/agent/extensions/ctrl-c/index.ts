import type { ExtensionAPI } from '@earendil-works/pi-coding-agent'
import { isKeyRelease, matchesKey } from '@earendil-works/pi-tui'

export default function (pi: ExtensionAPI) {
  let unsubscribe: (() => void) | undefined

  pi.on('session_start', (_event, ctx) => {
    unsubscribe?.()
    unsubscribe = undefined
    if (ctx.mode !== 'tui') return

    // Run before the editor's clear/exit bindings, even when a dialog has focus.
    unsubscribe = ctx.ui.onTerminalInput((data) => {
      if (isKeyRelease(data) || !matchesKey(data, 'ctrl+c')) return

      if (ctx.isIdle()) {
        ctx.shutdown()
      } else {
        ctx.abort()
      }
      return { consume: true }
    })
  })

  pi.on('session_shutdown', () => {
    unsubscribe?.()
    unsubscribe = undefined
  })
}
