local config = {}

--- nil values are generated from the notmuch config
--- they can be overriden and documented here
config.values = {
	primary_email = nil, -- String
	other_email = nil, -- {String}
	name = nil, -- String
	draftdir = "draft", -- directory is relative to the nm root
	exclude_tags = nil, -- {String}
	thread_expand = true,
	thread_reverse = false,
	sort = "newest",
	sent_folder = "Sent", -- String|function(from)
	sent_tags = "+sent",
	-- reverse_thread = false, -- Do we want the thread to start from top
	empty_topyic = "no topic",
	guess_email = false, -- if we can't determain your email for reply use primary
	empty_tag = "+archive", -- nil or "tag", add a tag when there is no tag
	qoute_header = function(date, author)
		return "On " .. os.date("%Y-%m-%d ", date) .. author .. " wrote:"
	end,
	alt_mode = 1, -- for now, 0 never, 1 only render when there isn't an alternative and 2 always
	show_html = function(text, unsafe) --- how to render a html
		-- unsafe means that the email
		-- is not secure to pass to html (or should use a safe mode)
		-- for more info, check https://efail.de/
		if not unsafe then
			local jobs = require("galore.jobs")
			return jobs.html(text)
		end
		return text
	end,
	tag_unread = function(message_id)
		local nu = require("galore.notmuch-util")
		return nu.change_tag(message_id, "-unread")
	end,
	start = function (opts)
		require("galore.cmp_nm")
		require("galore.cmp_vcard")
		local saved = require("galore.saved")
		return saved:create(opts.open_mode)
	end,
	validate_key = function (status) --- what level of security we should accept?
		local convert = require("galore.gmime.convert")
		return convert.validate(status, "green") or convert.validate(status, "valid") or status == 0
	end,
	verify_flags = "keyserver", -- "none"|"session"|"noverify"|"keyserver"|"online"
	decrypt_flags = "keyserver", -- "none"|"keyserver"|"online"
	sign = false, -- Should we crypto sign the email?
	encrypt = false, -- Should we encrypt the email by default?
	gpg_id = nil, --- what gpg id to use, string or {email = string}[]
	autocrypt = true, -- insert the gpg_id in our emails
	headers = { -- What headers to show, order is important
		"From",
		"To",
		"Cc",
		"Date",
		"Subject",
	},
	send_cmd = function(message) --- sendmail command to pipe the email into
		return "msmtp", {"--read-envelope-from", "-t"}
	end,
	--- how to notify the user that a part has been verified
	annotate_signature = function (buf, ns, status, before, after, names)
		-- local ui = require("galore.ui")
		-- vim.notify(msg: any, log_level: any, opts: any)
		if status then
			vim.notify("Signature succeeded")
		else
			vim.notify("Signature failed", vim.log.levels.WARN)
		end
		-- if status then
		-- 	ui.exmark(buf, ns, "nmVerifyGreen", "--------- Signature Passed ---------", before)
		-- else
		-- 	ui.exmark(buf, ns, "nmVerifyRed", "--------- Signature Failed ---------", before)
		-- end
		-- if status then
		-- 	ui.exmark(buf, ns, "nmVerifyGreen", "--------- Signature End ---------", after)
		-- else
		-- 	ui.exmark(buf, ns, "nmVerifyRed","--------- Signature End ---------", after)
		-- end
	end,
	from_length = 25, --- The from length the default show_message_descripiton
	show_message_descripiton = function(line)
	end,
	key_bindings = {
		-- global = {
		-- 	["<leader>mc"] = function ()
		-- 		require("galore.compose"):create("tab")
		-- 	end,
		-- 	["<leader>mf"] = function ()
		-- 		require("galore.telescope").load_draft()
		-- 	end,
		-- 	["<leader>ms"] = function ()
		-- 		require("galore.telescope").notmuch_search()
		-- 	end,
		-- 	["<leader>mn"] = function ()
		-- 		require("galore.jobs").new()
		-- 	end,
		-- 	["<leader>me"] = function ()
		-- 		require("galore.runtime").edit_saved()
		-- 	end,
		-- },
		telescope = {
			i = {
				--- Dunno if this is the correct way to solve this
				["<C-q>"] = function (buf)
					local tele = require("galore.telescope")
					local mb = require("galore.message_browser")
					tele.create_search(mb, buf)
				end,
				["<C-f>"] = function (buf)
					local tele = require("galore.telescope")
					local tmb = require("galore.thread_message_browser")
					tele.create_search(tmb, buf)
				end,
				["<C-e>"] = function (buf)
					local tele = require("galore.telescope")
					tele.compose_search(buf)
				end,
			}
		},
		saved = {
			n = {
				["<CR>"] = function (saved)
					local cb = require("galore.callback")
					local tmb = require("galore.thread_message_browser")
					cb.select_search(saved, tmb, "replace")
				end,
				["m"] = function (saved)
					local cb = require("galore.callback")
					local mb = require("galore.message_browser")
					cb.select_search(saved, mb, "replace")
				end,
				["q"] = function (saved)
					saved:close(true)
				end,
				["<C-v>"] = function (saved)
					local cb = require("galore.callback")
					local tmb = require("galore.thread_message_browser")
					cb.select_search(saved, tmb, "vsplit")
				end,
				["<C-x>"] = function (saved)
					local cb = require("galore.callback")
					local tmb = require("galore.thread_message_browser")
					cb.select_search(saved, tmb, "split")
				end,
				["="] = function (saved)
					saved:refresh()
				end,
				-- this is dumb
				["s"] = function (saved)
					local tmb = require("galore.thread_message_browser")
					local search = saved:select()[4]
					local opts = {
						prompt = "Search: ",
						default = search,
					}
					vim.ui.input(opts, function (input)
						if input then
							tmb:create(input, "split", saved)
						end
					end)
				end,
			},
		},
		thread_browser = {
			n = {
				["J"] = function (tmb)
					tmb:go_thread_next()
				end,
				["K"] = function (tmb)
					tmb:go_thread_prev()
				end,
				["a"] = function (tmb)
					local cb = require("galore.callback")
					cb.change_tag(tmb)
				end,
				["<CR>"] = function (tmb)
					local cb = require("galore.callback")
					cb.select_message(tmb, "replace")
				end,
				["<C-v>"] = function (tmb)
					local cb = require("galore.callback")
					cb.select_message(tmb, "vsplit")
				end,
				["<C-x>"] = function (tmb)
					local cb = require("galore.callback")
					cb.select_message(tmb, "split")
				end,
				["q"] = function (tmb)
					tmb:close(true)
				end,
				["ymi"] = function (tmb)
					local cb = require("galore.callback")
					cb.yank_browser(tmb, "id")
				end,
				["<tab>"] = function (tmb)
					local cb = require("galore.callback")
					cb.toggle(tmb)
				end,
				["A"] = function (tmb)
					require("galore.runtime").add_saved(tmb.search)
				end,
				["="] = function (tmb)
					tmb:refresh()
				end,
				-- something like this, but less complicated
				["<leader>/"] = function (browser)
					local action_set = require("telescope.actions.set")
					local tmb = require("galore.thread_message_browser")
					local tele = require("galore.telescope")
					local opts = {
						default_text=browser.search,
						attach_mappings = function (buf, map)
							local cb = function (bufnr, type)
								tele.open_browser(tmb, bufnr, type, browser)
							end
							action_set.select:replace(cb)
							return true
						end
					}
					require("galore.telescope").notmuch_search(opts)
				end,
			},
		},
		message_browser = {
			n = {
				["a"] = function (mb)
					local cb = require("galore.callback")
					cb.change_tag(mb)
				end,
				["<CR>"] = function (mb)
					local cb = require("galore.callback")
					cb.select_message(mb, "replace")
				end,
				["<C-v>"] = function (mb)
					local cb = require("galore.callback")
					cb.select_message(mb, "vsplit")
				end,
				["<C-x>"] = function (mb)
					local cb = require("galore.callback")
					cb.select_message(mb, "split")
				end,
				["ymi"] = function (mb)
					local cb = require("galore.callback")
					cb.yank_browser(mb, "id")
				end,
				["q"] = function (mb)
					mb:close(true)
				end,
				["A"] = function (mb)
					require("galore.runtime").add_saved(mb.search)
				end,
				["="] = function (mb)
					mb:refresh()
				end,
				["<leader>/"] = function (browser)
					local action_set = require("telescope.actions.set")
					local mb = require("galore.message_browser")
					local tele = require("galore.telescope")
					local opts = {
						default_text=browser.search,
						attach_mappings = function (buf, map)
							local cb = function (bufnr, type)
								tele.open_browser(mb, bufnr, type, browser)
							end
							action_set.select:replace(cb)
							return true
						end
					}
					require("galore.telescope").notmuch_search(opts)
				end,
			},
		},
		message_view = {
			n = {
				["r"] = function (message_view)
					local cb = require("galore.callback")
					cb.message_reply(message_view)
				end,
				["R"] = function (message_view)
					local cb = require("galore.callback")
					cb.message_reply_all(message_view)
				end,
				["s"] = function (message_view)
					message_view:save_attach()
				end,
				["S"] = function (message_view)
					message_view:view_attach()
				end,
				["q"] = function (message_view)
					message_view:close(true)
				end,
				["<leader>mh"] = function (message_view)
					message_view:raw_mode()
				end,
				["<C-n>"] = function (message_view)
					message_view:next()
				end,
				["<C-p>"] = function (message_view)
					message_view:prev()
				end,
				["O"] = function (message_view)
					--- don't do this
					--- use g_mime_crypto_context_import_keys instead?
					local tele = require("galore.telescope")
					local jobs = require("galore.jobs")
					local function cb(object)
						-- local datawrapper = gp.part_get_content(part)
						-- local stream = gs.data_wrapper_get_stream(datawrapper)
						-- local ctx = gc.gpg_context_new()
						-- local num, err = gc.crypto_context_import_keys(ctx, stream)
						jobs.pipe({"gpg", "--import"}, object)
					end
					tele.parts_browser(message_view.message, cb)
				end,
				["P"] = function (message_view)
					vim.input({prompt = "Pipe message: "}, function (input)
						if input then
							local cmd = vim.fn.split(input, " ")
							local jobs = require("galore.jobs")
							jobs.pipe(cmd, message_view.message)
						end
					end)
				end,
				--- lsp inspired bindings
				["gd"] = function (message_view)
					local telescope = require("galore.telescope")
					telescope.goto_parent(message_view)
				end,
				["gD"] = function (message_view)
					local telescope = require("galore.telescope")
					telescope.goto_tree(message_view.message)
				end,
				["gr"] = function (message_view)
					local telescope = require("galore.telescope")
					telescope.goto_reference(message_view.message)
				end,
				["gR"] = function (message_view)
					local telescope = require("galore.telescope")
					telescope.goto_references(message_view.message)
				end,
			},
		},
		compose = {
			n = {
				["<leader>ms"] = function (compose)
					compose:send()
				end,
				["<leader>ma"] = function (compose)
					local tele = require("galore.telescope")
					tele.attach_file(compose)
				end,
				["<leader>md"] = function (compose)
					compose:remove_attachment()
				end,
				["<leader>mq"] = function (compose)
					compose:save_draft()
				end,
				["<leader>mo"] = function (compose)
					compose:set_option_menu()
				end,
				["<leader>mO"] = function (compose)
					compose:unset_option()
				end,
				["<leader>mh"] = function (compose)
					compose:preview()
				end,
			},
		},
		default = {
			n = {
				["q"] = function (buf)
					buf:close(true)
				end,
			}
		}
	},
}

return config
