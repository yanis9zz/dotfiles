local map = vim.keymap.set

map('n', '<Esc>', '<cmd>nohlsearch<CR>')
map('n', '<leader>m', vim.diagnostic.open_float, { desc = 'Show diagnostic [M]essage' })
map('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

map('n', '<left>', '<cmd>echo "Use h to move"<CR>')
map('n', '<right>', '<cmd>echo "Use l to move"<CR>')
map('n', '<up>', '<cmd>echo "Use k to move"<CR>')
map('n', '<down>', '<cmd>echo "Use j to move"<CR>')

map('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus left' })
map('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus right' })
map('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus down' })
map('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus up' })
map('n', '<C-S-h>', '<C-w>H', { desc = 'Move window left' })
map('n', '<C-S-l>', '<C-w>L', { desc = 'Move window right' })
map('n', '<C-S-j>', '<C-w>J', { desc = 'Move window down' })
map('n', '<C-S-k>', '<C-w>K', { desc = 'Move window up' })

local terminal_buf = nil
local terminal_win = nil
local terminal_editor_win = nil
local terminal_return_win = nil

local function current_tab_window(window)
  return window and vim.api.nvim_win_is_valid(window) and vim.api.nvim_win_get_tabpage(window) == vim.api.nvim_get_current_tabpage()
end

local function find_terminal_window()
  for _, window in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_buf(window) == terminal_buf then
      return window
    end
  end
end

local function hide_terminal_split()
  terminal_win = find_terminal_window()
  if terminal_win then
    vim.cmd 'stopinsert'
    if vim.api.nvim_get_current_win() == terminal_win and current_tab_window(terminal_return_win) and terminal_return_win ~= terminal_win then
      vim.api.nvim_set_current_win(terminal_return_win)
    end
    if vim.fn.winlayout()[1] == 'leaf' then
      vim.cmd 'enew'
    else
      vim.api.nvim_win_hide(terminal_win)
    end
  end

  terminal_win = nil
end

local function open_terminal_split(start_insert)
  terminal_return_win = vim.api.nvim_get_current_win()
  -- Keep the terminal above its editor when toggling from another split.
  if current_tab_window(terminal_editor_win) then
    vim.api.nvim_set_current_win(terminal_editor_win)
  else
    terminal_editor_win = vim.api.nvim_get_current_win()
  end
  local height = vim.api.nvim_win_get_height(0)
  local terminal_height = math.max(5, math.floor(height / 4))

  -- Open above the current window
  vim.cmd 'aboveleft split'
  terminal_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_height(terminal_win, terminal_height)

  local job = terminal_buf and vim.api.nvim_buf_is_valid(terminal_buf) and vim.b[terminal_buf].terminal_job_id
  -- A valid buffer can still belong to a shell that has exited.
  if job and vim.fn.jobwait({ job }, 0)[1] == -1 then
    vim.api.nvim_win_set_buf(terminal_win, terminal_buf)
  else
    vim.cmd 'terminal'
    terminal_buf = vim.api.nvim_get_current_buf()

    -- Keep the terminal alive when its window is closed
    vim.bo[terminal_buf].bufhidden = 'hide'
  end

  if start_insert then
    vim.cmd 'startinsert'
  end
end

local function toggle_terminal_split()
  if find_terminal_window() then
    hide_terminal_split()
  else
    open_terminal_split(true)
  end
end

-- Accept both releasing Ctrl after W and keeping it held for T.
for _, keys in ipairs { '<C-w>t', '<C-w><C-t>' } do
  map({ 'n', 't' }, keys, toggle_terminal_split, {
    desc = 'Toggle terminal split',
  })
end

local function layout_left_and_right_with_terminal_top()
  vim.cmd 'stopinsert'
  -- Preserve the terminal before rebuilding the layout
  hide_terminal_split()

  if vim.bo.buftype == 'terminal' then
    vim.cmd 'enew'
  end
  vim.cmd 'silent only'
  local left_editor = vim.api.nvim_get_current_win()
  vim.cmd 'vsplit'
  terminal_editor_win = vim.api.nvim_get_current_win()

  -- Reuse the same terminal in the top-right quarter
  open_terminal_split(false)

  -- Return focus to the left editor
  terminal_return_win = left_editor
  vim.api.nvim_set_current_win(left_editor)
end

map({ 'n', 't' }, '<leader>ol', layout_left_and_right_with_terminal_top, {
  desc = '[O]pen [L]ayout (term top right)',
})

local open_codex = function()
  require('config.codex').open()
end

local open_codex_current = function()
  require('config.codex').open_current()
end

map({ 'n', 't' }, '<leader>cc', open_codex, { desc = 'Open [C]odex CLI' })
map({ 'n', 't' }, '<leader>cw', open_codex_current, { desc = 'Open [C]odex in current [W]indow' })
