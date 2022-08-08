if 1 ~= vim.fn.has "nvim-0.7.0" then
  vim.api.nvim_err_writeln "Galore requires at least nvim-0.7.0."
  return
end

vim.api.nvim_set_hl(0, "GaloreVerifyGreen", {fg="Green"})
vim.api.nvim_set_hl(0, "GaloreVerifyRed", {fg="Red"})
vim.api.nvim_set_hl(0, "GaloreSeperator", {fg="Red"})
vim.api.nvim_set_hl(0, "GaloreAttachment", {fg="Red"})
vim.api.nvim_set_hl(0, "GaloreHeader", {link="Comment"})

vim.api.nvim_create_user_command("Galore", function (args)
		require('galore').open()
	end, {
	nargs = 0,
})

vim.api.nvim_create_user_command("GaloreCompose", function (args)
		require('galore').compose(args.fargs)
	end, {
	nargs = "?",
})

vim.api.nvim_create_user_command("GaloreNew", function (args)
		require('galore.jobs').new()
	end, {
	nargs = 0,
})
