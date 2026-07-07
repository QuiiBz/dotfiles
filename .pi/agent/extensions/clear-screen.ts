import type { ExtensionAPI } from '@earendil-works/pi-coding-agent'

export default function (pi: ExtensionAPI) {
  pi.registerShortcut("ctrl+l", {
    description: "Clear screen",
    handler: async ctx => {
      if (!ctx.hasUI) return

      await ctx.ui.custom<void>((tui, _theme, _keybindings, done) => {
        const chatContainer = tui.children?.[1]
        if (chatContainer && 'clear' in chatContainer && typeof chatContainer.clear === 'function') {
          chatContainer.clear()
        }

        tui.requestRender(true)
        done()
        return { render: () => [], invalidate: () => {} }
      })
    }
  })
}
