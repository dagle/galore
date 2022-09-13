local M = {}
local health = require("health")

M.check = function()
	health.report_start("Galore health check")
	if vim.fn.executable("notmuch") == 1 then
		health.report_ok("Found notmuch")
	else
		health.report_error("Could not find notmuch, galore won't work")
	end
	if vim.fn.executable("nm-livesearch") == 1 then
		health.report_ok("found the executable nm-livesearch")
	else
		health.report_error("Could not find nm-livesearch, galore won't work")
	end
	if vim.fn.executable("browser-pipe") == 1 then
		health.report_ok("found the executable browser-pipe")
	else
		health.report_error("Could not find browser-pipe, won't be able to view html in an external browser")
	end
	if vim.fn.executable("file") == 1 then
		health.report_ok("found the find executable")
	else
		health.report_error("Could not find file, galore won't work")
	end
	if pcall(require, "cmp") then
		health.report_ok("Found cmp")
	else
		health.report_error("Missing cmp for email completion")
	end
	if pcall(require, "telescope") then
		health.report_ok("Found telescope")
	else
		health.report_error("Missing telescope for email search")
	end
	if vim.fn.executable("mates") == 1 then
		health.report_ok("Found mates")
	else
		health.report_error("Missing mates for vcard support")
	end
	if vim.fn.executable("w3m") == 1 then
		health.report_ok("found w3m")
	else
		health.report_error("Missing w3m default html render")
	end
end

return M
