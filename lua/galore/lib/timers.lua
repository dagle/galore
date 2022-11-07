local uv = vim.loop
local ok, notify = pcall(require, 'notify')

local M = {}

if not ok then
  --- log this
  vim.api.nvim_err_writeln("Can't find nvim-notify, will try to fallback")
  notify = vim.notify
end

local function default_opts(opts)
  opts.title = opts.title or 'Timer running'
  opts.stop_title = opts.stop_title or 'Timer stopped'
  opts.done_msg = opts.done_msg or 'Timer hit 0!'
  opts.tick = 1000
  opts.time_to_level = opts.time_to_level or function()
    return vim.log.levels.INFO
  end
end

local function time_to_str(time)
  local seconds = math.floor(time / 1000)
  local min = math.floor(seconds / 60)
  local hours = math.floor(min / 60)
  min = min - hours * 60
  seconds = seconds - min * 60
  if hours ~= 0 then
    return string.format('%d:%d:%d', hours, min, seconds)
  end
  if min ~= 0 then
    return string.format('%d:%d', min, seconds)
  end
  return string.format('%d', seconds)
end

--- Creates a popup_timer
--- @param time integer how long we should run the timer
--- @param rep integer not used atm
--- @param callback function()
--- @param opts table timer costumization
function M.popup_timer(time, rep, callback, opts)
  opts = opts or {}
  default_opts(opts)
  local id = notify(time_to_str(time), vim.log.levels.INFO, {
    title = opts.title,
    render = opts.render,
    timeout = opts.tick + 1000,
  })
  local timer = uv.new_timer()
  timer:start(
    opts.tick,
    opts.tick,
    vim.schedule_wrap(function()
      time = time - opts.tick
      if time <= 0 then
        timer:stop()
        notify(opts.done_msg, vim.log.levels.INFO, {
          title = opts.stop_title,
          replace = id,
          timeout = opts.timeout,
        })
        callback()
        -- if rep > 0 then
        -- 	M.popup_timer(rep, rep, callback, opts)
        -- end
        return
      end
      id = notify(time_to_str(time), opts.time_to_level(time), {
        title = opts.title,
        replace = id,
        timeout = opts.tick + 1000,
      })
    end)
  )
  return timer
end

return M
