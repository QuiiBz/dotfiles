import { readFileSync } from 'node:fs'
import type { ExtensionAPI } from '@earendil-works/pi-coding-agent'

// OpenAI Codex's review rubric, adapted for regular-text output; see README.md.
const rubric = readFileSync(new URL('./rubric.md', import.meta.url), 'utf8').trim()
const defaultScope = 'Review the current code changes (staged, unstaged, and untracked files) and provide prioritized findings.'

export default function (pi: ExtensionAPI) {
  pi.registerCommand('review', {
    description: 'Review current changes with Codex’s review prompt; optional extra instructions',
    handler: async (args, ctx) => {
      const extra = args.trim()
      const prompt = `${rubric}\n\n${defaultScope}${extra ? `\n\nAdditional review instructions:\n${extra}` : ''}`

      if (ctx.isIdle()) {
        pi.sendUserMessage(prompt)
      } else {
        pi.sendUserMessage(prompt, { deliverAs: 'followUp' })
      }
    }
  })
}
