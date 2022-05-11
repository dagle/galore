local config = require("galore.config")
local ok, ls = pcall(require, "luasnip")
if not ok then
	print("Error can't load cmp needed for address book")
	return
end
local s = ls.snippet
local t = ls.text_node

local function replace_text(replace)
	if type(replace) == "string" then
		return replace
	end
	if type(replace) == "table" then
		if replace.group then
			local ret = replace.group .. ": "
			ret = ret .. table.concat(replace, " ") .. ";"
			return ret
		end
		return table.concat(replace, " ")
	end
end

for _, v in ipairs(config.values.alias) do
	local text = replace_text(v[2])
	ls.add_snippets("mail", {
		s(v[1], {
			t({text})
		})
	})
end
