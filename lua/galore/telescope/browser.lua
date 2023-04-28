local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')

local Browser = {}

function Browser.create_search(browser, bufnr, type, parent)
  local search = action_state.get_current_line()
  actions.close(bufnr)
  local opts = {
    kind = type,
    parent = parent,
  }
  browser:create(search, opts)
end

return Browser
