--- @meta
---
--- @module 'galore.lib.buffer'

--- @class View : Buffer
--- @field line table
--- @field vline integer
--- @field parent table
--- @field opts table
local View = {}

--- @return GMime.Part[]
function View:attachments() end

--- Move to the next message
function View:next() end

--- Move to the prev message
function View:prev() end

return View
