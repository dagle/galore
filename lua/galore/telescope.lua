local ok, _ = pcall(require, 'telescope')
if not ok then
	print("You need to install telescope to use this module")
	return
end

local pickers = require("telescope.pickers")
local teleconf = require("telescope.config").values
local previewers = require "telescope.previewers"
local compose = require('galore.compose')
local actions = require("telescope.actions")
local putils = require("telescope.previewers.utils")
local finders = require("telescope.finders")
local action_state = require "telescope.actions.state"
local action_set = require "telescope.actions.set"

local r = require('galore.render')
local gm = require('galore.gmime')
local nm = require('galore.notmuch')
local conf = require('galore.config')

local M = {}

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
		table.insert(data, {filename, display})
	end
	return finders.new_table {
		results = data,
		entry_maker = function (entry)
			return {
				value = entry[1],
				display = entry[2],
				ordinal = entry[1],
			}
		end
	}
end

-- XXX we are opening message multiple times
local function open_draft(bufnr, type)
	local entry = action_state.get_selected_entry()
	local message = gm.parse_message(entry.value)
	local mode = "current"
	actions.close(bufnr)

	-- XXX We should merge these to be the same
	if type == "default" then
		mode = "current"
	elseif type == "horizontal" then
		mode = "split"
	elseif type == "vertical" then
		mode = "vsplit"
	elseif type == "tabedit" then
		mode = "tab"
	end
	compose.create(mode, message)
end

M.notmuch_search = function(opts)
  opts = opts or {}
  pickers.new(opts, {
    prompt_title = "Notmuch search",
    results_title = "Notmuch match",
    finder = notmuch_picker(opts),
    previewer = previewers.new_buffer_previewer {
		title = opts.preview_title or "Notmuch preview",
		keep_last_buf = true,
		define_preview = function(self, entry, status)
			local message = gm.parse_message(entry.value)
			r.show_header(message, self.state.bufnr)
			r.show_message(message, self.state.bufnr, false)
			putils.highlighter(self.state.bufnr, "mail")
		end,
	},
	attach_mappings = function()
		action_set.select:replace(open_draft)
		return true
	end,
    sorter = teleconf.file_sorter(opts),
  }):find()
end

M.load_draft = function(opts)
	opts = opts or {}
	local search = opts.search or ""
	opts.search = search-- .. "tag:draft" -- XXX change back
    opts.prompt_title = "Load draft"
	opts.results_title = "Drafts"
	opts.preview_title = "Draft preview"
	M.notmuch_search(opts)
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
		P(file)
		-- add file to attachment to current compose
    end)
    return true
  end
	require 'telescope'.extensions.file_browser.file_browser(opts)
end
return M
