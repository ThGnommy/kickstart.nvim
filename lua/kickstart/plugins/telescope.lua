return {
  'nvim-telescope/telescope.nvim',
  event = 'VimEnter',
  dependencies = {
    'nvim-lua/plenary.nvim',
    {
      'nvim-telescope/telescope-fzf-native.nvim',
      build = 'make',
      cond = function()
        return vim.fn.executable 'make' == 1
      end,
    },
    { 'nvim-telescope/telescope-ui-select.nvim' },
  },
  config = function()
    local actions = require 'telescope.actions'
    local action_state = require 'telescope.actions.state'

    -- `:tab drop` needs a filename, so it errors (E471) on unnamed or non-file buffers.
    -- Used by the pickers that can surface those: buffers, current_buffer_fuzzy_find.
    local function select_tab_drop_if_file(prompt_bufnr)
      local entry = action_state.get_selected_entry()
      local bufnr = entry and entry.bufnr
      if bufnr and vim.api.nvim_buf_get_name(bufnr) ~= '' and vim.bo[bufnr].buftype == '' then
        return actions.select_tab_drop(prompt_bufnr)
      end
      return actions.select_default(prompt_bufnr)
    end

    -- Pickers whose <CR> means "open this file" get their own tab, reusing a tab that
    -- already shows the file. Deliberately NOT in defaults.mappings: <CR> there is
    -- `select_default`, which telescope-ui-select (LSP code actions), help_tags and
    -- builtin.builtin replace with non-file behaviour.
    local tab_drop_pickers = {
      'find_files',
      'git_files',
      'oldfiles',
      'live_grep',
      'grep_string',
      'diagnostics',
      'quickfix',
      'loclist',
      'lsp_references',
      'lsp_definitions',
      'lsp_implementations',
      'lsp_type_definitions',
      'lsp_document_symbols',
      'lsp_dynamic_workspace_symbols',
    }

    local function tab_drop_mappings(action)
      return { mappings = { i = { ['<CR>'] = action }, n = { ['<CR>'] = action } } }
    end

    local picker_opts = {
      buffers = tab_drop_mappings(select_tab_drop_if_file),
      current_buffer_fuzzy_find = tab_drop_mappings(select_tab_drop_if_file),
    }
    for _, name in ipairs(tab_drop_pickers) do
      picker_opts[name] = tab_drop_mappings(actions.select_tab_drop)
    end

    require('telescope').setup {
      defaults = {
        layout_strategy = 'vertical',
        vertical = { width = 0.8 },
      },
      pickers = picker_opts,
      extensions = {
        ['ui-select'] = { require('telescope.themes').get_dropdown() },
      },
    }

    pcall(require('telescope').load_extension, 'fzf')
    pcall(require('telescope').load_extension, 'ui-select')

    local builtin = require 'telescope.builtin'
    vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
    vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
    vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })

    -- Unreal Engine: search Content directory
    vim.keymap.set('n', '<leader>su', function()
      require('telescope.builtin').find_files {
        cwd = 'Content',
        hidden = true,
        no_ignore = true,
        prompt_title = 'Unreal Assets',
      }
    end, { desc = '[S]earch [U]nreal Content' })

    vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
    vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
    vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
    vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
    vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
    vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
    vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

    vim.keymap.set('n', '<leader>ad', function()
      vim.diagnostic.open_float(nil, { focus = false, border = 'rounded' })
    end, { desc = 'Show diagnostics in floating window' })

    vim.keymap.set('n', '<leader>ar', builtin.lsp_references, { desc = '[S]earch References' })
    vim.keymap.set('n', '<leader>ai', builtin.lsp_implementations, { desc = '[S]earch Implementations' })
    vim.keymap.set('n', '<leader>ao', '<cmd>LspClangdSwitchSourceHeader<CR>', { desc = '[S]witch between header/cpp' })

    vim.keymap.set('n', '<leader>/', function()
      builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown { winblend = 10, previewer = false })
    end, { desc = '[/] Fuzzily search in current buffer' })

    vim.keymap.set('n', '<leader>s/', function()
      builtin.live_grep { grep_open_files = true, prompt_title = 'Live Grep in Open Files' }
    end, { desc = '[S]earch [/] in Open Files' })

    vim.keymap.set('n', '<leader>sn', function()
      builtin.find_files { cwd = vim.fn.stdpath 'config' }
    end, { desc = '[S]earch [N]eovim files' })
  end,
}
