local r = require('galore.render')
local u = require('galore.util')
local Buffer = require('galore.lib.buffer')
local nu = require('galore.notmuch-util')
-- local nm = require("galore.notmuch")
local nm = require('notmuch')
local ui = require('galore.ui')
local runtime = require('galore.runtime')
local o = require('galore.opts')
local gu = require('galore.gmime-util')

local Thread = Buffer:new()

function Thread:update(tid)
  self:unlock()
  self:clear()
  self.thread_parts = {}
  self.states = {}
  self.lines = {}

  runtime.with_db(function(db)
    local query = nm.create_query(db, 'thread:' .. tid)
    nm.query_set_sort(query, self.opts.sort)
    local i = 1
    local tot = nm.query_count_messages(query)
    for nm_message in nm.query_get_messages(query) do
      local message_start = vim.fn.line('$')

      local line = nu.get_message(nm_message)
      line.total = tot
      line.index = i

      local message = gu.parse_message(line.filenames[1])

      local buffer = {}
      r.show_headers(message, self.handle, { ns = self.ns }, line, message_start)
      local body = vim.fn.line('$')
      local state = r.render_message(r.default_render, message, buffer, {
        offset = body - 1,
        keys = line.keys,
      })
      table.insert(self.states, state)
      table.insert(self.lines, line)
      u.purge_empty(buffer)
      self:set_lines(-1, -1, true, buffer)
      local message_stop = vim.fn.line('$')
      if not vim.tbl_isempty(state.attachments) then
        ui.render_attachments(state.attachments, message_stop - 1, self.handle, self.ns)
      end
      table.insert(
        self.thread_parts,
        { start = message_start, stop = message_stop, body = body, mid = line.id }
      )
      i = i + 1
    end
    self:set_lines(0, 1, true, {})
    -- vim.schedule(function ()
    -- 	for idx, state in ipairs(self.states) do
    -- 		for _, cb in ipairs(state.callbacks) do
    -- 			cb(self.handle, self.ns)
    -- 		end
    -- 		self.states[idx] = nil
    -- 	end
    -- end)
  end)

  self:lock()
end

function Thread:with_all_attachments(func, ...)
  local attachments = {}
  for _, state in ipairs(self.states) do
    vim.list_extend(attachments, state.attachments)
  end
  func(attachments, ...)
end

function Thread:with_selected_attachments(func, ...)
  local _, i = self:get_selected()
  local attachments = self.states[i].attachments
  func(attachments, ...)
end

function Thread:get_selected()
  local line = unpack(vim.api.nvim_win_get_cursor(0))
  line = line + 1
  for i, m in ipairs(self.thread_parts) do
    if m.start <= line and m.stop >= line then
      return m.mid, i
    end
  end
end

function Thread:message_view()
  local mid = self:get_selected()
  local mw = require('galore.message_view')
  local opts = o.bufcopy(self.opts)
  mw:create(mid, opts)
end

function Thread:redraw(line)
  self:focus()
  self:update(line)
end

function Thread:set(i)
  local _, col = unpack(vim.api.nvim_win_get_cursor(0))
  for j, m in ipairs(self.thread_parts) do
    if i == j then
      vim.api.nvim_win_set_cursor(0, { m.start, col })
    end
  end
end

function Thread:next()
  local found = false
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  for _, m in ipairs(self.thread_parts) do
    if m.start <= line and m.stop >= line then
      vim.api.nvim_win_set_cursor(0, { m.start, col })
      found = true
    elseif found then
      vim.api.nvim_win_set_cursor(0, { m.start, col })
      return
    end
  end
end

function Thread:prev()
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  for i, m in ipairs(self.thread_parts) do
    if m and m.start <= line and m.stop >= line then
      vim.api.nvim_win_set_cursor(0, { m.start, col })
      return
    end
  end
end

-- local function verify_signatures(self)
-- 	local state = {}
-- 	local function verify(_, part, _)
-- 		if gp.is_multipart_signed(part) then
-- 			local verified = gcu.verify_signed(part)
-- 			if state.verified == nil then
-- 				state.verified = verified
-- 			end
-- 			state.verified = state.verified and verified
-- 		end
-- 	end
-- 	if not self.message then
-- 		return
-- 	end
-- 	gp.message_foreach_dfs(self.message, verify)
-- 	return state.verified or state.verified == nil
-- end

function Thread:commands()
  -- vim.api.nvim_buf_create_user_command(self.handle, "GaloreSaveAttachment", function (args)
  -- 	if args.fargs then
  -- 		local save_path = "."
  -- 		if #args.fargs > 2 then
  -- 			save_path = args.fargs[2]
  -- 		end
  -- 		save_attachment(self.state.attachments, args.fargs[1], save_path)
  -- 	end
  -- end, {
  -- nargs = "*",
  -- complete = function ()
  -- 	local files = {}
  -- 	for _, v in ipairs(self.state.attachments) do
  -- 		table.insert(files, v.filename)
  -- 	end
  -- 	return files
  -- end,
  -- })
  -- vim.api.nvim_buf_create_user_command(self.handle, "GaloreVerify", function ()
  -- 	print(verify_signatures(self))
  -- end, {
  -- })
end

function Thread:create(tid, opts)
  o.thread_view_options(opts)
  Buffer.create({
    name = opts.bufname(tid),
    ft = 'mail',
    kind = opts.kind,
    parent = opts.parent,
    mappings = opts.key_bindings,
    init = function(buffer)
      buffer.opts = opts
      buffer.vline = opts.vline
      buffer.ns = vim.api.nvim_create_namespace('galore-thread-view')
      buffer.dians = vim.api.nvim_create_namespace('galore-dia')
      -- mark_read(buffer, opts.parent, line, opts.vline)
      buffer:update(tid)
      buffer:commands()
      buffer:set(opts.index)
      opts.init(buffer)
    end,
  }, Thread)
end

function Thread.open_attach() end

return Thread
