-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  vim.api.nvim_create_user_command('UEBuild', function()
    local targets = { 'DebugGame', 'Development' }

    -- open a floating window for selection
    vim.ui.select(targets, { prompt = 'Select build target:' }, function(choice)
      if not choice then
        vim.notify('No target selected!', vim.log.levels.WARN)
        return
      end

      -- everything below runs only after user picks a target
      local buf = vim.api.nvim_create_buf(false, true)
      vim.bo[buf].bufhidden = 'wipe'
      vim.bo[buf].filetype = 'log'

      local width = math.floor(vim.o.columns * 0.9)
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

      local cmd = 'ue4 build ' .. choice
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'Running: ' .. cmd, '' })

      local function append(data)
        if not data then
          return
        end
        vim.api.nvim_buf_set_lines(buf, -1, -1, false, data)
        vim.api.nvim_win_set_cursor(win, { vim.api.nvim_buf_line_count(buf), 0 })
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
        end,
      })

      -- close the window when press esc
      vim.keymap.set('n', '<Esc>', function()
        if job_finished and vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end
      end, { buffer = buf, nowait = true })
    end)
  end, {}),
}
