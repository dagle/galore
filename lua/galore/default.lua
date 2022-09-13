local config = require("galore.config")
local grouped = config.values.browser_grouped
local M = {}

function M.init(opts, searches)
		local saved = require("galore.saved")
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
		return saved:create(opts, searches)
end

return M
