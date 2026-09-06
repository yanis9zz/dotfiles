return {
  {
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = { library = { { path = '${3rd}/luv/library', words = { 'vim%.uv' } } } },
  },
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      { 'mason-org/mason.nvim', opts = {} },
      'mason-org/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      { 'j-hui/fidget.nvim', opts = {} },
      'saghen/blink.cmp',
    },
    config = function()
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('dotfiles-lsp-attach', { clear = true }),
        callback = function(event)
          local function map(keys, action, description, mode)
            vim.keymap.set(mode or 'n', keys, action, { buffer = event.buf, desc = 'LSP: ' .. description })
          end

          local function telescope(picker)
            return function()
              require('telescope.builtin')[picker]()
            end
          end

          map('grn', vim.lsp.buf.rename, '[R]e[n]ame')
          map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
          map('grr', telescope 'lsp_references', '[G]oto [R]eferences')
          map('gri', telescope 'lsp_implementations', '[G]oto [I]mplementation')
          map('grd', telescope 'lsp_definitions', '[G]oto [D]efinition')
          map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
          map('gO', telescope 'lsp_document_symbols', 'Document symbols')
          map('gW', telescope 'lsp_dynamic_workspace_symbols', 'Workspace symbols')
          map('grt', telescope 'lsp_type_definitions', '[G]oto [T]ype definition')

          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
            local highlight_group = vim.api.nvim_create_augroup('dotfiles-lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              group = highlight_group,
              buffer = event.buf,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              group = highlight_group,
              buffer = event.buf,
              callback = vim.lsp.buf.clear_references,
            })
            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('dotfiles-lsp-detach', { clear = true }),
              callback = function(detach_event)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = highlight_group, buffer = detach_event.buf }
              end,
            })
          end

          if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
            map('<leader>th', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
            end, '[T]oggle Inlay [H]ints')
          end
        end,
      })

      vim.diagnostic.config {
        severity_sort = true,
        float = { border = 'rounded', source = 'if_many' },
        underline = { severity = vim.diagnostic.severity.ERROR },
        signs = vim.g.have_nerd_font and {
          text = {
            [vim.diagnostic.severity.ERROR] = '󰅚 ',
            [vim.diagnostic.severity.WARN] = '󰀪 ',
            [vim.diagnostic.severity.INFO] = '󰋽 ',
            [vim.diagnostic.severity.HINT] = '󰌶 ',
          },
        } or {},
        virtual_text = { source = 'if_many', spacing = 2 },
      }

      local capabilities = require('blink.cmp').get_lsp_capabilities()
      local servers = {
        clangd = {
          cmd = {
            'clangd',
            '--background-index',
            '--clang-tidy',
            '--completion-style=detailed',
            '--header-insertion=never',
          },
        },
        pyright = {},
        ts_ls = {},
        lua_ls = {
          on_init = function(client)
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false
          end,
          settings = {
            Lua = {
              completion = { callSnippet = 'Replace' },
              format = { enable = false },
            },
          },
        },
      }

      -- Mason does not distribute clangd for Linux ARM64; bootstrap installs the distro package.
      local system = vim.uv.os_uname()
      local system_clangd = system.sysname == 'Linux' and (system.machine == 'aarch64' or system.machine == 'arm64')
      local tools = {}
      for name in pairs(servers) do
        if name ~= 'clangd' or not system_clangd then
          table.insert(tools, name)
        end
      end
      table.insert(tools, 'stylua')
      require('mason-tool-installer').setup { ensure_installed = tools }
      require('mason-lspconfig').setup { automatic_enable = false }

      for name, config in pairs(servers) do
        config.capabilities = vim.tbl_deep_extend('force', {}, capabilities, config.capabilities or {})
        vim.lsp.config(name, config)
        vim.lsp.enable(name)
      end
    end,
  },
}
