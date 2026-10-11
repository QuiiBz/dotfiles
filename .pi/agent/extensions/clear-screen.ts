import type { ExtensionAPI, ExtensionContext } from '@earendil-works/pi-coding-agent'

export default function (pi: ExtensionAPI) {
  const clearScreen = async (ctx: ExtensionContext) => {
    if (!ctx.hasUI) return

    await ctx.ui.custom<void>((tui, _theme, _keybindings, done) => {
      // Pi 1.x groups header, loaded resources, and chat in the first child.
      // Older versions put those three containers directly under the TUI.
      const firstChild = tui.children[0]
      const chatContainer = firstChild && 'children' in firstChild
        && Array.isArray(firstChild.children) && firstChild.children.length === 3
        ? firstChild.children[2]
        : tui.children[2]

      if (!chatContainer || !('clear' in chatContainer) || typeof chatContainer.clear !== 'function') {
        throw new Error('Cannot find the chat container in this Pi version')
      }

      // Clear only rendered messages; session history and model context stay intact.
      chatContainer.clear()
      tui.invalidate()
      tui.requestRender(true)
      done()
      return { render: () => [], invalidate: () => {} }
    })
  }

  pi.registerShortcut("ctrl+l", {
    description: "Clear screen",
    handler: clearScreen
  })

  pi.registerCommand("clear", {
    description: "Clear screen without resetting the conversation",
    handler: async (_args, ctx) => clearScreen(ctx)
  })
}
