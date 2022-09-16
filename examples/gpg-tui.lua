local terms = require("toggleterm.terminal")
local gpgtui = terms.Terminal:new({
  cmd = "gpg-tui",
  direction = "float",
  float_opts = {
    border = "single",
  },
})

local function gpgtui_toggle()
  gpgtui:toggle()
end

vim.keymap.set('n', '<leader>mg', gpgtui_toggle, {noremap = true, silent = true})
