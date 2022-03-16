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

local r = require("galore.render")
local gu = require("galore.gmime.util")
local message_view = require("galore.message_view")
local ts_utils = require "telescope.utils"
local strings = require "plenary.strings"
local gp = require("galore.gmime.parts")
local gc = require("galore.gmime.content")
local go = require("galore.gmime.object")
local ffi = require("ffi")
local config = require("galore.config")
local nm = require("galore.notmuch")

local Telescope = {}

-- parses the tree and outputs the parts
-- this should use select
-- XXX todo, a bit over the top atm
local function show_tree(object)
	if gp.is_message_part(object) then
		return "message-part"
	elseif gp.is_partial(object) then
		return "partial"
	elseif gp.is_part(object) then
		local part = ffi.cast("GMimePart *", object)
		if gp.part_is_attachment(part) then
			-- if gu.part_mime_type(object) == "application/pgp-signature" then
			-- 	return "signature"
			-- end
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

-- should take a filter function?
function Telescope.parts_browser(message, selected)
	local state = {}
	state.select = {}
	state.part = {}
	gp.message_foreach_dfs(message, browser_fun, state)
	vim.ui.select(state.select, {}, function (_, idx)
		-- apply filters to this?
		if selected then
			selected(state.part[idx])
		end
	end)
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
	local message = gu.parse_message(path)
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
	local path = entry.value.filename
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
	local line = {
		filename=entry.value.filename,
		tags=entry.value.tags,
	}
	message_view:create(line, mode, nil, nil)
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
	local message = gu.parse_message(path)
	r.show_header(message, buf, nil, nil)
	r.show_message(message, buf, {preview = function (bufid, str)
		encrypted(bufid, winid, str)
	end})
	putils.highlighter(buf, "mail")
end

Telescope.notmuch_search = function(opts, cb)
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
			action_set.select:replace(open_search)
			return true
		end,
	}):find()
end

Telescope.load_draft = function(opts)
	opts = opts or {}
	local search = opts.search or ""
	opts.presearch = search .. "tag:draft"
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

function Telescope.goto_tree(message, opts)
	opts = opts or {}
	local realsearch = gp.message_get_message_id(message)
	opts.presearch = string.format("thread:{mid:%s}", realsearch)
	opts.prompt_title = "Load References"
	opts.results_title = "Message"
	opts.preview_title = "Message Preview"
	Telescope.notmuch_search(opts)
end

--- go to all emails before this one
function Telescope.goto_reference(message, opts)
	opts = opts or {}
	local refs = go.object_get_header(ffi.cast("GMimeObject *", message), "References")
	if refs == nil then
		vim.notify("No reference")
		return
	end
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
function Telescope.goto_references(message, opts)
	local realsearch = gp.message_get_message_id(message)
	opts.search_group = {"message-after", realsearch}
	opts.prompt_title = "Load References"
	opts.results_title = "Message"
	opts.preview_title = "Message Preview"
	Telescope.notmuch_search(opts)
end

--- Move this
function Telescope.goto_parent(mv)
	local nu = require("galore.notmuch-util")
	local ref = go.object_get_header(ffi.cast("GMimeObject *", mv.message), "In-Reply-To")
	if ref == nil then
		vim.notify("No reference")
		return
	end
	local realsearch = gc.utils_decode_message_id(ref)

	local query = nm.create_query(config.values.db,  realsearch)
	local line
	for nmmessage in nm.query_get_messages(query) do
		line = nu.get_message(nmmessage)
		break;
	end

	local items = make_tag(mv.message)
	vim.fn.settagstack(vim.fn.win_getid(), {items=items}, 't')
	message_view:create(line, "replace", nil, nil)
end

Telescope.attach_file = function(compose, opts)
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
			compose:add_attachment(file)
		end)
		return true
	end
	require("telescope").extensions.file_browser.file_browser(opts)
end

return Telescope
