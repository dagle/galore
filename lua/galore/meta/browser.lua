--- @meta

--- @class Browser
--- @field State integer[]
local Browser = {}

--- @param mode any
-- --- @return view
function Browser:select_thread(mode) end

--- @return number[]
function Browser:thread() end

--- @param line_nr integer
function Browser:update(line_nr) end

function Browser:refresh() end

return Browser
