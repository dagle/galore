--- A small example on how to use luasnip
--- for email. The filetype filetype that compose uses is mail
local ls = require("luasnip")
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

local alias = {{"Work-emails", "example@example.org, test@test.org"}}

for _, v in ipairs(alias) do
	local text = replace_text(v[2])
	ls.add_snippets("mail", {
		s(v[1], {
			t({text})
		})
	})
end
