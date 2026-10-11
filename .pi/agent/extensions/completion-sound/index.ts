import type { ExtensionAPI } from '@earendil-works/pi-coding-agent'

export default function (pi: ExtensionAPI) {
  // Wait through tool calls, retries, compaction, and queued follow-ups.
  pi.on('agent_settled', (event, ctx) => {
    if (process.platform !== 'darwin' || ctx.mode !== 'tui' || event.aborted) return

    // Match Codex's completion sound without blocking the next input.
    void pi.exec('/usr/bin/afplay', ['/System/Library/Sounds/Submarine.aiff'], {
      timeout: 5000,
    }).catch(() => {
      // Audio failures must not interrupt the session.
    })
  })
}
