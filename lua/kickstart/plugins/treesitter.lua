return {
  'romus204/tree-sitter-manager.nvim',
  config = function()
    require('tree-sitter-manager').setup { {
      border = 'rounded',
    } }
  end,
}
