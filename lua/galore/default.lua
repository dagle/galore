local config = require("galore.config")
local M = {}

function M.message_description(l)
	local gu = require("galore.gmime.util")
	local t = table.concat(l.tags, " ")
	local formated
	local date = os.date("%Y-%m-%d", l.date)
	local from = gu.preview_addr(l.from, 25)
	if l.index > 1 then
		formated = string.format("%s [%02d/%02d] %s│ %s▶ (%s)", date, l.index, l.total, from, l.pre, t)
	else
		formated = string.format("%s [%02d/%02d] %s│ %s (%s)", date, l.index, l.total, from, l.sub, t)
	end
	formated = string.gsub(formated, "[\r\n]", "")
	return formated
end

function M.init(opts)
		require("galore.cmp_nm")
		require("galore.cmp_vcard")
		vim.api.nvim_create_autocmd({"BufEnter", "Filetype"},{
			pattern = {"galore-threads*", "galore-messages"},
			callback = function ()
				vim.api.nvim_win_set_option(0, "foldlevel", 1)
				vim.api.nvim_win_set_option(0, "foldmethod", "manual")
				vim.api.nvim_win_set_option(0, "foldcolumn", '1')
			end})
		vim.api.nvim_create_autocmd({"BufEnter", "Filetype"},{
			pattern = {"mail"},
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

return M
