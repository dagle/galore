local ok, _ = pcall(require, "telescope")
if not ok then
	error("You need to install telescope to use this module")
	return
end

local pickers = require("telescope.pickers")
local teleconf = require("telescope.config").values
local previewers = require("telescope.previewers")
local compose = require("galore.compose")
local actions = require("telescope.actions")
local putils = require("telescope.previewers.utils")
local finders = require("telescope.finders")
local action_state = require("telescope.actions.state")
local action_set = require("telescope.actions.set")

local r = require("galore.render")
local gm = require("galore.gmime")
local gu = require("galore.gmime-util")
local nm = require("galore.notmuch")
local conf = require("galore.config")
local message_view = require("galore.message_view")
local ts_utils = require "telescope.utils"
local strings = require "plenary.strings"


local M = {}

-- parses the tree and outputs the parts
-- this should use select
-- XXX todo, a bit over the top atm
-- M.parts_browser = function (message)
-- -- function M.show_part(part, buf, opts, state)
-- 	if gm.is_message_part(part) then
-- 		local message = gm.get_message(part)
-- 		-- do we want to show that it's a new message?
-- 		-- show_message_helper(message, buf, opts, state)
-- 	elseif gm.is_partial(part) then
-- 		local full = gm.partial_collect(part)
-- 		-- do we want to show that it's a collected message?
-- 		-- show_message_helper(full, buf, opts, state)
-- 	elseif gm.is_part(part) then
-- 		-- if gm.is_attachment(part) then
-- 		if gm.get_disposition(part) == "attachment" then
-- 			local ppart = ffi.cast("GMimePart *", part)
-- 			local filename = gm.part_filename(ppart)
-- 			-- M.parts[filename] = ppart
-- 			local str = "- [ " .. filename .. " ]"
-- 			-- M.draw(buf, {str})
--
-- 			-- -- local str = gm.print_part(part)
-- 			-- -- v.nvim_buf_set_lines(0, -1, -1, true, split_lines(str))
-- 		else
-- 			-- should contain more stuff
-- 			-- should push some filetypes into attachments
-- 			local ct = gm.get_content_type(part)
-- 			local type = gm.get_mime_type(ct)
-- 			if type == "text/plain" then
-- 			elseif type == "text/html" then
-- 			end
-- 		end
-- 	elseif gm.is_multipart(part) then
-- 		if gm.is_multipart_encrypted(part) then
-- 			-- display as "encrypted part, until it's decrypted, then refresh the renderer"
-- 			-- local de_part, sign = gm.decrypt_and_verify(part)
-- 			return
-- 		elseif gm.is_multipart_signed(part) then
-- 			-- maybe apply some colors etc if the sign is correct or not
-- 			-- if gm.verify_signed(part) then
-- 				-- table.insert(state.parts, "--- sign confirmed! ---")
-- 			-- end
-- 			local se_part = gm.get_signed_part(part)
-- 			return
-- 		elseif gm.is_multipart_alt(part) then
-- 			local multi = ffi.cast("GMimeMultipart *", part)
-- 			local i = 0
-- 			local j = gm.multipart_len(multi)
-- 			while i < j do
-- 				local child = gm.multipart_child(multi, i)
-- 				M.show_part(child, buf, opts, state)
-- 				i = i + 1
-- 			end
--         else
-- 			local multi = ffi.cast("GMimeMultipart *", part)
-- 			local i = 0
-- 			local j = gm.multipart_len(multi)
-- 			-- for i = 0, j-1 do
-- 			-- end
-- 			while i < j do
-- 				local child = gm.multipart_child(multi, i)
-- 				M.show_part(child, buf, opts, state)
-- 				i = i + 1
-- 			end
-- 		end
-- 	end
-- 	vim.ui.select(items: table, opts: table, on_choice: function)
-- end

local notmuch_picker = function(opts)
	-- local db_path = conf.values.db_path
	local data = {}
	local search = opts.search or ""
	-- local db = nm.db_open(db_path, 0)
	local db = conf.values.db
	local query = nm.create_query(db, search)
	for m in nm.query_get_messages(query) do
		local display = nm.message_get_header(m, "Subject")
		local filename = nm.message_get_filename(m)
		-- table.insert(data, {filename, display})
		table.insert(data, { filename, display })
	end
	return query,
		finders.new_table({
			results = data,
			entry_maker = function(entry)
				return {
					value = entry[1],
					display = entry[2],
					ordinal = entry[2],
				}
			end,
		})
end

local function type_to_kind(type)
	local mode = "replace"
	if type == "default" then
		mode = "replace"
	elseif type == "horizontal" then
		mode = "split"
	elseif type == "vertical" then
		mode = "vsplit"
	elseif type == "tabedit" then
		mode = "tab"
	end
	return mode
end

local function open_path(bufnr, type, path, fun)
	local message = gm.parse_message(path)
	actions.close(bufnr)
	local mode = type_to_kind(type)

	fun(mode, message)
end

local function load_draft(kind, message)
	local ref = gu.get_ref(message)
	compose.create(kind, message, ref)
end

local function load_compose(kind, message)
	local ref = gu.make_ref(message)
	compose.create(kind, message, ref)
end

local function open_draft(bufnr, type)
	local entry = action_state.get_selected_entry()
	local path = entry.value
	open_path(bufnr, type, path, load_draft)
end

local function compose_search(bufnr, type)
	local entry = action_state.get_selected_entry()
	open_path(bufnr, type, entry.value.filename, load_compose)
end

local function open_search(bufnr, type)
	local entry = action_state.get_selected_entry()
	actions.close(bufnr)
	local mode = type_to_kind(type)
	message_view.create(entry.value.filename, mode)
end

-- XXX honor opts
local function entry_maker(opts)
	return function(entry)
		local data = vim.fn.json_decode(entry)
		return {
			value = data,
			display = data.subject,
			ordinal = data.subject, -- this is bad
		}
	end
end

-- Something like like this.
-- Should take a hight because not all of the
-- email might be encrypted etc
local function encrypted(buf, winid, message)
  local height = vim.api.nvim_win_get_height(winid)
  local width = vim.api.nvim_win_get_width(winid)
  local fillchar = "╱"
   vim.api.nvim_buf_set_lines(
    buf,
    -1,
    -1,
    false,
    ts_utils.repeated_table(height, table.concat(ts_utils.repeated_table(width, fillchar), ""))
  )
  local anon_ns = vim.api.nvim_create_namespace ""
  local padding = table.concat(ts_utils.repeated_table(#message + 4, " "), "")
  local lines = {
    padding,
    "  " .. message .. "  ",
    padding,
  }
  vim.api.nvim_buf_set_extmark(
    buf,
    anon_ns,
    0,
    0,
    { end_line = height, hl_group = "TelescopePreviewMessageFillchar" }
  )
  local col = math.floor((width - strings.strdisplaywidth(lines[2])) / 2)
  for i, line in ipairs(lines) do
    vim.api.nvim_buf_set_extmark(
      buf,
      anon_ns,
      math.floor(height / 2) - 1 + i,
      0,
      { virt_text = { { line, "TelescopePreviewMessage" } }, virt_text_pos = "overlay", virt_text_win_col = col }
    )
  end
  --
end

local function mime_preview(buf, winid, path)
	local message = gm.parse_message(path)
	r.show_header(message, buf, nil, nil)
	r.show_message(message, buf, {preview = function (bufid, str)
		encrypted(bufid, winid, str)
	end})
	putils.highlighter(buf, "mail")
end

M.notmuch_search = function(opts)
	opts = opts or {}
	local live_notmucher = finders.new_job(function(prompt)
		if not prompt or prompt == "" then
			return nil
		end
		if opts.presearch then
			prompt = opts.presearch .. " and " .. prompt
		end

		return vim.tbl_flatten({ "nm-livesearch", "message", prompt })
	end, entry_maker(opts), opts.max_results, opts.cwd)

	pickers.new(opts, {
		prompt_title = "Notmuch search",
		results_title = "Notmuch match",
		finder = live_notmucher,
		previewer = previewers.new_buffer_previewer({
			title = opts.preview_title or "Notmuch preview",
			keep_last_buf = false,
			define_preview = function(self, entry, status)
				local filename = entry.value.filename
				mime_preview(self.state.bufnr, self.state.winid, filename)
			end,
		}),
		attach_mappings = function()
			-- action_set.select:replace(compose_search)
			action_set.select:replace(open_search)
			return true
		end,
	}):find()
end

local search_builder = function(opts)
	opts = opts or {}
	local q, picker = notmuch_picker(opts)
	pickers.new(opts, {
		prompt_title = "Notmuch search",
		results_title = "Notmuch match",
		-- finder = notmuch_picker(opts),
		finder = picker,
		previewer = previewers.new_buffer_previewer({
			title = opts.preview_title or "Notmuch preview",
			keep_last_buf = true,
			define_preview = opts.preview or function(self, entry, status)
				local filename = entry.value
				mime_preview(self.state.bufnr, filename)
			end,
		}),
		attach_mappings = function()
			action_set.select:replace(open_draft)
			return true
		end,
	}):find()
	nm.query_destroy(q)
end

M.load_draft = function(opts)
	opts = opts or {}
	local search = opts.search or ""
	opts.search = search .. "tag:draft"
	opts.prompt_title = "Load draft"
	opts.results_title = "Drafts"
	opts.preview_title = "Draft preview"
	-- opts.preview = function (self, entry, status)
	-- 	local filename = entry.value
	-- 	mime_preview(self.state.bufnr, filename)
	-- end
	search_builder(opts)
end

M.attach_file = function(opts)
	opts = opts or {}
	opts.prompt_title = "Attach file"
	-- is this even the best way? works now tm
	opts.attach_mappings = function(prompt_bufnr, _)
		action_set.select:replace_if(function()
			local entry = action_state.get_selected_entry()
			local ret = entry and not entry.Path:is_dir()
			return ret
		end, function()
			actions.close(prompt_bufnr)
			local file = action_state.get_selected_entry().path
			compose.add_attachment(file)
		end)
		return true
	end
	require("telescope").extensions.file_browser.file_browser(opts)
end
return M
