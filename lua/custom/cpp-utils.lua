local CppUtils = {}

function CppUtils.GenerateDefinition()
  local line = vim.api.nvim_get_current_line()
  local file = vim.fn.expand '%:p'
  local filename = vim.fn.expand '%:t:r'

  -- Check if the file has UCLASS (skip comment lines)
  local uclass_found = false
  for _, l in ipairs(vim.fn.readfile(file)) do
    if not l:match '^%s*//' and l:match 'UCLASS' then
      uclass_found = true
      break
    end
  end

  -- Decide the class name
  local class_name = filename
  if uclass_found and not class_name:match '^U' then
    class_name = 'U' .. class_name
  end

  -- Clean up the function line
  local func = line:gsub(';$', ''):gsub('^%s*', '')

  -- Match: everything before args, the args (balanced parens), trailing qualifiers
  local ret_and_name, args, qualifiers = func:match '^(.+%S)%s*(%b())%s*(.-)%s*$'
  if not ret_and_name then
    print 'Could not detect function'
    return
  end

  -- Split the ret+name part: lazy match for return type, greedy for name
  local ret_type, name = ret_and_name:match '^(.-)%s+([%w_:~]+)$'
  if not ret_type or not name then
    print 'Could not detect function name'
    return
  end

  -- Build stub, appending qualifiers (const, override, noexcept, = 0, etc.) if present
  local qual_part = (qualifiers ~= '') and (' ' .. qualifiers) or ''
  local stub = string.format('%s %s::%s%s%s', ret_type, class_name, name, args, qual_part)
  stub = stub .. '\n{\n    // TODO: implement\n}\n'

  vim.fn.setreg('+', stub)
  print 'C++ definition copied to clipboard'
end

return CppUtils
