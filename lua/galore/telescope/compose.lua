local Telescope = require "galore.telescope.notmuch"
local action_set = require "telescope.actions.set"
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

local cb = require "galore.view.message"

local Compose = {}

local function load_draft(kind, message, opts)
  cb.load_draft(kind, message, opts)
end

local function load_compose(kind, message, opts)
  cb.message_reply(kind, message, "reply", opts)
end

local function load_compose_all(kind, message, opts)
  cb.message_reply(kind, message, "reply_all", opts)
end

function Telescope.compose_search(bufnr, type)
  Telescope.open_path(bufnr, type, load_compose)
end

function Telescope.compose_search_all(bufnr, type)
  Telescope.open_path(bufnr, type, load_compose_all)
end

local function open_draft(bufnr, type)
  Telescope.open_path(bufnr, type, load_draft)
end

Compose.load_draft = function(opts)
  opts = opts or {}
  -- local search = opts.search or ""
  -- opts.default_text = "tag:draft and not tag:sent "
  opts.presearch = opts.presearch or "tag:draft and not tag:sent"
  opts.prompt_title = "Load draft"
  opts.results_title = "Drafts"
  opts.preview_title = "Draft preview"
  opts.galore_keymaps = {}
  opts.attach_mappings = function()
    action_set.select:replace(open_draft)
    return true
  end
  Telescope.notmuch_search(opts)
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

return Compose
