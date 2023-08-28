--- @meta

--- @class View
--- @field line table
local View = {}

--- @return GMime.Part[]
function View:attachments() end

--- Move to the next message
function View:next() end

--- Move to the prev message
function View:prev() end

return View
