local Dia = {}

--- Should return what we matched on
--- Should this be "and" or "or" semantics?
local function match(cond, line)
	if cond == nil then
		return false
	end
	if type(cond) ~= type(line) then
		return false
	end

	if vim.tbl_islist(cond) and vim.tbl_islist(line) then
		for _, value in ipairs(cond) do
			if not vim.tbl_contains(line, value) then
				return false
			end
		end
	end

	if type(cond) == 'table' then
		for k, _ in pairs(cond) do
			if not match(cond[k], line[k]) then
				return false
			end
		end
	elseif cond == line then
		return true
	end
	return true
end

local diaopts = { virtual_text = false, signs = false }

local function highlight(bufnr, message, offset, cond)
	local m = match(cond, message)
	if m then
		local diagnostics = {
			bufnr = bufnr,
			lnum = offset,
			end_lnum = offset,
			col = 0,
			end_col = -1,
			severity = vim.diagnostic.severity.INFO,
			message = "Match",
			source = "galore",
		}
		return diagnostics
	end
end

function Dia.set_emph(browser, cond)
	browser.cond = cond
	browser.diagnostics = {}
	for i, message in ipairs(browser.State) do
		local high = highlight(browser.handle, message, i-1, browser.emph)
		if high then
			table.insert(browser.diagnostics, high)
		end
	end
	vim.diagnostic.set(browser.dians, browser.handle, browser.diagnostics, diaopts)
end

---XXX todo
function Dia.update_emph(browser, i)
	local apa = highlight(browser.handle, browser.State[i], i, browser.cond)
	vim.diagnostic.set(browser.dians, browser.handle, browser.diagnostics, diaopts)
end

return Dia
