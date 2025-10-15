local UnrealUtils = {}

function UnrealUtils.find_uproject_files()
  local cwd = vim.fn.getcwd()
  return vim.fn.globpath(cwd, '*.uproject', false, true)
end

function UnrealUtils.get_default_engine_path()
  return os.getenv 'UNREAL_ENGINE_PATH'
end

return UnrealUtils
