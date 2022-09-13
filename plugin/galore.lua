if 1 ~= vim.fn.has "nvim-0.7.0" then
  vim.api.nvim_err_writeln "Galore requires at least nvim-0.7.0."
  return
end

if vim.g.loaded_galore == 1 then
  return
end
vim.g.loaded_galore = 1

vim.api.nvim_set_hl(0, "GaloreVerifyGreen", {fg="Green"})
vim.api.nvim_set_hl(0, "GaloreVerifyRed", {fg="Red"})
vim.api.nvim_set_hl(0, "GaloreSeperator", {fg="Red"})
vim.api.nvim_set_hl(0, "GaloreAttachment", {fg="Red"})
vim.api.nvim_set_hl(0, "GaloreHeader", {link="Comment"})
vim.api.nvim_set_hl(0, "GaloreVerifyGreen", {fg="Green"})
vim.api.nvim_set_hl(0, "GaloreVerifyRed", {fg="Red"})

vim.api.nvim_create_user_command("Galore", function (args)
	local opts = {}
	if args.args and args.args ~= "" then
		opts.search = args.args
	end
	require('galore').open(opts)
	end, {
	nargs = "*",
})

vim.api.nvim_create_user_command("GaloreCompose", function (args)
		require('galore').compose("replace", args.args)
	end, {
	nargs = "?",
})

vim.api.nvim_create_user_command("GaloreMailto", function (args)
		require('galore').mailto("replace", args.args)
	end, {
	nargs = "?",
})

vim.api.nvim_create_user_command("GaloreNew", function ()
		require('galore.jobs').new()
	end, {
	nargs = 0,
})
