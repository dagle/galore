local ok, _ = pcall(require, "telescope")
if not ok then
	error("You need to install telescope to use this module")
	return
end
local u = require("galore.util")
local pickers = require("telescope.pickers")
local previewers = require("telescope.previewers")
local actions = require("telescope.actions")
local putils = require("telescope.previewers.utils")
local finders = require("telescope.finders")
local action_state = require("telescope.actions.state")
local action_set = require("telescope.actions.set")
local config = require("galore.config")

local r = require("galore.render")

local gu = require("galore.gmime-util")

local message_view = require("galore.message_view")
local ts_utils = require "telescope.utils"
local strings = require "plenary.strings"
local runtime = require("galore.runtime")
local nm = require("notmuch")
local nu = require("galore.notmuch-util")
local fb_utils = require "telescope._extensions.file_browser.utils"
local scan = require "plenary.scandir"
local Path = require "plenary.path"
local cb = require("galore.callback")

local lgi = require 'lgi'
local gmime = lgi.require("GMime", "3.0")

local Telescope = {}

local function filter(object, types)
	if types == nil or vim.tbl_isempty(types) then
		return true
	end
	for _, v in ipairs(types) do
		if gu.mime_type(object) == v then
			return true
		end
	end
	return false
end

local function show_tree(object, types)
	if filter(object, types) then
		return gu.mime_type(object)
	end
end

--- Being able to match encrypted files
local encrypted = {
	"application/x-pgp-signature",
	"application/pgp-signature",
	"application/x-pgp-encrypted",
	"application/pgp-encrypted",
	"application/pgp-keys",

	"application/x-pkcs7-signature",
	"application/pkcs7-signature",
	"application/x-pkcs7-mime",
	"application/pkcs7-mime",
	"application/pkcs7-keys",
}

function Telescope.parts_browser(message, selected, types)
	local state = {}
	state.select = {}
	state.part = {}
	local function browser_fun(_, part, level)
		local strbuf = {}
		for _ = 1, level-1 do
			table.insert(strbuf, "\t")
		end
		local entry = show_tree(part, types)
		if entry then
			table.insert(strbuf, entry)
			local str = table.concat(strbuf)
			table.insert(state.select, str)
			table.insert(state.part, part)
		end
	end
	-- message:foreach(browser_fun)
	gu.message_foreach_level(message, browser_fun)
	vim.ui.select(state.select, {}, function (_, idx)
		if selected and idx then
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

local function list_to_table(list)
	local tbl = {}
	for _, v in ipairs(list) do
		local key = v[1]
		local value = v[2]
		tbl[key] = value
	end
	return tbl
end

-- Doesn't support multifile?
--- TODO we don't do it like that
local function open_path(bufnr, type, fun)
	local entry = action_state.get_selected_entry()
	local message = gu.parse_message(entry.value.filename)
	actions.close(bufnr)
	local mode = type_to_kind(type)
	local opts = {
		keys = list_to_table(entry.value.keys)
	}

	fun(mode, message, opts)
end

local function load_draft(kind, message, opts)
	cb.load_draft(kind, message, opts)
end

local function load_compose(kind, message, opts)
	cb.message_reply(kind, message, "reply", opts)
end

local function load_compose_all(kind, message, opts)
	cb.message_reply(kind, message, "reply_all", opts)
end

local function open_draft(bufnr, type)
	open_path(bufnr, type, load_draft)
end

function Telescope.compose_search(bufnr, type)
	open_path(bufnr, type, load_compose)
end

function Telescope.compose_search_all(bufnr, type)
	open_path(bufnr, type, load_compose_all)
end

-- add runtime to these
local function open_search(bufnr, type)
	local entry = action_state.get_selected_entry()
	entry.value.keys = list_to_table(entry.value.keys)
	actions.close(bufnr)
	local mode = type_to_kind(type)
	message_view:create(entry.value.id, {kind=mode})
end

function Telescope.create_search(browser, bufnr, type, parent)
	local search = action_state.get_current_line()
	actions.close(bufnr)
	local opts = {
		kind = type_to_kind(type) or "split",
		parent = parent,
	}
	browser:create(search, opts)
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
		local data = vim.json.decode(entry)
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

-- add extra info to an entry
local function entry_populate(entry)
	local ret
	-- TODO use the values from opts
	runtime.with_db(function (db)
		local message = nm.db_find_message(db, entry.id)
		if message == nil then
			return
		end
		local line = nu.get_message(message)
		nu.line_populate(db, line)
		ret = line
	end)
	return ret
end

-- change to entry
local function mime_preview(buf, winid, entry)
	local ui = require("galore.ui")
	local ns = vim.api.nvim_create_namespace("galore-preview")
	vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
	-- this should never be false?
	if entry.id and entry.id ~= "" then
		local telerender = r.new({
			verify = false,
			-- attachment = false,
			encrypted = function (_, _, _, _)
				encrypted(buf, winid, "encrypted")
			end
		}, r.default_render)
		-- vim.api.nvim_get_keymap
		local line = entry_populate(entry)
		if not line then
			return
		end
		local message = gu.parse_message(line.filenames[1])
		local i = r.show_headers(message, buf, {ns = ns}, line)
		local buffer = {}
		local state = r.render_message(telerender, message, buffer, {})
		u.purge_empty(buffer)
		vim.api.nvim_buf_set_lines(buf, -1, -1, true, buffer)
		vim.api.nvim_buf_set_lines(buf, -2, -1, true, {})

		--- XXX Why is - 2 the best value here? WHY (or is it?)
		--- maybe -1 for 0 index and then i is 1 index so - 2?
		local linenr = i + #buffer - 2
		if not vim.tbl_isempty(state.attachments) then
			ui.render_attachments(state.attachments, linenr, buf, ns)
		end
		putils.highlighter(buf, "mail")
	end
end

Telescope.notmuch_search = function(opts)
	opts = opts or {}
	--- maybe not the sexiest, but works until we rewrite this
	opts.galore_keymaps = opts.galore_keymaps or config.values.key_bindings.telescope
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
		local group = opts.search_group or "messages"

		-- TODO use the values from opts and not config!

		local ret = vim.tbl_flatten({ "nm-livesearch", "-d", config.values.db_path, group, prompt})
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
				mime_preview(self.state.bufnr, self.state.winid, entry.value)
			end,
		}),
		attach_mappings = function(buf, map)
			action_set.select:replace(open_search)
			for mode, binds in pairs(opts.galore_keymaps) do
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
	-- opts.default_text = "tag:draft and not tag:sent "
	opts.presearch = opts.presearch or "tag:draft and not tag:sent"
	opts.prompt_title = "Load draft"
	opts.results_title = "Drafts"
	opts.preview_title = "Draft preview"
	opts.galore_keymaps = {}
	opts.attach_mappings = function ()
			action_set.select:replace(open_draft)
			return true
	end
	Telescope.notmuch_search(opts)
end

local function make_tag(message)
	local subject = message:get_header("Subject") or ""
	local from = {vim.fn.bufnr('%'), vim.fn.line('.'), vim.fn.col('.'), 0}
	return {{tagname=subject, from=from}}
end

function Telescope.get_header(message, header)
	local ref = message:get_header(header)
	if refs == nil then
		vim.notify("No " .. header)
		return
	end
	return refs
end

function Telescope.goto_tree(message_id, opts)
	opts = opts or {}
	local tid
	runtime.with_db(function (db)
		local nm_message = nm.db_find_message(db, message_id)
		tid = nm.message_get_thread_id(nm_message)
	end)
	opts.presearch = string.format("thread:%s", tid)
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
	for ref in gu.reference_iter_str(refs) do
		table.insert(buf, "mid:" .. ref)
	end
	opts.presearch = search .. table.concat(buf, " or ")
	opts.search_group = "messages-before"
	opts.prompt_title = "Load Reference"
	opts.results_title = "Message"
	opts.preview_title = "Message Preview"
	Telescope.notmuch_search(opts)
end

--- goto all emails after this one
function Telescope.goto_references(message_id, opts)
	opts = opts or {}
	opts.presearch = message_id
	opts.search_group = "messages-after"
	opts.prompt_title = "Load References"
	opts.results_title = "Message"
	opts.preview_title = "Message Preview"
	Telescope.notmuch_search(opts)
end

local function goto_message(message, id, parent)
	local items = make_tag(message)
	vim.fn.settagstack(vim.fn.win_getid(), {items=items}, 't')
	message_view:create(id, {kind="replace", parent=parent})
end

function Telescope.goto_message(message, parent)
	local mid = message:get_message_id()
	goto_message(message, mid, parent)
end

function Telescope.goto_parent(message, parent)
	local ref = message:get_header("In-Reply-To")
	if ref == nil then
		vim.notify("No parent")
		return
	end
	local mid = gmime.utils_decode_message_id(ref)
	goto_message(message, mid, parent)
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
			comp:add_attachment_path(file)
		end)
		return true
	end
	require("telescope").extensions.file_browser.file_browser(opts)
end


--- set file-ending/filename as a hint somehow?

-- TODO
--- We need a binding:
--- To get the current line, even if we have a match
--- A binding to select the current directory
Telescope.save_file = function (attachment, opts)
	opts = opts or {}
	opts.prompt_title = opts.prompt_title or "Save file"
	opts.attach_mappings = function(prompt_bufnr, _)
		actions.select_default:replace(function()
			local entry = action_state.get_selected_entry()
			if entry and entry.Path:is_dir() then
				local current_picker = action_state.get_current_picker(prompt_bufnr)
				local finder = current_picker.finder
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
				local file
				if entry then
					file = entry.path
				else
					local text = action_state.get_current_line()
					file = (not opts.only_navigation and text) or attachment.filename
				end
				gu.save_part(attachment.part, file)
			end
		end)
		return true
	end
	require("telescope").extensions.file_browser.file_browser(opts)
end

return Telescope
