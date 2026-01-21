-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information

--[[
  UE Build Command for Neovim

  This module creates a user command `:UEBuild` that:
    - Opens a floating window showing the output of `ue4 build DebugGame`
    - Highlights errors and warnings in the build output
    - Automatically closes the window on success or when pressing <Esc>
    - Close the window and kill the process using `:UEBuildStop`
    - Optionally continues debugging via DAP if build succeeds
--]]
--

local ns = vim.api.nvim_create_namespace 'BuildHighlights'

local function highlight_errors(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

  for i, line in ipairs(lines) do
    if line:lower():find 'error:' then
      vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, {
        end_col = #line,
        hl_group = 'ErrorMsg',
      })
    elseif line:lower():find 'warning:' then
      vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, {
        end_col = #line,
        hl_group = 'WarningMsg',
      })
    end
  end
end

local current_job = {
  id = nil,
  finished = false,
  buf = nil,
  win = nil,
}

return {
  vim.api.nvim_create_user_command('UEBuild', function()
    current_job.buf = vim.api.nvim_create_buf(false, true)
    vim.bo[current_job.buf].bufhidden = 'wipe'
    vim.bo[current_job.buf].filetype = 'log'
    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.4)
    local row = vim.o.lines - height - 4
    local col = math.floor((vim.o.columns - width) / 2)
    local cwd = vim.fn.getcwd()
    local project_name = cwd:match '([^/]+)$'
    current_job.win = vim.api.nvim_open_win(current_job.buf, true, {
      title = '*** Building ' .. project_name .. ' ***',
      title_pos = 'center',
      relative = 'editor',
      width = width,
      height = height,
      row = row,
      col = col,
      border = 'double',
      style = 'minimal',
    })
    local cmd = 'ue4 build DebugGame'
    vim.api.nvim_buf_set_lines(current_job.buf, 0, -1, false, { 'Running: ' .. cmd, '' })

    local function append(data)
      if not data then
        return
      end
      vim.api.nvim_buf_set_lines(current_job.buf, -1, -1, false, data)
      if vim.api.nvim_win_is_valid(current_job.win) then
        vim.api.nvim_win_set_cursor(current_job.win, { vim.api.nvim_buf_line_count(current_job.buf), 0 })
      end
      highlight_errors(current_job.buf)
    end

    current_job.finished = false
    current_job.id = vim.fn.jobstart({ 'bash', '-c', cmd }, {
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
        current_job.finished = true
        if code == 0 then
          vim.notify('✅ Build succeeded: ', vim.log.levels.INFO)
          -- close build window after short delay
          vim.defer_fn(function()
            if vim.api.nvim_win_is_valid(current_job.win) then
              vim.api.nvim_win_close(current_job.win, true)
            end
            require('dap').continue()
          end, 500)
        else
          vim.notify('❌ Build failed (' .. code .. ')', vim.log.levels.ERROR)
        end
      end,
    })

    -- close the window with <Esc> if the build is finished
    vim.keymap.set('n', '<Esc>', function()
      if current_job.finished and vim.api.nvim_win_is_valid(current_job.win) then
        vim.api.nvim_win_close(current_job.win, true)
      end
    end, { buffer = current_job.buf, nowait = true })
  end, {}),

  -- command to stop the build
  vim.api.nvim_create_user_command('UEBuildStop', function()
    if not current_job.finished and current_job.id then
      vim.fn.jobstop(current_job.id)
      if current_job.buf and vim.api.nvim_buf_is_valid(current_job.buf) then
        vim.api.nvim_buf_set_lines(current_job.buf, -1, -1, false, { '', '🛑 Build process killed' })
        vim.notify('🛑 Build process killed', vim.log.levels.WARN)
      end
    else
      vim.notify('⚠️ Build process not found', vim.log.levels.INFO)
    end
  end, {}),
}
