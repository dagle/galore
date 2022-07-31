local ok, _ = pcall(require, "telescope")
if not ok then
	error("You need to install telescope to use this module")
	return
end
local pickers = require("telescope.pickers")
local previewers = require("telescope.previewers")
local actions = require("telescope.actions")
local putils = require("telescope.previewers.utils")
local finders = require("telescope.finders")
local action_state = require("telescope.actions.state")
local action_set = require("telescope.actions.set")
local compose = require("galore.compose")
local config = require("galore.config")

local r = require("galore.render")
local gu = require("galore.gmime.util")
local message_view = require("galore.message_view")
local ts_utils = require "telescope.utils"
local strings = require "plenary.strings"
local gp = require("galore.gmime.parts")
local gc = require("galore.gmime.content")
local go = require("galore.gmime.object")
local ffi = require("ffi")
local runtime = require("galore.runtime")
local nm = require("galore.notmuch")
local nu = require("galore.notmuch-util")
local fb_utils = require "telescope._extensions.file_browser.utils"
local scan = require "plenary.scandir"
local Path = require "plenary.path"

local Telescope = {}

local function show_tree(object)
	if gp.is_message_part(object) then
		return "message-part"
	elseif gp.is_partial(object) then
		return "partial"
	elseif gp.is_part(object) then
		local part = ffi.cast("GMimePart *", object)
		if gp.part_is_attachment(part) then
			return gu.part_mime_type(object)
		end
		return "part"
	elseif gp.is_multipart_encrypted(object) then
		return "encrypted mulitpart"
	elseif gp.is_multipart_signed(object) then
		return "signed mulitpart"
	elseif gp.is_multipart(object) then
		return "mulitpart"
	end
end

local function browser_fun(parent, part, level, state)
	local strbuf = {}
	for _ = 1, level-1 do
		table.insert(strbuf, "\t")
	end
	table.insert(strbuf, show_tree(part))
	local str = table.concat(strbuf)
	table.insert(state.select, str)
	table.insert(state.part, part)
end

function Telescope.parts_browser(message, selected)
	local state = {}
	state.select = {}
	state.part = {}
	gp.message_foreach_dfs(message, browser_fun, state)
	vim.ui.select(state.select, {}, function (_, idx)
		if selected then
			selected(state.part[idx])
		end
	end)
end

local function type_to_kind(type)
	local mode
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

-- Doesn't support multifile?
local function open_path(bufnr, type, path, fun)
	local message = gu.parse_message(path)
	actions.close(bufnr)
	local mode = type_to_kind(type)

	fun(mode, message)
end

local function load_draft(kind, message)
	local ref = gu.get_ref(message)
	compose:create(kind, message, {ref})
end

local function load_compose(kind, message)
	local ref = gu.make_ref(message)
	compose:create(kind, message, {ref}, {response_mode = true})
end

--- should use filenames
local function open_draft(bufnr, type)
	local entry = action_state.get_selected_entry()
	local path = entry.value.filename
	open_path(bufnr, type, path, load_draft)
end

function Telescope.compose_search(bufnr, type)
	local entry = action_state.get_selected_entry()
	open_path(bufnr, type, entry.value.filename, load_compose)
end

local function open_search(bufnr, type)
	local entry = action_state.get_selected_entry()
	actions.close(bufnr)
	local mode = type_to_kind(type)
	message_view:create(entry.value, {kind=mode})
end

function Telescope.create_search(browser, bufnr, type, parent)
	type = type_to_kind(type) or "split"
	local search = action_state.get_current_line()
	actions.close(bufnr)
	browser:create(search, type, parent)
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

local function entry_maker()
	return function(entry)
		local data = vim.fn.json_decode(entry)
		if data == nil then
			return
		end
		return {
			value = data,
			display = data.subject,
			ordinal = data.subject, -- this is bad
		}
	end
end


local function mime_preview(buf, winid, path)
	if path and path ~= "" then
		local message = gu.parse_message(path)
		r.show_headers(message, buf, nil, nil)
		r.show_message(message, buf, {preview = function (bufid, str)
			encrypted(bufid, winid, str)
		end})
		putils.highlighter(buf, "mail")
	end
end

Telescope.notmuch_search = function(opts)
	opts = opts or {}
	local live_notmucher = finders.new_job(function(prompt)
		if opts.presearch then
			if not prompt or prompt == "" then
				prompt = opts.presearch
			else
				prompt = opts.presearch .. " and " .. prompt
			end
		end
		if not prompt or prompt == "" and not opts.search_group then
			return nil
		end
		local group = opts.search_group or "message"
		local ret =  vim.tbl_flatten({ "nm-livesearch", group, prompt})
		return ret
	end, entry_maker(), opts.max_results, opts.cwd)

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
		attach_mappings = function(buf, map)
			action_set.select:replace(open_search)
			for mode, binds in pairs(config.values.key_bindings.telescope) do
				for key, func in pairs(binds) do
					local function telecb()
						func(buf)
					end
					map(mode, key, telecb)
				end
			end
			return true
		end,
	}):find()
end

Telescope.load_draft = function(opts)
	opts = opts or {}
	-- local search = opts.search or ""
	opts.default_text = "tag:draft"
	opts.prompt_title = "Load draft"
	opts.results_title = "Drafts"
	opts.preview_title = "Draft preview"
	opts.attach_mappings = function ()
			action_set.select:replace(open_draft)
			return true
	end
	Telescope.notmuch_search(opts)
end

local function make_tag(message)
	local subject = go.object_get_header(ffi.cast("GMimeObject *", message), "Subject") or ""
	local from = {vim.fn.bufnr('%'), vim.fn.line('.'), vim.fn.col('.'), 0}
	return {{tagname=subject, from=from}}
end

function Telescope.get_header(message, header)
	local refs = go.object_get_header(ffi.cast("GMimeObject *", message), header)
	if refs == nil then
		vim.notify("No " .. header)
		return
	end
	return refs
end

function Telescope.goto_tree(message_id, opts)
	opts = opts or {}
	opts.presearch = string.format("thread:{mid:%s}", message_id)
	opts.prompt_title = "Load Message Tree"
	opts.results_title = "Message"
	opts.preview_title = "Message Preview"
	Telescope.notmuch_search(opts)
end

--- go to all emails before this one
function Telescope.goto_reference(refs, opts)
	if refs == nil then
		vim.notify("No reference")
		return
	end
	opts = opts or {}
	local search = opts.search or ""
	local buf = {}
	for ref in gc.reference_iter_str(refs) do
		table.insert(buf, "mid:" .. ref)
	end
	opts.presearch = search .. table.concat(buf, " or ")
	opts.prompt_title = "Load Reference"
	opts.results_title = "Message"
	opts.preview_title = "Message Preview"
	Telescope.notmuch_search(opts)
end

--- goto all emails after this one
function Telescope.goto_references(message_id, opts)
	opts = opts or {}
	opts.search_group = {"message-after", message_id}
	opts.prompt_title = "Load References"
	opts.results_title = "Message"
	opts.preview_title = "Message Preview"
	Telescope.notmuch_search(opts)
end

local function goto_message(mv, id)
	local line
	runtime.with_db(function (db)
		local message = nm.db_find_message(db, id)
		line = nu.get_message(message)
	end)

	local items = make_tag(mv.message)
	vim.fn.settagstack(vim.fn.win_getid(), {items=items}, 't')
	message_view:create(line, {kind="replace", parent=mv.parent})
end

function Telescope.goto_message(mv)
	if not mv.message then
		return
	end
	local mid = gp.message_get_message_id(mv.message)
	goto_message(mv, mid)
end

function Telescope.goto_parent(mv)
	if not mv.message then
		return
	end
	local ref = go.object_get_header(ffi.cast("GMimeObject *", mv.message), "In-Reply-To")
	if ref == nil then
		vim.notify("No parent")
		return
	end
	local mid = gc.utils_decode_message_id(ref)
	goto_message(mv, mid)
end

Telescope.attach_file = function(comp, opts)
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
			comp:add_attachment(file)
		end)
		return true
	end
	require("telescope").extensions.file_browser.file_browser(opts)
end


--- set file-ending/filename as a hint somehow?

--- We need a binding:
--- To get the current line, even if we have a match
--- A binding to select the current directory
Telescope.save_file = function (part, opts)
	opts = opts or {}
	opts.prompt_title = "Save file"
	opts.attach_mappings = function(prompt_bufnr, _)
		actions.select_default:replace(function()
			local entry = action_state.get_selected_entry()
			if entry and entry.Path:is_dir() then
				local current_picker = action_state.get_current_picker(prompt_bufnr)
				local finder = current_picker.finder
				local entry = action_state.get_selected_entry()
				local path = vim.loop.fs_realpath(entry.path)

				if finder.files and finder.collapse_dirs then
					local upwards = path == Path:new(finder.path):parent():absolute()
					while true do
						local dirs = scan.scan_dir(path, { add_dirs = true, depth = 1, hidden = true })
						if #dirs == 1 and vim.fn.isdirectory(dirs[1]) then
							path = upwards and Path:new(path):parent():absolute() or dirs[1]
							-- make sure it's upper bound (#dirs == 1 implicitly reflects lower bound)
							if path == Path:new(path):parent():absolute() then
								break
							end
						else
							break
						end
					end
				end

				finder.files = true
				finder.path = path
				fb_utils.redraw_border_title(current_picker)
				current_picker:refresh(finder, { reset_prompt = true, multi = current_picker._multi })
			else
				actions.close(prompt_bufnr)
				local selected = action_state.get_selected_entry()
				local file
				if selected then
					file = selected.path
				else
					--- add path to it
					file = action_state.get_current_line()
				end
				gu.save_part(part, file)
				-- local search = action_state.get_current_line()
			end
		end)
		return true
	end
	require("telescope").extensions.file_browser.file_browser(opts)
end

return Telescope
