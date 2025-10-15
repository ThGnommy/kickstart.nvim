--[[
  UE Build Command for Neovim

  This module creates a user command `:UEBuild` that:
    - Opens a floating window showing the output of `ue4 build DebugGame`
    - Highlights errors and warnings in the build output
    - Automatically closes the window on success or when pressing <Esc>
    - Optionally continues debugging via DAP if build succeeds
--]]
--

local ns = vim.api.nvim_create_namespace 'BuildHighlights'

local function highlight_errors(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

  for i, line in ipairs(lines) do
    if line:lower():find 'error:' then
      vim.api.nvim_buf_add_highlight(buf, ns, 'ErrorMsg', i - 1, 0, -1)
    elseif line:lower():find 'warning:' then
      vim.api.nvim_buf_add_highlight(buf, ns, 'WarningMsg', i - 1, 0, -1)
    end
  end
end

return {
  vim.api.nvim_create_user_command('UEBuild', function()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].bufhidden = 'wipe'
    vim.bo[buf].filetype = 'log'

    local width = math.floor(vim.o.columns * 0.5)
    local height = math.floor(vim.o.lines * 0.5)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    local cwd = vim.fn.getcwd()
    local project_name = cwd:match '([^/]+)$'

    local win = vim.api.nvim_open_win(buf, true, {
      title = '*** Building ' .. project_name .. ' ***',
      title_pos = 'center',
      relative = 'editor',
      width = width,
      height = height,
      row = row,
      col = col,
      border = 'rounded',
      style = 'minimal',
    })

    local cmd = 'ue4 build DebugGame'
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'Running: ' .. cmd, '' })

    local function append(data)
      if not data then
        return
      end
      vim.api.nvim_buf_set_lines(buf, -1, -1, false, data)
      vim.api.nvim_win_set_cursor(win, { vim.api.nvim_buf_line_count(buf), 0 })
      highlight_errors(buf)
    end

    local job_finished = false

    vim.fn.jobstart({ 'bash', '-c', cmd }, {
      stdout_buffered = false,
      stderr_buffered = false,
      on_stdout = function(_, data)
        append(data)
      end,
      on_stderr = function(_, data)
        append(data)
      end,
      on_exit = function(_, code)
        append { '', '--- Process exited with code ' .. code .. ' ---' }
        job_finished = true
        if code == 0 then
          vim.notify('✅ Build succeeded: ', vim.log.levels.INFO)
          -- close build window after short delay
          vim.defer_fn(function()
            if vim.api.nvim_win_is_valid(win) then
              vim.api.nvim_win_close(win, true)
            end
            require('dap').continue()
          end, 500)
        else
          vim.notify('❌ Build failed (' .. code .. ')', vim.log.levels.ERROR)
        end
      end,
    })

    -- close the window when press esc
    vim.keymap.set('n', '<Esc>', function()
      if job_finished and vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end, { buffer = buf, nowait = true })
  end, {}),
}
