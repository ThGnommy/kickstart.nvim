local CppUtils = {}

function CppUtils.GenerateDefinition()
  local line = vim.api.nvim_get_current_line()
  local file = vim.fn.expand '%:p' -- full path
  local filename = vim.fn.expand '%:t:r' -- file name without extension

  -- 1️⃣ Check if the file has UCLASS
  local uclass_found = false
  for _, l in ipairs(vim.fn.readfile(file)) do
    if l:match '^%s*UCLASS' then
      uclass_found = true
      break
    end
  end

  -- 2️⃣ Decide the class name
  local class_name = filename
  if uclass_found and not class_name:match '^U' then
    class_name = 'U' .. class_name
  end

  -- 3️⃣ Clean up the function line
  local func = line:gsub(';$', ''):gsub('^%s*', '')

  -- 4️⃣ Match return type, function name, args, qualifiers
  local ret_and_name, args_and_qualifiers = func:match '^(.+%S)%s*(%b())%s*(.*)$'
  if not ret_and_name then
    print 'Could not detect function'
    return
  end

  local ret_type, name = ret_and_name:match '^(.-)%s+([%w_:~]+)$'
  if not ret_type or not name then
    print 'Could not detect function name'
    return
  end

  -- 6️⃣ Build stub
  local stub = string.format('%s %s::%s%s', ret_type, class_name, name, args_and_qualifiers)
  stub = stub .. ' {\n    // TODO: implement\n}\n'

  -- 7️⃣ Copy to clipboard
  vim.fn.setreg('+', stub)
  print 'C++ definition copied to clipboard'
end

return CppUtils
