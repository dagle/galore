local Telescope = require("galore.telescope.notmuch")
local runtime = require("galore.runtime")
local nm = require('notmuch')
local gu = require('galore.gmime-util')

local M = {}

function M.goto_tree(message_id, opts)
  opts = opts or {}
  local tid
  runtime.with_db(function(db)
    local nm_message = nm.db_find_message(db, message_id)
    tid = nm.message_get_thread_id(nm_message)
  end)
  opts.presearch = string.format('thread:%s', tid)
  opts.prompt_title = 'Load Message Tree'
  opts.results_title = 'Message'
  opts.preview_title = 'Message Preview'
  Telescope.notmuch_search(opts)
end

--- go to all emails before this one
function Telescope.goto_reference(message_id, opts)
  opts = opts or {}
  opts.presearch = message_id
  opts.search_group = 'messages-before'
  opts.prompt_title = 'Load Reference'
  opts.results_title = 'Message'
  opts.preview_title = 'Message Preview'
  Telescope.notmuch_search(opts)
end

--- go to all emails before this one
function Telescope.goto_references(message_id, opts)
  opts = opts or {}
  opts.presearch = message_id
  opts.search_group = 'messages-after'
  opts.prompt_title = 'Load References'
  opts.results_title = 'Message'
  opts.preview_title = 'Message Preview'
  Telescope.notmuch_search(opts)
end

return M
