--- A hook takes a message and returns a boolean if success

local gp = require("galore.gmime.parts")

local M = {}

--- @param message any
--- @return boolean
function M.has_attachment(message)
	local find_attachment = function (_, part, state)
		if gp.is_part(part) and gp.part_is_attachment(part) then
			state.attachment = true
		end
	end
	local state = {}
	gp.message_foreach(message, find_attachment, state)
	return state.attachment
end

--- Doesn't handle re:
function M.missed_attachment(message)
	local sub = gp.message_get_subject(message)
	local start, _ = string.find(sub, "[a,A]ttachment")
	if start and not M.has_attachment(message) then
		return false
	end
	return true
end

function M.confirm()
	vim.ui.input({
		prompt = "Wanna send email? Y[es]",
	}, function (input)
		if input then
			input = input:lower()
			if input == "yes" or "y" then
				return true
			end
		end
		return false
	end)
end

function M.preview()
end

---

function M.delete_draft()
end

return M
