local M = { buffers = {} }
local codex_command = {
  'codex',
  '-c',
  'tui.animations=false',
  '-c',
  'tui.alternate_screen=always',
}
local codex_window_options = {
  cursorcolumn = false,
  cursorline = false,
  foldcolumn = '0',
  number = false,
  relativenumber = false,
  scrolloff = 0,
  signcolumn = 'no',
  sidescrolloff = 0,
}

local function project_root()
  return vim.fs.root(0, '.git') or vim.uv.cwd()
end

local function codex_installed()
  if vim.fn.executable 'codex' == 1 then
    return true
  end

  vim.notify('Codex CLI introuvable. Voir https://developers.openai.com/codex/cli/', vim.log.levels.ERROR)
  return false
end

local function terminal_is_running(buffer)
  if not buffer or not vim.api.nvim_buf_is_valid(buffer) then
    return false
  end

  local ok, job = pcall(vim.api.nvim_buf_get_var, buffer, 'terminal_job_id')
  return ok and job > 0 and vim.fn.jobwait({ job }, 0)[1] == -1
end

local function create_terminal(root)
  local buffer = vim.api.nvim_create_buf(false, true)
  vim.bo[buffer].bufhidden = 'hide'
  vim.b[buffer].codex_terminal = true
  vim.b[buffer].codex_root = root

  vim.api.nvim_buf_call(buffer, function()
    vim.fn.termopen(codex_command, { cwd = root })
    vim.bo[buffer].scrollback = 1000
  end)

  M.buffers[root] = buffer
  return buffer
end

local function project_terminal(root)
  local buffer = M.buffers[root]

  if terminal_is_running(buffer) then
    return buffer
  end

  if buffer and vim.api.nvim_buf_is_valid(buffer) then
    vim.api.nvim_buf_delete(buffer, { force = true })
  end

  return create_terminal(root)
end

local function set_window_options(window, options)
  for name, value in pairs(options) do
    vim.api.nvim_set_option_value(name, value, { win = window })
  end
end

local function configure_codex_window(window)
  set_window_options(window, codex_window_options)
end

local function current_window_options(window)
  local options = {}

  for name in pairs(codex_window_options) do
    options[name] = vim.api.nvim_get_option_value(name, { win = window })
  end

  return options
end

local function open_native_terminal(root)
  local buffer = project_terminal(root)
  vim.cmd 'botright 15split'
  vim.api.nvim_win_set_buf(0, buffer)
  configure_codex_window(0)
  vim.cmd 'startinsert'
end

function M.open()
  if not codex_installed() then
    return
  end

  local root = project_root()
  local helper = (vim.g.dotfiles_root or vim.fn.expand '~/config') .. '/scripts/codex-popup'

  if vim.env.TMUX and vim.fn.executable 'tmux' == 1 and vim.fn.executable(helper) == 1 then
    local job = vim.fn.jobstart({ helper, root }, { detach = true })
    if job > 0 then
      return
    end

    vim.notify('Impossible de lancer la popup tmux, ouverture dans Neovim.', vim.log.levels.WARN)
  end

  open_native_terminal(root)
end

function M.open_current()
  if not codex_installed() then
    return
  end

  local window = vim.api.nvim_get_current_win()
  local current = vim.api.nvim_win_get_buf(window)

  if vim.b[current].codex_terminal then
    local previous = vim.w[window].codex_previous_buf
    local previous_options = vim.w[window].codex_previous_window_options
    vim.w[window].codex_previous_buf = nil
    vim.w[window].codex_previous_window_options = nil

    if previous and vim.api.nvim_buf_is_valid(previous) and previous ~= current then
      vim.api.nvim_win_set_buf(window, previous)
      if vim.bo[previous].buftype == 'terminal' then
        vim.cmd 'startinsert'
      end
    else
      vim.cmd 'enew'
    end

    if previous_options then
      set_window_options(window, previous_options)
    end

    return
  end

  vim.w[window].codex_previous_buf = current
  vim.w[window].codex_previous_window_options = current_window_options(window)
  vim.api.nvim_win_set_buf(window, project_terminal(project_root()))
  configure_codex_window(window)
  vim.cmd 'startinsert'
end

return M
