vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = true
local config_path = vim.uv.fs_realpath(vim.fn.stdpath 'config' .. '/init.lua')
if config_path then
  vim.g.dotfiles_root = vim.fn.fnamemodify(config_path, ':h:h:h:h')
end

-- These optional providers are not used by this configuration.
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

require 'config.options'
require 'config.keymaps'
require 'config.lazy'
