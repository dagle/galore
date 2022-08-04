local config = require("galore.config")
local grouped = config.values.browser_grouped
local M = {}

function M.message_description(l, group)
	local gu = require("galore.gmime.util")
	local t = table.concat(l.tags, " ")
	local formated
	local date = os.date("%Y-%m-%d", l.date)
	local from = gu.preview_addr(l.from, 25)
	if l.index > 1 and l.level > 0 then
		formated = string.format("%s [%02d/%02d] %s│ %s▶ (%s)", date, l.index, l.total, from, l.pre, t)
	elseif group and grouped then
		formated = string.format("%s [%02d/%02d] %s│ └─▶ (%s)", date, l.index, l.total, from, t)
	else
		formated = string.format("%s [%02d/%02d] %s│ %s (%s)", date, l.index, l.total, from, l.sub, t)
	end
	formated = string.gsub(formated, "[\r\n]", "")
	return formated
end

function M.init(opts)
		require("galore.cmp_nm")
		require("galore.cmp_vcard")
		local group = vim.api.nvim_create_augroup("galore-windowstyle", {clear = true})
		vim.api.nvim_create_autocmd({"BufEnter", "Filetype"},{
			pattern = {"galore-threads*", "galore-messages"},
			group = group,
			callback = function ()
				vim.api.nvim_win_set_option(0, "foldlevel", 1)
				vim.api.nvim_win_set_option(0, "foldmethod", "manual")
				vim.api.nvim_win_set_option(0, "foldcolumn", '1')
			end})
		vim.api.nvim_create_autocmd({"BufEnter", "Filetype"},{
			pattern = {"mail"},
			group = group,
			callback = function ()
				vim.api.nvim_win_set_option(0, "foldlevel", 99)
				vim.api.nvim_win_set_option(0, "foldmethod", "syntax")
				vim.api.nvim_win_set_option(0, "foldcolumn", '1')
			end})
		local saved = require("galore.saved")
		return saved:create(opts)
end

function M.gen_config()
	local message_description = M.message_description
	config.values.show_message_description = message_description
	config.values.init = M.init
end

-- function M.header_functions()
-- 	local runtime = require("galore.runtime")
-- 	runtime.register_headerfunc("re")
-- end

return M
