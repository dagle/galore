-- This is a hack that lets us tell the lsp
-- where to find the completions. To use these install
-- https://github.com/dagle/invader.nvim

local lgi = require 'lgi'

local lib = (function()
  local dirname = string.sub(debug.getinfo(1).source, 2, #'/gmime-extra.lua' * -1)
  return dirname .. '../../lib'
end)()

lgi.GIRepository.Repository.prepend_library_path(lib .. '/lib/')
lgi.GIRepository.Repository.prepend_search_path(lib .. '/lib/girepository-1.0')

-- @module 'GMime_extra_3_0'
-- local GMime_extra_3_0 = lgi.require("GMime-extra", "3.0")
local Galore = lgi.require("Galore", "0.1")

return Galore
