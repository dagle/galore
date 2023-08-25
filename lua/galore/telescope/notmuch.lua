local pickers = require "telescope.pickers"
local previewers = require "telescope.previewers"
local finders = require "telescope.finders"
local putils = require "telescope.previewers.utils"
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local action_set = require "telescope.actions.set"

local r = require "galore.render"
local u = require "galore.util"
local util = require "galore.telescope.util"

local runtime = require "galore.runtime"
local nu = require "galore.notmuch-util"
local nm = require "notmuch"
local gu = require "galore.gmime-util"

local config = require "galore.config"

local Telescope = {}

function Telescope.open_path(bufnr, type, fun)
  local entry = action_state.get_selected_entry()
  local message = gu.parse_message(entry.value.filename)
  actions.close(bufnr)
  local opts = {
    keys = util.list_to_table(entry.value.keys),
  }

  fun(type, message, opts)
end

-- I don't really want this here but I really
-- don't want the user to having to define it everywhere
local function open_search(bufnr, type)
  -- TODO: add support for opening the thread
  local message_view = require "galore.view.message"

  local entry = action_state.get_selected_entry()
  entry.value.keys = util.list_to_table(entry.value.keys)
  actions.close(bufnr)
  message_view:create(entry.value.id, { kind = type })
end

function Telescope.create_search(browser, bufnr, type, parent)
  local search = action_state.get_current_line()
  actions.close(bufnr)
  local opts = {
    kind = type,
    parent = parent,
  }
  browser:create(search, opts)
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
  runtime.with_db(function(db)
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
  local ui = require "galore.ui"
  local ns = vim.api.nvim_create_namespace "galore-preview"
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  -- this should never be false?
  if entry.id and entry.id ~= "" then
    local telerender = r.new({
      verify = false,
      -- attachment = false,
      encrypted = function(_, _, _, _)
        util.encrypted(buf, winid, "encrypted")
      end,
    }, r.default_render)
    -- vim.api.nvim_get_keymap
    local line = entry_populate(entry)
    if not line then
      return
    end
    local message = gu.parse_message(line.filenames[1])
    local i = r.show_headers(message, buf, { ns = ns }, line)
    local buffer = {}
    local state = r.render_message(telerender, message, buffer, {})
    u.purge_empty(buffer)
    vim.api.nvim_buf_set_lines(buf, -1, -1, true, { "" })
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

    local ret = vim.tbl_flatten { "nm-livesearch", "-d", config.values.db_path, group, prompt }
    return ret
  end, entry_maker(), opts.max_results, opts.cwd)

  pickers
    .new(opts, {
      prompt_title = "Notmuch search",
      results_title = "Notmuch match",
      finder = live_notmucher,
      previewer = previewers.new_buffer_previewer {
        title = opts.preview_title or "Notmuch preview",
        keep_last_buf = false,
        define_preview = function(self, entry, _)
          mime_preview(self.state.bufnr, self.state.winid, entry.value)
        end,
      },
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
    })
    :find()
end

return Telescope
