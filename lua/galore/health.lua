local M = {}
local health = require("health")

M.check = function()
	health.report_start("Galore health check")
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
end

return M
