local terminal_creator = "com.superlogical.terminal"
local window_history = {}
local session_history = {}
local pane_history = {}

local function checked(result, failure)
  if result == nil then
    error(failure or "Rex returned no result", 0)
  end
  return result
end

local function observe(history, current)
  if history.current ~= current then
    history.previous = history.current
    history.current = current
  end
end

local function context_state(context)
  local view = checked(rex.session.view({}))
  local selected_window
  for _, window in ipairs(view.windows or {}) do
    for _, layer in ipairs(window.layers or {}) do
      for _, block in ipairs(layer.blocks or {}) do
        if block.block_id == context.block_id then
          selected_window = window
        end
      end
    end
  end
  if not selected_window then
    for _, window in ipairs(view.windows or {}) do
      if window.window_id == view.active_window_id then
        selected_window = window
        break
      end
    end
  end
  if not selected_window then
    error("The session has no active window", 0)
  end
  local client_key = context.client_id or "cli"
  session_history[client_key] = session_history[client_key] or {}
  observe(session_history[client_key], context.session_id)
  window_history[context.session_id] = window_history[context.session_id] or {}
  observe(window_history[context.session_id], selected_window.window_id)
  pane_history[selected_window.window_id] = pane_history[selected_window.window_id] or {}
  observe(pane_history[selected_window.window_id], context.block_id or selected_window.focused_block_id)
  return view, selected_window
end

local function shell_layout(context)
  local process = rex.block.call(terminal_creator, "process", { block_id = context.block_id })
  local directory = process and process.foreground and process.foreground.cwd
  directory = directory or (process and process.child and process.child.cwd)
  if not directory then
    error("Cannot read the current pane directory", 0)
  end
  return rex.layout.block({
    flavor = terminal_creator .. ".shell",
    options = { cwd = directory },
  })
end

rex.action({
  name = "tmux_window",
  title = "tmux: Change Window",
  args = { operation = "string", index = "integer?" },
  run = function(context, arguments)
    local view = context_state(context)
    local history = window_history[context.session_id]
    if arguments.operation == "new" then
      rex.client.queue("client.tab.new")
    elseif arguments.operation == "next" then
      rex.client.queue("client.tab.next")
    elseif arguments.operation == "previous" then
      rex.client.queue("client.tab.previous")
    else
      local target = history.previous
      if arguments.operation == "goto" then
        local window = (view.windows or {})[arguments.index]
        target = window and window.window_id
      end
      if not target then
        error("No matching window is recorded", 0)
      end
      for index, window in ipairs(view.windows or {}) do
        if window.window_id == target then
          rex.client.queue("client.tab.goto", { index = index })
          return
        end
      end
      error("The recorded window no longer exists", 0)
    end
  end,
})

rex.action({
  name = "tmux_session",
  title = "tmux: Change Session",
  args = { operation = "string" },
  run = function(context, arguments)
    context_state(context)
    if arguments.operation == "choose" then
      rex.client.queue("session.switch")
      return
    end
    local sessions = checked(rex.call("session.list", {})).sessions or {}
    local target = session_history[context.client_id or "cli"].previous
    if arguments.operation ~= "last" then
      for index, session in ipairs(sessions) do
        if session.session_id == context.session_id then
          local step = arguments.operation == "next" and 1 or -1
          target = sessions[(index - 1 + step) % #sessions + 1].session_id
          break
        end
      end
    end
    if not target then
      error("No previous session is recorded", 0)
    end
    rex.client.queue("session.select", { session_id = target })
  end,
})

rex.action({
  name = "tmux_pane",
  title = "tmux: Change Pane",
  args = { operation = "string" },
  run = function(context, arguments)
    local _, window = context_state(context)
    if arguments.operation == "last" then
      local target = pane_history[window.window_id].previous
      if not target then
        error("No previous pane is recorded", 0)
      end
      checked(rex.session.focus_block({ block_id = target }))
    elseif arguments.operation == "next" then
      checked(rex.session.focus_next_pane({ wrap = true }))
    else
      checked(rex.session.focus_previous_pane({ wrap = true }))
    end
    context_state(context)
  end,
})

rex.action({
  name = "tmux_split",
  title = "tmux: Split Pane in Current Directory",
  args = { direction = "string" },
  run = function(context, arguments)
    context_state(context)
    rex.client.queue("pane.split", {
      direction = arguments.direction == "horizontal" and "right" or "down",
    })
  end,
})

rex.action({
  name = "tmux_float",
  title = "tmux: Open Centered Floating Pane",
  run = function(context)
    context_state(context)
    checked(rex.session.new_layer({
      bounds = { 0.3, 0.3, 0.4, 0.4 },
      layout = shell_layout(context),
      focus = true,
    }))
    context_state(context)
  end,
})

local function find_split(node, block_id, direction, candidates)
  if not node then
    return nil
  end
  if node.block_id == block_id then
    return node
  end
  if not node.split then
    return nil
  end
  local leaf = find_split(node.split.before, block_id, direction, candidates)
    or find_split(node.split.after, block_id, direction, candidates)
  if leaf and node.split.direction == direction then
    candidates[#candidates + 1] = node
  end
  return leaf
end

local function first_block(node)
  return node.block_id or first_block(node.split.before)
end

rex.action({
  name = "tmux_resize",
  title = "tmux: Resize Pane by Cells",
  args = { direction = "string", amount = "integer" },
  repeats = true,
  run = function(context, arguments)
    local _, window = context_state(context)
    local horizontal = arguments.direction == "left" or arguments.direction == "right"
    local direction = horizontal and "horizontal" or "vertical"
    local dimension = horizontal and 3 or 4
    local size = checked(rex.block.call(terminal_creator, "size", { block_id = context.block_id }))
    local cells = horizontal and size.columns or size.rows
    if cells < 1 then
      error("The terminal has no size", 0)
    end
    local sign = (arguments.direction == "left" or arguments.direction == "up") and -1 or 1
    for _, layer in ipairs(window.layers or {}) do
      local candidates = {}
      local leaf = find_split(layer.layout, context.block_id, direction, candidates)
      if leaf then
        local split_node = candidates[1]
        if split_node then
          local cell_fraction = leaf.rect[dimension] / cells / split_node.rect[dimension]
          local ratio = split_node.split.ratio + sign * arguments.amount * cell_fraction
          checked(rex.session.resize_pane({
            direction = direction,
            before_block_id = first_block(split_node.split.before),
            after_block_id = first_block(split_node.split.after),
            ratio = math.max(cell_fraction, math.min(1 - cell_fraction, ratio)),
          }))
        elseif layer.kind == "floating" then
          local bounds = { unpack(layer.bounds) }
          local cell_fraction = bounds[dimension] / cells
          local delta = arguments.amount * cell_fraction
          local position = dimension - 2
          if sign < 0 then
            delta = math.min(delta, bounds[position])
            bounds[position] = bounds[position] - delta
          else
            delta = math.min(delta, 1 - bounds[position] - bounds[dimension])
          end
          bounds[dimension] = bounds[dimension] + delta
          checked(rex.session.resize_layer({ layer_id = layer.layer_id, bounds = bounds }))
        end
        return
      end
    end
  end,
})

rex.action({
  name = "tmux_swap",
  title = "tmux: Swap Pane",
  args = { step = "integer" },
  run = function(context, arguments)
    local _, window = context_state(context)
    local blocks = window.layers[1].blocks or {}
    for index, block in ipairs(blocks) do
      if block.block_id == context.block_id then
        local target = blocks[(index - 1 + arguments.step) % #blocks + 1].block_id
        if target ~= context.block_id then
          checked(rex.session.swap_blocks({ block_id = context.block_id, other_block_id = target }))
        end
        return
      end
    end
    error("Cannot swap a floating pane up or down", 0)
  end,
})

rex.action({
  name = "tmux_rotate",
  title = "tmux: Rotate Panes",
  args = { step = "integer" },
  run = function(context, arguments)
    local _, window = context_state(context)
    local blocks = {}
    local focused_index
    for _, layer in ipairs(window.layers or {}) do
      for _, block in ipairs(layer.blocks or {}) do
        blocks[#blocks + 1] = block.block_id
        if block.block_id == context.block_id then
          focused_index = #blocks
        end
      end
    end
    if #blocks < 2 or not focused_index then
      return
    end
    local index = arguments.step == 1 and #blocks or 1
    local pivot = blocks[index]
    local step = -arguments.step
    for target = index + step, arguments.step == 1 and 1 or #blocks, step do
      checked(rex.session.swap_blocks({ block_id = pivot, other_block_id = blocks[target] }))
    end
    checked(rex.session.focus_block({ block_id = blocks[(focused_index - 1 - arguments.step) % #blocks + 1] }))
    context_state(context)
  end,
})

rex.action({
  name = "tmux_move",
  title = "tmux: Position Floating Pane",
  args = { x = "number", y = "number", width = "number?", height = "number?" },
  run = function(context, arguments)
    local _, window = context_state(context)
    for _, layer in ipairs(window.layers or {}) do
      for _, block in ipairs(layer.blocks or {}) do
        if block.block_id == context.block_id then
          if layer.kind ~= "floating" then
            error("The current pane is not floating", 0)
          end
          local width = arguments.width or layer.bounds[3]
          local height = arguments.height or layer.bounds[4]
          checked(rex.session.resize_layer({
            layer_id = layer.layer_id,
            bounds = { arguments.x * (1 - width), arguments.y * (1 - height), width, height },
          }))
          return
        end
      end
    end
  end,
})

local function bind(key, action, arguments)
  rex.bind("ctrl+a>" .. key, action, arguments)
end

-- Use physical keys for French-PC symbols that Rex cannot name as characters.
local character_keys = {
  ['"'] = "[Digit3]", ["%"] = "shift+[Quote]", ["*"] = "[Backslash]",
  ["("] = "[Digit5]", [")"] = "[Minus]", ["$"] = "[BracketRight]",
  ["&"] = "[Digit1]", ["!"] = "[Slash]", ["@"] = "alt+[Digit0]",
  ["{"] = "alt+[Digit4]", ["}"] = "alt+[Equal]", [":"] = "[Period]",
  ["?"] = "shift+[KeyM]", ["1"] = "shift+[Digit1]", ["2"] = "shift+[Digit2]",
  ["3"] = "shift+[Digit3]", ["4"] = "shift+[Digit4]", ["5"] = "shift+[Digit5]",
  ["6"] = "shift+[Digit6]", ["7"] = "shift+[Digit7]", ["8"] = "shift+[Digit8]",
  ["9"] = "shift+[Digit9]", ["0"] = "shift+[Digit0]",
}

local function bind_character(character, action, arguments)
  bind(character_keys[character] or character, action, arguments)
end

bind("a", "pane.send_key", { key = "ctrl+a" })
bind("ctrl+b", "pane.send_key", { key = "ctrl+a" })
bind("e", "pane.send_key", { key = "ctrl+e" })
bind("r", "client.config.reload")
bind("shift+s", "client.sidebar.toggle")
bind_character('"', "tmux_split", { direction = "vertical" })
bind_character("%", "tmux_split", { direction = "horizontal" })
bind_character("*", "tmux_float")
bind("tab", "tmux_window", { operation = "last" })
bind("shift+tab", "tmux_session", { operation = "last" })
bind("shift+l", "tmux_session", { operation = "last" })
bind_character("(", "tmux_session", { operation = "previous" })
bind_character(")", "tmux_session", { operation = "next" })
bind("s", "tmux_session", { operation = "choose" })
bind("c", "tmux_window", { operation = "new" })
bind("n", "tmux_window", { operation = "next" })
bind("p", "tmux_window", { operation = "previous" })
bind(";", "tmux_pane", { operation = "last" })
bind("o", "tmux_pane", { operation = "next" })
bind(",", "client.tab.rename")
bind_character("$", "session.rename")
bind_character("&", "client.tab.close")
bind("x", "pane.close")
bind("z", "pane.zoom")
bind_character("!", "pane.move_to_new_tab")
bind_character("@", "pane.float")
bind("shift+e", "pane.balance")
bind_character("{", "tmux_swap", { step = -1 })
bind_character("}", "tmux_swap", { step = 1 })
bind("ctrl+o", "tmux_rotate", { step = -1 })
bind("alt+o", "tmux_rotate", { step = 1 })
bind_character(":", "client.palette.toggle")
bind_character("?", "client.palette.toggle")
bind("w", "tmux_session", { operation = "choose" })
bind("f", "tmux_session", { operation = "choose" })

rex.mode("tmux-move", { exclusive = true })
bind("g", "client.mode.enter", { name = "tmux-move", once = true })
rex.bind("tmux-move/escape", "client.mode.exit")
for _, position in ipairs({
  { "1", 0, 0 }, { "2", 1, 0 }, { "3", 0, 1 }, { "4", 1, 1 },
  { "up", 0.5, 0 }, { "down", 0.5, 1 }, { "left", 0, 0.5 }, { "right", 1, 0.5 },
}) do
  rex.bind("tmux-move/" .. position[1], "tmux_move", { x = position[2], y = position[3] })
  local width = (position[1] == "up" or position[1] == "down") and 1 or 0.5
  local height = (position[1] == "left" or position[1] == "right") and 1 or 0.5
  rex.bind("tmux-move/alt+" .. position[1], "tmux_move", {
    x = position[2], y = position[3], width = width, height = height,
  })
  if character_keys[position[1]] then
    rex.bind("tmux-move/" .. character_keys[position[1]], "tmux_move", { x = position[2], y = position[3] })
    rex.bind("tmux-move/alt+" .. character_keys[position[1]], "tmux_move", {
      x = position[2], y = position[3], width = width, height = height,
    })
  end
end
rex.bind("tmux-move/0", "tmux_move", { x = 0, y = 0, width = 1, height = 1 })
rex.bind("tmux-move/" .. character_keys["0"], "tmux_move", { x = 0, y = 0, width = 1, height = 1 })

for index = 1, 9 do
  bind(tostring(index), "tmux_window", { operation = "goto", index = index })
  bind_character(tostring(index), "tmux_window", { operation = "goto", index = index })
end

for _, key in ipairs({ "left", "up", "h", "k" }) do
  bind(key, "tmux_pane", { operation = "previous" })
end
for _, key in ipairs({ "right", "down", "j", "l" }) do
  bind(key, "tmux_pane", { operation = "next" })
end

-- Rex has no tmux repeat timer. Enter resize mode with Ctrl+A, R; leave with Escape.
rex.mode("tmux-resize", { exclusive = true })
bind("shift+r", "client.mode.enter", { name = "tmux-resize" })
rex.bind("tmux-resize/escape", "client.mode.exit")
rex.bind("tmux-resize/enter", "client.mode.exit")
for _, movement in ipairs({ { "h", "left" }, { "j", "down" }, { "k", "up" }, { "l", "right" } }) do
  for _, key in ipairs({ movement[1], movement[2] }) do
    local arguments = { direction = movement[2], amount = 1 }
    bind("ctrl+" .. key, "tmux_resize", arguments)
    rex.bind("tmux-resize/ctrl+" .. key, "tmux_resize", arguments)
    rex.bind("tmux-resize/" .. key, "tmux_resize", arguments)
  end
  local arguments = { direction = movement[2], amount = 5 }
  bind("alt+" .. movement[2], "tmux_resize", arguments)
  rex.bind("tmux-resize/alt+" .. movement[2], "tmux_resize", arguments)
end
