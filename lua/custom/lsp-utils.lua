local LspUtils = {}

function LspUtils.lsp_restart(code, signal)
  if signal ~= 0 then
    vim.defer_fn(function()
      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(bufnr) then
          local ft = vim.bo[bufnr].filetype
          if vim.tbl_contains({ 'c', 'cpp', 'objc', 'objcpp' }, ft) then
            vim.api.nvim_exec_autocmds('FileType', { buffer = bufnr })
          end
        end
      end
    end, 3000)
  end
end

return LspUtils
