local nm = require "notmuch"
local Buffer = require "galore.lib.buffer"
local runtime = require "galore.runtime"
local ordered = require "galore.lib.ordered"
local o = require "galore.opts"

local Saved = Buffer:new()

Saved.Commands = {
  --- create a new search
}

local function make_entry(self, db, box, search)
  local q = nm.create_query(db, search.search)
  if exclude then
    for _, ex in ipairs(self.opts.exclude_tags) do
      -- we don't really care if the tags are removed or not, we want to do best effort
      pcall(function()
        nm.query_add_tag_exclude(q, ex)
      end)
    end
  end
  local unread_q = nm.create_query(db, search.search .. " and tag:unread")
  local messages = nm.query_count_messages(q)
  local unread = nm.query_count_messages(unread_q)
  table.insert(box, {
    messages = messages,
    unread = unread,
    name = search.name,
    search = search.search,
  })
end

function Saved:manual(searches)
  runtime.with_db(function(db)
    for name, search in nm.config_get_pairs(db, "query") do
      ordered.insert(searches, search, { search = search, name = name, exclude = true })
    end
  end)
end

function Saved:gen_tags(searches)
  runtime.with_db(function(db)
    for tag in nm.db_get_all_tags(db) do
      local search = "tag:" .. tag
      ordered.insert(searches, search, { search = search, name = tag, exclude = true })
    end
  end)
end

function Saved:gen_internal(searches)
  for search in runtime.iterate_saved() do
    ordered.insert(searches, search, { search = search, name = search, exclude = true })
  end
end

function Saved:gen_excluded(searches)
  for _, tag in ipairs(self.opts.exclude_tags) do
    local search = "tag:" .. tag
    ordered.insert(searches, search, { search = search, name = tag, exclude = false })
  end
end

function Saved:get_searches()
  local searches = ordered.new()
  for _, gen in ipairs(self.searches) do
    gen(self, searches)
  end
  return searches
end

local function ppsearch(tag)
  local left = string.format("%d(%d) %s", tag.messages, tag.unread, tag.name)
  return string.format("%-35s (%s)", left, tag.search)
end

--- Redraw all the saved searches and update the count
function Saved:refresh()
  self:unlock()
  self:clear()
  local box = {}
  local searches = self:get_searches()
  runtime.with_db(function(db)
    for _, search in ordered.pairs(searches) do
      make_entry(self, db, box, search)
    end
  end)
  local formated = vim.tbl_map(ppsearch, box)
  self:set_lines(0, 0, true, formated)
  self:set_lines(-2, -1, true, {})
  self.State = box
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  self:lock()
end

--- Return the currently selected line
function Saved:select()
  local line = vim.fn.line "."
  return self.State[line]
end

--- @param browser any
--- @param mode any
function Saved:select_search(browser, mode)
  local search = self:select().search
  browser:create(search, { kind = mode, parent = self })
end

function Saved:default_browser()
  local default_browser = self.opts.default_browser or "tmb"
  if default_browser == "tmb" then
    return require "galore.browser.thread_messages"
  elseif default_browser == "message" then
    return require "galore.browser.messages"
  elseif default_browser == "thread" then
    return require "galore.browser.threads"
  else
    error "Unknown browser"
  end
end

--- @param mode any
function Saved:select_search_default(mode)
  local browser = self:default_browser()
  self:select_search(browser, mode)
end

--- Create a new window for saved searches
--- @param opts table {kind}
--- @return any
function Saved:create(opts, searches)
  o.saved_options(opts)
  return Buffer.create({
    name = opts.bufname,
    ft = "galore-saved",
    kind = opts.kind,
    cursor = "top",
    mappings = opts.key_bindings,
    init = function(buffer)
      buffer.searches = searches
      buffer.opts = opts
      buffer:refresh()
      opts.init(buffer)
    end,
  }, Saved)
end

return Saved
