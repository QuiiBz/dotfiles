import { CustomEditor, type ExtensionAPI, type KeybindingsManager, type Theme } from '@earendil-works/pi-coding-agent'
import type { EditorTheme, TUI } from '@earendil-works/pi-tui'

class GrayInputEditor extends CustomEditor {
  constructor(tui: TUI, editorTheme: EditorTheme, keybindings: KeybindingsManager,
    private readonly palette: () => Theme) {
    super(tui, editorTheme, keybindings, { paddingX: 1 })
  }

  // Keep the existing row geometry for mouse hit-testing and autocomplete.
  // Border rows become blank padding, like the user message box.
  protected renderTopBorder(): string { return '' }
  protected renderBottomBorder(): string { return '' }

  render(width: number): string[] {
    if (width <= 0) return []
    const lines = super.render(width)
    // The body is padded to full width, so only the border placeholders are ''.
    const bottom = lines.indexOf('', 1)
    const theme = this.palette()
    const colors = theme.getFgAnsi('userMessageText') + theme.getBgAnsi('userMessageBg')
    return lines.map((line, index) => {
      // Preserve the autocomplete menu's own styling below the input panel.
      if (index > bottom) return line
      const content = line || ' '.repeat(width)
      // The fake cursor closes with SGR 0; restore the panel colors afterward,
      // otherwise the rest of its row would revert to the terminal background.
      const styled = content.replace(/\x1b\[(?:0)?m/g, reset => reset + colors)
      return theme.style(styled, { fg: 'userMessageText', bg: 'userMessageBg' })
    })
  }
}

export default function (pi: ExtensionAPI) {
  let restore: (() => void) | undefined
  pi.on('session_start', (_event, ctx) => {
    if (ctx.mode !== 'tui') return
    ctx.ui.setEditorComponent((tui, theme, keybindings) =>
      new GrayInputEditor(tui, theme, keybindings, () => ctx.ui.theme))
    restore = () => ctx.ui.setEditorComponent(undefined)
  })
  pi.on('session_shutdown', () => {
    restore?.()
    restore = undefined
  })
}
