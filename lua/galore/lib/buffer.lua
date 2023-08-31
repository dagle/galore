--- @class Buffer
--- @field handle integer
local Buffer = {}

function Buffer:new(this)
  this = this or {}
  self.__index = self
  setmetatable(this, self)

  return this
end

function Buffer:focus()
  local windows = vim.fn.win_findbuf(self.handle)

  if #windows == 0 or not windows then
    vim.api.nvim_win_set_buf(0, self.handle)
    return
  end

  vim.fn.win_gotoid(windows[1])
end

function Buffer:lock()
  self:set_option("readonly", true)
  self:set_option("modifiable", false)
end

function Buffer:unlock()
  self:set_option("readonly", false)
  self:set_option("modifiable", true)
end

function Buffer:is_open()
  return #vim.fn.win_findbuf(self.handle) ~= 0
end

function Buffer:clear()
  vim.api.nvim_buf_set_lines(self.handle, 0, -1, false, {})
end

function Buffer:set_parent(parent)
  self.parent = parent
end

function Buffer:add_timer(timer)
  if self.timers == nil then
    self.timers = {}
  end
  table.insert(self.timers, timer)
end

function Buffer:stop_timers()
  for _, timer in ipairs(self.timers) do
    timer:stop()
  end
  -- free timers so we don't have backpointers etc
  self.timers = {}
end

local function cleanup(self)
  if self.cleanup then
    self:cleanup()
  end
  self.timers = {}
  self.parent = nil
end

-- split up this and add a callback handler for when the buffer is deleted
function Buffer:close(delete)
  local bufwins = #vim.fn.win_findbuf(self.handle)

  local floating = vim.api.nvim_win_get_config(0).zindex

  if floating then
    vim.api.nvim_win_close(0, true)
    if self.parent then
      self.parent:focus()
    end
  elseif self.kind == "replace" and self.parent then
    if self.parent.handle and vim.fn.bufexists(self.parent.handle) ~= 0 then
      vim.api.nvim_win_set_buf(0, self.parent.handle)
    end
  -- elseif self.kind == "floating" then
  -- 	vim.api.nvim_win_close(0, true)
  -- 	if self.parent then
  -- 		self.parent:focus()
  -- 	end
  else
    if self.parent then
      self.parent:focus()
    end
  end
  if delete and bufwins <= 1 then
    if self.runner then
      self.runner.close()
    end
    if self.timers then
      self:stop_timers()
    end
    cleanup(self)
    vim.api.nvim_buf_delete(self.handle, {})
  end
end

function Buffer:get_lines(first, last, strict)
  return vim.api.nvim_buf_get_lines(self.handle, first, last, strict)
end

function Buffer:get_line(line)
  return vim.fn.getbufline(self.handle, line)
end

function Buffer:get_current_line()
  return self:get_line(vim.fn.getpos(".")[2])
end

function Buffer:set_lines(first, last, strict, lines)
  vim.api.nvim_buf_set_lines(self.handle, first, last, strict, lines)
end

function Buffer:set_text(first_line, last_line, first_col, last_col, lines)
  vim.api.nvim_buf_set_text(self.handle, first_line, first_col, last_line, last_col, lines)
end

function Buffer:move_cursor(line)
  if line < 0 then
    self:focus()
    vim.cmd "norm G"
  else
    self:focus()
    vim.cmd("norm " .. line .. "G")
  end
end

function Buffer:is_valid()
  return vim.api.nvim_buf_is_valid(self.handle)
end

function Buffer:put(lines, after, follow)
  self:focus()
  vim.api.nvim_put(lines, "l", after, follow)
end

function Buffer:create_fold(first, last)
  vim.cmd(string.format("%d,%dfold", first, last))
  vim.cmd(string.format("%d,%dfoldopen", first, last))
end

function Buffer:get_option(name)
  vim.api.nvim_buf_get_option(self.handle, name)
end

function Buffer:set_option(name, value)
  vim.api.nvim_buf_set_option(self.handle, name, value)
end

function Buffer:set_name(name)
  vim.api.nvim_buf_set_name(self.handle, name)
end

function Buffer:set_foldlevel(level)
  local windows = vim.fn.win_findbuf(self.handle)
  vim.api.nvim_win_set_option(0, "foldlevel", level)
end

function Buffer:replace_content_with(lines)
  self:set_lines(0, -1, false, lines)
end

function Buffer:open_fold(line, reset_pos)
  local pos
  if reset_pos == true then
    pos = vim.fn.getpos()
  end

  vim.fn.setpos(".", { self.handle, line, 0, 0 })
  vim.cmd "normal zo"

  if reset_pos == true then
    vim.fn.setpos(".", pos)
  end
end

-- remove?
function Buffer:set_ns(name)
  self.ns = vim.api.nvim_create_namespace(name)
end

function Buffer:add_highlight(line, col_start, col_end, name)
  local ns_id = self.ns or 0
  vim.api.nvim_buf_add_highlight(self.handle, ns_id, name, line, col_start, col_end)
end

function Buffer:unplace_sign(id)
  vim.cmd("sign unplace " .. id)
end

function Buffer:place_sign(line, name, group, id)
  -- Sign IDs should be unique within a group, however there's no downside as
  -- long as we don't want to uniquely identify the placed sign later. Thus,
  -- we leave the choice to the caller
  local sign_id = id or 1

  -- There's an equivalent function sign_place() which can automatically use
  -- a free ID, but is considerable slower, so we use the command for now
  local cmd = "sign place " .. sign_id .. " line=" .. line .. " name=" .. name
  if group ~= nil then
    cmd = cmd .. " group=" .. group
  end
  cmd = cmd .. " buffer=" .. self.handle

  vim.cmd(cmd)
  return sign_id
end

function Buffer:get_sign_at_line(line, group)
  group = group or "*"
  return vim.fn.sign_getplaced(self.handle, {
    group = group,
    lnum = line,
  })[1]
end

function Buffer:clear_sign_group(group)
  vim.cmd("sign unplace * group=" .. group .. " buffer=" .. self.handle)
end

function Buffer:set_filetype(ft)
  self:set_option("filetype", ft)
end

function Buffer:call(f)
  vim.api.nvim_buf_call(self.handle, f)
end

function Buffer.exists(name)
  return vim.fn.bufnr(name) ~= -1
end

function Buffer:set_extmark(...)
  return vim.api.nvim_buf_set_extmark(self.handle, ...)
end

function Buffer:get_extmark(ns, id)
  return vim.api.nvim_buf_get_extmark_by_id(self.handle, ns, id, { details = true })
end

function Buffer:del_extmark(ns, id)
  return vim.api.nvim_buf_del_extmark(self.handle, ns, id)
end

local function buf_exist(name)
  if vim.fn.bufexists(name) ~= 0 then
    local buf = vim.fn.bufnr(name)
    vim.api.nvim_win_set_buf(0, buf)
    return true
  end
end

--- @return any
function Buffer.create(config, class)
  config = config or {}

  --- kind should be mods!
  -- local kind = config.kind or 'replace'
  local kind = "default"

  if config.kind and config.kind ~= "" then
    kind = config.kind
  end

  local buffer = nil
  class = class or Buffer

  if kind == "default" then
    if buf_exist(config.name) then
      return
    end
    vim.cmd "enew"
    buffer = class:new { handle = vim.api.nvim_get_current_buf() }
  elseif kind == "floating" then
    -- Creates the border window
    -- TODO maybe do something fancy, like checking if we
    -- there are more floating windows shift the windows
    local vim_height = vim.api.nvim_eval [[&lines]]
    local vim_width = vim.api.nvim_eval [[&columns]]
    local width = math.floor(vim_width * 0.8) + 5
    local height = math.floor(vim_height * 0.7) + 2
    local col = vim_width * 0.1 - 2
    local row = vim_height * 0.15 - 1

    local content_buffer
    local inited = false
    if vim.fn.bufexists(config.name) ~= 0 then
      content_buffer = vim.fn.bufnr(config.name)
      inited = true
    else
      vim.cmd "tabnew"
      if buf_exist(config.name) then
        return
      end
      buffer = class:new { handle = vim.api.nvim_get_current_buf() }
      content_buffer = vim.api.nvim_create_buf(true, true)
    end

    local content_window = vim.api.nvim_open_win(content_buffer, true, {
      relative = "editor",
      width = width,
      height = height,
      col = col,
      row = row,
      style = "minimal",
      focusable = false,
      border = "single",
    })

    buffer = class:new { handle = content_buffer }
    if inited then
      return
    end
    vim.wo.winhl = "Normal:Normal"
    vim.api.nvim_win_set_cursor(content_window, { 1, 0 })
  else
    local split = string.format("%s new", kind)
    vim.cmd(split)
    if buf_exist(config.name) then
      return
    end
    buffer = class:new { handle = vim.api.nvim_get_current_buf() }
  end

  buffer.kind = kind
  buffer.parent = config.parent
  buffer.cleanup = config.cleanup
  buffer.update = config.update

  vim.wo.nu = false
  vim.wo.rnu = false

  if config.name then
    buffer:set_name(config.name)
  end

  --- this should be configurable?
  buffer:set_option("buflisted", config.buflisted or false)
  buffer:set_option("bufhidden", config.bufhidden or "hide")
  buffer:set_option("buftype", config.buftype or "nofile")
  buffer:set_option("swapfile", false)
  buffer:set_option("fileencoding", "utf-8")
  buffer:set_option("fileformat", "unix")

  -- don't want to do it like this
  vim.api.nvim_win_set_option(0, "wrap", false)

  if config.ft then
    buffer:set_filetype(config.ft)
  end

  local mapopts = { noremap = true, silent = true, buffer = buffer.handle }
  if config.mappings then
    for mode, val in pairs(config.mappings) do
      for key, cb in pairs(val) do
        local opts = mapopts
        if type(cb) == "table" then
          opts = vim.tbl_extend("keep", cb, mapopts)
          opts.rhs = nil
          cb = cb.rhs
        end
        local cbfunc = function()
          cb(buffer)
        end
        vim.keymap.set(mode, key, cbfunc, opts)
      end
    end
  else
    local conf = require "galore.config"
    for mode, val in pairs(conf.values.key_bindings.default) do
      for key, cb in pairs(val) do
        local cbfunc = function()
          cb(buffer)
        end
        vim.keymap.set(mode, key, cbfunc, mapopts)
      end
    end
  end

  if config.init then
    config.init(buffer)
  end

  if config.cursor == "top" then
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
  end

  --- add globals
  vim.api.nvim_buf_create_user_command(buffer.handle, "Galore", function(line)
    local cmd = buffer.Commands[line.fargs[1]]

    if cmd then
      cmd.fun(buffer, line)
    end
  end, {
    nargs = "*",
    complete = function(_, line, _)
      if buffer.Commands then
        local l = vim.split(line, "%s+")
        local i
        local n

        for j, v in ipairs(l) do
          if v == "Galore" then
            n = #l - j - 1
            i = j
            break
          end
        end

        if n == 0 then
          local keys = vim.tbl_keys(buffer.Commands)
          return vim.tbl_filter(function(val)
            return vim.startswith(val, l[i + 1])
          end, keys)
        end
        if n > 0 then
          local cmd = buffer.Commands[l[i + 1]]

          if cmd.cmp and cmd.cmp[n] then
            local comp = cmd.cmp[n](buffer)
            return vim.tbl_filter(function(val)
              return vim.startswith(val, l[#l])
            end, comp)
          end
        end
      end
    end,
  })

  -- if config.autocmds then
  -- 	-- vim.api.nvim_create_augroup("") -- unique id?
  -- 	for event, cb in pairs(config.autocmds) do
  -- 		local cbfunc = function ()
  -- 			cb(buffer)
  -- 		end
  -- 		vim.api.nvim_create_autocmd(event, {callback = cbfunc, buffer = buffer.handle})
  -- 	end
  -- end
  vim.api.nvim_create_autocmd("BufDelete", {
    callback = function()
      -- buffer_delete(buffer.handle)
    end,
    buffer = buffer.handle,
  })

  -- if not config.modifiable then
  -- 	buffer:set_option("modifiable", false)
  -- end

  if config.readonly ~= nil and config.readonly then
    buffer:set_option("readonly", true)
  end
  vim.b.galorebuf = function()
    return buffer
  end

  return buffer
end

return Buffer
