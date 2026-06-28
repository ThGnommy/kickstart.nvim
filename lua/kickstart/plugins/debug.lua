-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for Go, but can
-- be extended to other languages as well. That's why it's called
-- kickstart.nvim and not kitchen-sink.nvim ;)

return {
  -- NOTE: Yes, you can install new plugins here!
  'mfussenegger/nvim-dap',
  -- NOTE: And you can specify dependencies as well
  dependencies = {
    -- Creates a beautiful debugger UI
    'rcarriga/nvim-dap-ui',

    -- Required dependency for nvim-dap-ui
    'nvim-neotest/nvim-nio',

    -- Installs the debug adapters for you
    'mason-org/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',

    -- View inline variables
    'theHamsta/nvim-dap-virtual-text',

    -- Add your own debuggers here
    'leoluz/nvim-dap-go',
  },
  keys = {
    -- Basic debugging keymaps, feel free to change to your liking!
    {
      '<F5>',
      function()
        require('dap').continue()
      end,
      desc = 'Debug: Start/Continue',
    },
    {
      '<F1>',
      function()
        require('dap').step_into()
      end,
      desc = 'Debug: Step Into',
    },
    {
      '<F2>',
      function()
        require('dap').step_over()
      end,
      desc = 'Debug: Step Over',
    },
    {
      '<F3>',
      function()
        require('dap').step_out()
      end,
      desc = 'Debug: Step Out',
    },
    {
      '<leader>b',
      function()
        require('dap').toggle_breakpoint()
      end,
      desc = 'Debug: Toggle Breakpoint',
    },
    {
      '<leader>B',
      function()
        require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')
      end,
      desc = 'Debug: Set Breakpoint',
    },
    -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
    {
      '<F7>',
      function()
        require('dapui').toggle()
      end,
      desc = 'Debug: See last session result.',
    },
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    require('nvim-dap-virtual-text').setup {
      commented = true,
      virt_text_win_col = 20,
    }

    require('mason-nvim-dap').setup {
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_installation = true,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {},

      -- You'll need to check that you have the required things installed
      -- online, please don't ask me how to install them :)
      ensure_installed = {
        -- Update this to ensure that you have the debuggers for the langs you want
        'delve',
        'codelldb',
      },
    }

    -- Dap UI setup
    -- For more information, see |:help nvim-dap-ui|
    dapui.setup {
      mappings = {
        expand = { '<Space>' },
        open = '<CR>',
      },
      layouts = {
        {
          elements = {
            'stacks',
            'scopes',
            'breakpoints',
            -- 'watches',
          },
          size = 15,
          position = 'bottom',
        },
        {
          elements = {
            'repl',
            'console',
          },
          size = 10,
          position = 'bottom',
        },
      },
      -- Set icons to characters that are more likely to work in every terminal.
      --    Feel free to remove or use ones that you like more! :)
      --    Don't feel like these are good choices.
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      controls = {
        icons = {
          pause = '⏸ [F5]',
          play = '▶ [F5]',
          step_into = '⏎ [F1]',
          step_over = '⏭ [F2]',
          step_out = '⏮ [F3]',
          step_back = 'b [F7]',
          run_last = '▶▶ [F5]',
        },
      },
    }

    -- Change breakpoint icons
    vim.api.nvim_set_hl(0, 'DapBreak', { fg = '#e51400' })
    vim.api.nvim_set_hl(0, 'DapStop', { fg = '#ffcc00' })
    local breakpoint_icons = vim.g.have_nerd_font
        and { Breakpoint = '', BreakpointCondition = '', BreakpointRejected = '', LogPoint = '', Stopped = '' }
      or { Breakpoint = '●', BreakpointCondition = '⊜', BreakpointRejected = '⊘', LogPoint = '◆', Stopped = '⭔' }
    for type, icon in pairs(breakpoint_icons) do
      local tp = 'Dap' .. type
      local hl = (type == 'Stopped') and 'DapStop' or 'DapBreak'
      vim.fn.sign_define(tp, { text = icon, texthl = hl, numhl = hl })
    end

    vim.keymap.set('n', '<leader>ah', function()
      local widgets = require 'dap.ui.widgets'
      widgets.hover(nil, { border = 'rounded' }) -- options: 'single', 'double', 'rounded', 'solid', 'shadow'
    end, { noremap = true, silent = true, desc = '[S]how Variable on cursor' })

    dap.adapters.codelldb = {
      type = 'server',
      port = '${port}',
      executable = {
        -- You can also use `vim.fn.stdpath("data") .. "/mason/bin/codelldb"` if installed via Mason
        command = vim.fn.stdpath 'data' .. '/mason/packages/codelldb/extension/adapter/codelldb',
        args = { '--port', '${port}' },
      },
    }

    local unreal_utils = require 'custom.unreal-utils'
    local uprojects = unreal_utils.find_uproject_files()

    dap.configurations.cpp = {
      {
        name = 'Dynamic Launch with Unreal Engine project support',
        type = 'codelldb',
        request = 'launch',
        program = function()
          if #uprojects == 0 then
            -- fallback: ask for executable
            return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
          else
            return unreal_utils.get_default_engine_path()
          end
        end,
        args = function()
          if #uprojects == 0 then
            return {} -- no args if manually launching
          else
            -- use the first .uproject
            return { uprojects[1], '-log', '-debug', '-nosplash' }
          end
        end,
        cwd = '${workspaceFolder}',
        stopOnEntry = false,
        evaluationTimeout = 0.3,
        preRunCommands = {
          'breakpoint name configure --disable cpp_exception',
          'settings set target.inline-breakpoint-strategy always',
        },
      },
    }

    -- Optionally reuse same config for C and Rust:
    dap.configurations.c = dap.configurations.cpp
    dap.configurations.rust = dap.configurations.cpp

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close
  end,
}
