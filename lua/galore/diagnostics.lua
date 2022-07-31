local Dia = {}

--- If it find something to match on (or schematics), it returns that branch of the condition
local function match(cond, line)
	if cond == nil then
		return false
	end
	if type(cond) ~= type(line) then
		return false
	end
	if cond == line then
		return cond
	end

	if vim.tbl_islist(cond) and vim.tbl_islist(line) then
		for _, value in ipairs(cond) do
			if vim.tbl_contains(line, value) then
				return value
			end
		end
	end

	if type(cond) == 'table' then
		for k, _ in pairs(cond) do
			local m = match(cond[k], line[k])
			if m then
				return {[k] = m}
			end
		end
	end
	return false
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
			message = vim.inspect(m),
			source = "galore",
		}
		return diagnostics
	end
end

function Dia.set_emph(browser, emph)
	browser.emph = emph
	browser.diagnostics = {}
	for i, message in ipairs(browser.State) do
		local high = highlight(browser.handle, message, i-1, emph)
		if high then
			table.insert(browser.diagnostics, high)
		end
	end
	vim.diagnostic.set(browser.dians, browser.handle, browser.diagnostics, diaopts)
end

function Dia.update_emph(browser, i)
	local new = highlight(browser.handle, browser.State[i], i-1, browser.emph)
	for j, dia in ipairs(browser.diagnostics) do
		if dia.lnum == i then
			browser.diagnostics[j] = new
		end
		if dia.lnum > i then
			break
		end
	end
	vim.diagnostic.set(browser.dians, browser.handle, browser.diagnostics, diaopts)
end

return Dia
