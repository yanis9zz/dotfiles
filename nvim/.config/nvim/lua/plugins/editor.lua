return {
  {
    'NMAC427/guess-indent.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    opts = {
      filetype_exclude = { 'c', 'cpp', 'netrw', 'tutor' },
    },
  },

  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    opts = {
      delay = 0,
      icons = { mappings = vim.g.have_nerd_font },
      spec = {
        { '<leader>s', group = '[S]earch' },
        { '<leader>sh', group = '[S]earch [H]idden' },
        { '<leader>t', group = '[T]oggle' },
        { '<leader>o', group = '[O]pen' },
        { '<leader>g', group = '[G]oto' },
        { '<leader>gp', group = '[G]oto [P]review' },
        { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
        { '<leader>c', group = '[C]odex' },
        { '<leader>l', group = '[L]eetCode' },
      },
    },
  },

  {
    'nvim-telescope/telescope.nvim',
    cmd = 'Telescope',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      'nvim-telescope/telescope-ui-select.nvim',
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },
    keys = {
      { '<leader>sH', '<cmd>Telescope help_tags<cr>', desc = '[S]earch [H]elp' },
      { '<leader>sk', '<cmd>Telescope keymaps<cr>', desc = '[S]earch [K]eymaps' },
      { '<leader>sf', '<cmd>Telescope find_files<cr>', desc = '[S]earch [F]iles' },
      { '<leader>ss', '<cmd>Telescope builtin<cr>', desc = '[S]earch [S]elect Telescope' },
      { '<leader>sw', '<cmd>Telescope grep_string<cr>', desc = '[S]earch current [W]ord' },
      { '<leader>sg', '<cmd>Telescope live_grep<cr>', desc = '[S]earch by [G]rep' },
      { '<leader>sd', '<cmd>Telescope diagnostics<cr>', desc = '[S]earch [D]iagnostics' },
      { '<leader>sr', '<cmd>Telescope resume<cr>', desc = '[S]earch [R]esume' },
      { '<leader>s.', '<cmd>Telescope oldfiles<cr>', desc = '[S]earch recent files' },
      { '<leader><leader>', '<cmd>Telescope buffers<cr>', desc = 'Find open buffers' },
      {
        '<leader>/',
        function()
          require('telescope.builtin').current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
            winblend = 10,
            previewer = false,
          })
        end,
        desc = 'Search in current buffer',
      },
      {
        '<leader>s/',
        function()
          require('telescope.builtin').live_grep {
            grep_open_files = true,
            prompt_title = 'Live Grep in Open Files',
          }
        end,
        desc = '[S]earch open buffers',
      },
      {
        '<leader>sn',
        function()
          require('telescope.builtin').find_files { cwd = vim.fn.stdpath 'config' }
        end,
        desc = '[S]earch [N]eovim files',
      },
      { '<leader>shf', '<cmd>Telescope find_files hidden=true<cr>', desc = '[S]earch [H]idden [F]iles' },
      {
        '<leader>shg',
        function()
          require('telescope.builtin').live_grep {
            additional_args = function()
              return { '--hidden' }
            end,
          }
        end,
        desc = '[S]earch [H]idden by [G]rep',
      },
    },
    config = function()
      require('telescope').setup {
        extensions = { ['ui-select'] = { require('telescope.themes').get_dropdown() } },
      }
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')
    end,
  },

  {
    'stevearc/conform.nvim',
    event = 'BufWritePre',
    cmd = 'ConformInfo',
    keys = {
      {
        '<leader>f',
        function()
          require('conform').format { async = true, lsp_format = 'fallback' }
        end,
        mode = { 'n', 'x' },
        desc = '[F]ormat buffer or selection',
      },
    },
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        if vim.tbl_contains({ 'c', 'cpp' }, vim.bo[bufnr].filetype) then
          return nil
        end
        return { timeout_ms = 500, lsp_format = 'fallback' }
      end,
      formatters_by_ft = { lua = { 'stylua' } },
    },
  },

  {
    'saghen/blink.cmp',
    event = 'InsertEnter',
    version = '1.*',
    dependencies = {
      {
        'L3MON4D3/LuaSnip',
        version = '2.*',
        build = vim.fn.executable 'make' == 1 and 'make install_jsregexp' or nil,
        opts = {},
      },
      'folke/lazydev.nvim',
    },
    opts = {
      keymap = { preset = 'default' },
      appearance = { nerd_font_variant = 'mono' },
      completion = { documentation = { auto_show = true, auto_show_delay_ms = 100 } },
      sources = {
        default = { 'lsp', 'path', 'snippets', 'lazydev' },
        providers = { lazydev = { module = 'lazydev.integrations.blink', score_offset = 100 } },
      },
      snippets = { preset = 'luasnip' },
      fuzzy = { implementation = 'lua' },
      signature = { enabled = true },
    },
  },

  {
    'folke/tokyonight.nvim',
    priority = 1000,
    config = function()
      vim.o.background = 'dark'
      require('tokyonight').setup { styles = { comments = { italic = false } } }
      vim.cmd.colorscheme 'tokyonight-moon'
    end,
  },

  {
    'folke/todo-comments.nvim',
    event = { 'BufReadPost', 'BufNewFile' },
    dependencies = 'nvim-lua/plenary.nvim',
    keys = {
      { '<leader>st', '<cmd>TodoTelescope<cr>', desc = '[S]earch [T]odo list' },
    },
    opts = { signs = false },
  },

  {
    'echasnovski/mini.nvim',
    event = 'VeryLazy',
    config = function()
      require('mini.ai').setup { n_lines = 500 }
      require('mini.surround').setup()
      local statusline = require 'mini.statusline'
      statusline.setup { use_icons = vim.g.have_nerd_font, set_icon = true }
      statusline.section_location = function()
        return '%2l:%-2v'
      end
    end,
  },

  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'master',
    event = { 'BufReadPost', 'BufNewFile' },
    build = ':TSUpdate',
    main = 'nvim-treesitter.configs',
    opts = {
      ensure_installed = {
        'bash',
        'c',
        'cpp',
        'css',
        'diff',
        'dockerfile',
        'html',
        'javascript',
        'json',
        'jsonc',
        'lua',
        'luadoc',
        'make',
        'markdown',
        'markdown_inline',
        'python',
        'query',
        'toml',
        'tsx',
        'typescript',
        'vim',
        'vimdoc',
        'yaml',
      },
      auto_install = true,
      highlight = { enable = true, additional_vim_regex_highlighting = { 'ruby' } },
      indent = { enable = true, disable = { 'ruby', 'c' } },
    },
  },
}
