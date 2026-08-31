-- Sessions save every buffer (`sessionoptions` includes `buffers`) but only the tabs
-- that existed, so files come back loaded yet invisible. Give each one its own tab.
local function tabs_from_buffers()
  local shown = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    shown[vim.api.nvim_win_get_buf(win)] = true
  end

  local original = vim.api.nvim_get_current_tabpage()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    -- Skip unnamed and non-file buffers: `sbuffer` would show a scratch or terminal tab.
    if not shown[buf] and vim.bo[buf].buflisted and vim.api.nvim_buf_get_name(buf) ~= '' and vim.bo[buf].buftype == '' then
      vim.cmd('tab sbuffer ' .. buf)
      shown[buf] = true
    end
  end
  vim.api.nvim_set_current_tabpage(original)
end

return {
  {
    'rmagatti/auto-session',
    lazy = false,

    ---enables autocomplete for opts
    ---@module "auto-session"
    ---@type AutoSession.Config
    opts = {
      suppressed_dirs = { '~/', '~/Projects', '~/Downloads', '/' },
      post_restore_cmds = { tabs_from_buffers },
      -- log_level = 'debug',
    },
  },
}
