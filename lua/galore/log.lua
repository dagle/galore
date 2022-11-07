local function show_level(level)
  if level == vim.log.levels.TRACE then
    return 'TRACE'
  elseif level == vim.log.levels.DEBUG then
    return 'DEBUG'
  elseif level == vim.log.levels.INFO then
    return 'INFO'
  elseif level == vim.log.levels.WARN then
    return 'WARN'
  elseif level == vim.log.levels.ERROR then
    return 'ERROR'
    -- elseif level == vim.log.levels.OFF then
  end
end

local p_debug = vim.fn.getenv('DEBUG_GALORE')
if p_debug == vim.NIL then
  p_debug = false
end

-- User configuration section
local default_config = {
  -- Name of the plugin. Prepended to log messages
  plugin = 'Galore',

  notify = true,

  -- Should write to a file
  use_file = true,
  -- default_level

  -- Should write to the quickfix list
  -- use notify to quickfix instead
  -- use_quickfix = false,

  -- Any messages above this level will be logged.
  level = p_debug and vim.log.levels.DEBUG or vim.log.levels.INFO,
}

local log = {}

log.new = function(config)
  config = vim.tbl_deep_extend('force', default_config, config)

  local outfile =
    string.format('%s/%s.log', vim.api.nvim_call_function('stdpath', { 'cache' }), config.plugin)

  local obj = {}
  local logfun = function(str, level)
    if not level then
      level = vim.log.levels.INFO
    end
    if level < config.level then
      return
    end

    local info = debug.getinfo(2, 'Sl')
    local lineinfo = info.short_src .. ':' .. info.currentline

    -- Send a notify if we have that configured
    if config.notify then
      local message = string.format('[%s] %s', config.plugin, str)
      vim.notify(message, level)
    end

    local levelstr = show_level(level)
    -- Output to log file
    if config.use_file then
      local fp = assert(io.open(outfile, 'a'))
      local message = string.format('[%-6s%s] %s: %s\n', levelstr, os.date(), lineinfo, str)
      fp:write(message)
      fp:close()
    end

    -- maybe
    -- Output to quickfix
    if config.use_quickfix then
      local formatted_msg = string.format('[%s] %s', levelstr, str)
      local qf_entry = {
        -- remove the @ getinfo adds to the file path
        filename = info.source:sub(2),
        lnum = info.currentline,
        col = 1,
        text = formatted_msg,
      }
      vim.fn.setqflist({ qf_entry }, 'a')
    end
  end
  local log_err = function(str)
    logfun(str, vim.log.levels.ERROR)
    error(str)
  end
  obj.log = logfun
  obj.log_err = log_err
  return obj
end

-- return log
-- pass config-value to log.new()?
return log.new({})
