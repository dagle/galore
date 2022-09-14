local config = {}

config.values = {
	--- These values are generate from notmuch if set to nil
	db_path = nil,
	nm_config = nil,
	nm_profile = nil,
	primary_email = nil, -- String
	other_email = nil, -- {String}
	name = nil, -- String
	mail_root = nil,
	exclude_tags = nil, -- A list of tags that you want to filter out from searches
	synchronize_flags = nil,

	-- select_dir is a function that select the sub folder for a messag
	select_dir = function(from) -- maybe message?
		return ""
	end,
	draft_dir = "Draft", -- directory is relative to the nm root
	sent_dir = "Sent", -- String|function(from)
	key_writeback = false, --- should we write back keys we got from decryption
	draft_encrypt = false, -- TODO
	sentencrypt = false, -- TODO

	mailinglist_subscribed = {}, -- mailing lists we are subscribed to
	default_browser = "tmb", -- default browser to use in default_bindings, also for telescope
	default_view = "context", -- default view to use in default_bindings, also for telescope, also allows "context"
	thread_expand = true,
	thread_reverse = false,
	browser_grouped = true,
	-- Order dependant, true means always show (with "" if no value), false means only show if we added a value to it and not in the list = hidden header, if it exists
	compose_headers = {{"From",true}, {"To",true}, {"Cc",false}, {"Bcc",false}, {"Subject",true}},
	extra_headres = {}, -- table with key value of headers to insert if missing
	idn = true,
	sort = "newest", -- "newest" | "oldest" | "message-id" | "unsort"
	sent_tags = "+sent",
	unsafe_tags = {"spam"}, -- tags we don't want to use for unsafe stuff
	empty_topic = "no topic",
	guess_email = false, -- if we can't determain your email for reply use primary
	empty_tag = "+archive", -- nil or "tag", add a tag when there is no tag
	default_emph = {tags = {"unread"}}, --- maybe change this to a function in the future?
	qoute_header = function(date, author)
		return "On " .. os.date("%Y-%m-%d ", date) .. author .. " wrote:"
	end,
	always_complete = false, -- always complete addresses, even if not in address header
	-- move this to example
	alt_mode = true, -- Only render one part of alts 
	alt_order = {"text/plain", "text/enriched", "text/html"}, -- table or function?
	-- alt_order = {"text/html", "text/plain", "text/enriched"}, -- table or function?
	multilingual = false, -- Only render one part of alts 
	lang_order = {}, -- {"en-GB", "en", "es" or "klingon", zxx image} or function?
	show_html = function(text, unsafe) --- how to render a html
		-- unsafe means that the email
		-- is not secure to pass to html (or should use a safe mode)
		-- for more info, check https://efail.de/
		if not unsafe then
			local jobs = require("galore.jobs")
			return jobs.w3m(text)
			-- return vim.fn.split(text)
		end
		return vim.fn.split(text)
	end,
	tag_unread = function(db, id)
		local nu = require("galore.notmuch-util")
		return nu.change_tag(db, id, "-unread")
	end,
	init = function (opts)
		local def = require("galore.default")
		local saved = require("galore.saved")
		local tmb = require("galore.thread_message_browser")
		if opts.search then
			tmb:create(opts.search, {kind="replace"})
			return
		end
		local searches = {saved.gen_tags}-- , saved.gen_internal, saved.gen_excluded}
		def.init(opts, searches)
	end,
	validate_key = function (status) --- what level of security we should accept?
		-- return bit.band(status, gmime.SignatureStatus.VALID) or bit.band(status, gmime.SignatureStatus.GREEN)
		-- return status gmime.SignatureStatus.VALID
		-- return status.VALID or status.GREEN
	end,
	verify_flags = "keyserver", -- "none"|"session"|"noverify"|"keyserver"|"online"
	decrypt_flags = "keyserver", -- "none"|"keyserver"|"online"
	sign = false, -- Should we crypto sign the email?
	encrypt = false, -- Should we encrypt the email by default? false, 1 or 2. 1 = try to encrypt
	-- create message anyways. 2 = always encrypt and failing is an error
	gpg_id = nil, --- what gpg id to use, string or {email = string}[]
	autocrypt = true, -- insert the gpg_id in our emails
	autocrypt_reply = true, -- use autocrypt in replys if their header includes one.
	custom_headers = {}, -- a list of headers/producers to be inserted into the header
	send_cmd = function(message) --- sendmail command to pipe the email into
		return "msmtp", {"--read-envelope-from", "-t"}
	end,
	--- how to notify the user that a part has been verified
	annotate_signature = function (bufnr, ns, status, before, after, _)
		local ui = require("galore.ui")
		if status then
			-- ui.exmark(bufnr, ns, "nmVerifyGreen", "--------- Signature Passed ---------", before)
			-- ui.exmark(bufnr, ns, "nmVerifyGreen", "--------- Signature Passed ---------", after)
			vim.notify("Signature succeeded")
		else
			-- ui.exmark(bufnr, ns, "nmVerifyRed", "--------- Signature Failed ---------", before)
			-- ui.exmark(bufnr, ns, "nmVerifyRed", "--------- Signature Failed ---------", after)
			vim.notify("Signature failed", vim.log.levels.WARN)
		end
	end,
	from_length = 25, --- The from length the default show_message_descripiton
	show_message_description =
		{
			"{date} [{index:02}/{total:02}] {from:25}│ {subject} ({tags})",
			"{date} [{index:02}/{total:02}] {from:25}│ {response}▶ ({tags})",
		},
	key_bindings = {
		telescope = {
			i = {
				--- default additional functionallity for telescope
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
				["<C-E>"] = function (buf)
					local tele = require("galore.telescope")
					tele.compose_search_all(buf)
				end,
			}
		},
		saved = {
			n = {
				["<CR>"] = { rhs = function (saved)
					local cb = require("galore.callback")
					cb.select_search_default(saved, "replace")
				end, desc = "Open selected"},
				["b"] = { rhs = function (saved)
					local cb = require("galore.callback")
					local mb = require("galore.message_browser")
					cb.select_search(saved, mb, "replace")
				end, desc = "Open message browser"},
				["t"] = { rhs = function (saved)
					local cb = require("galore.callback")
					local tm = require("galore.thread_browser")
					cb.select_search(saved, tm, "replace")
				end, desc = "Open thread browser"},
				["q"] = { rhs = function (saved)
					saved:close(true)
				end, desc = "Close window"},
				["<C-v>"] = { rhs = function (saved)
					local cb = require("galore.callback")
					cb.select_search_default(saved, "vsplit")
				end, desc = "Open in a vertical split"},
				["<C-x>"] = { rhs = function (saved)
					local cb = require("galore.callback")
					cb.select_search_default(saved, "split")
				end, desc = "Open in a split"},
				["="] = { rhs = function (saved)
					saved:refresh()
				end, desc = "Refresh window"},
				["s"] = { rhs = function (saved)
					local tmb = require("galore.thread_message_browser")
					local search = saved:select()[4]
					local opts = {
						prompt = "Search: ",
						default = search,
					}
					vim.ui.input(opts, function (input)
						if input then
							tmb:create(input, {kind="replace", parent=saved})
						end
					end)
				end, desc = "Create subsearch for selected"},
			},
		},
		thread_message_browser = {
			n = {
				["J"] = { rhs = function (tmb)
					vim.cmd("normal!]z")
					local line, row = unpack(vim.api.nvim_win_get_cursor(0))
					local count = vim.api.nvim_buf_line_count(0)
					line = math.min(count, line + 1)
					vim.api.nvim_win_set_cursor(0, {line, row})
				end, desc = "Jump to previous thread"},
				["K"] = { rhs = function (tmb)
					local line, row = unpack(vim.api.nvim_win_get_cursor(0))
					line = math.max(1, line - 1)
					vim.api.nvim_win_set_cursor(0, {line, row})
					vim.cmd("normal![z")
				end, desc = "Jump to next thread"},
				["a"] = { rhs = function (tmb)
					local cb = require("galore.callback")
					cb.change_tag_ask(tmb)
				end, desc = "Change tag"},
				["<CR>"] = { rhs = function (tmb)
					local cb = require("galore.callback")
					cb.select_message(tmb, "replace")
				end, desc = "Open message"},
				["<C-v>"] = { rhs = function (tmb)
					local cb = require("galore.callback")
					cb.select_message(tmb, "vsplit")
				end, desc = "Open message in vsplit"},
				["<C-x>"] = { rhs = function (tmb)
					local cb = require("galore.callback")
					cb.select_message(tmb, "split")
				end, desc = "Open message in split"},
				["q"] = { rhs = function (tmb)
					tmb:close(true)
				end, desc = "close window"},
				["ymi"] = { rhs = function (tmb)
					local cb = require("galore.callback")
					cb.yank_browser(tmb)
				end, desc = "yank the id of current message"},
				["<tab>"] = { rhs = function ()
					vim.cmd("normal!za")
				end, desc = "Toggle fold on the current tab"},
				["<C-t>"] = { rhs = function (tmb)
					tmb:mb_search()
				end, desc = "Change mode to message browser"},
				["A"] = { rhs = function (tmb)
					require("galore.runtime").add_saved(tmb.search)
				end, desc = "Save this search"},
				["="] = { rhs = function (tmb)
					tmb:refresh()
				end, desc = "Refresh the search"},
				["gD"] = { rhs = function (mb)
					local telescope = require("galore.telescope")
					local br = require("galore.browser")
					local _, id = br.select(mb)
					telescope.goto_tree(id)
				end, desc = "goto tree"},
				["<leader>m/"] = { rhs = function (browser)
					local action_set = require("telescope.actions.set")
					local tmb = require("galore.thread_message_browser")
					local tele = require("galore.telescope")
					local opts = {
						default_text=browser.search,
						attach_mappings = function (buf, map)
							local cb = function (bufnr, type)
								tele.create_search(tmb, bufnr, type, browser)
							end
							action_set.select:replace(cb)
							return true
						end
					}
					require("galore.telescope").notmuch_search(opts)
				end, desc="notmuch sub search"},
			},
		},
		message_browser = {
			n = {
				["a"] = { rhs = function (mb)
					local cb = require("galore.callback")
					cb.change_tag_ask(mb)
				end, desc = "Change tag"},
				["<CR>"] = { rhs = function (mb)
					local cb = require("galore.callback")
					cb.select_message(mb, "replace")
				end, desc = "Open message"},
				["<C-v>"] = { rhs = function (mb)
					local cb = require("galore.callback")
					cb.select_message(mb, "vsplit")
				end, desc = "Open message in vsplit"},
				["<C-x>"] = { rhs = function (mb)
					local cb = require("galore.callback")
					cb.select_message(mb, "split")
				end, desc = "Open message in split"},
				["ymi"] = { rhs = function (mb)
					local cb = require("galore.callback")
					cb.yank_browser(mb)
				end, desc = "yank the id of current message"},
				["q"] = { rhs = function (mb)
					mb:close(true)
				end, desc = "close window"},
				["A"] = { rhs = function (mb)
					require("galore.runtime").add_saved(mb.search)
				end, desc = "Save this search"},
				["="] = { rhs = function (mb)
					mb:refresh()
				end, desc = "Refresh the search"},
				["<C-t>"] = { rhs = function (mb)
					mb:tmb_search()
				end, desc = "Change mode to thread message browser"},
				["gD"] = { rhs = function (mb)
					local telescope = require("galore.telescope")
					local br = require("galore.browser")
					local _, id = br.select(mb)
					telescope.goto_tree(id)
				end, desc = "goto tree"},
				["<leader>m/"] = { rhs = function (browser)
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
				end, desc="notmuch sub search"},
			},
		},
		thread_browser = {
			n = {
				["a"] = { rhs = function (tb)
					local cb = require("galore.callback")
					cb.change_tag_threads_ask(tb)
				end, desc = "Change tag for each message"},
				["<CR>"] = { rhs = function (tb)
					local cb = require("galore.callback")
					cb.select_thread(tb, "replace")
				end, desc = "Open message"},
				["<C-v>"] = { rhs = function (tb)
					local cb = require("galore.callback")
					cb.select_thread(tb, "vsplit")
				end, desc = "Open message in vsplit"},
				["<C-x>"] = { rhs = function (tb)
					local cb = require("galore.callback")
					cb.select_thread(tb, "split")
				end, desc = "Open message in split"},
				["q"] = { rhs = function (tb)
					tb:close(true)
				end, desc = "close window"},
				["ymi"] = { rhs = function (tb)
					local cb = require("galore.callback")
					cb.yank_browser(tb)
				end, desc="Copy thread id"},
				--- add this later
				-- ["<C-t>"] = function (tb)
				-- 	tb:mb_search()
				-- end,
				["A"] = { rhs = function (tb)
					require("galore.runtime").add_saved(tb.search)
				end, desc = "Save this search"},
				["="] = { rhs = function (tb)
					tb:refresh()
				end, desc = "Refresh the search"},
				["gD"] = { rhs = function (tb)
					local telescope = require("galore.telescope")
					local br = require("galore.browser")
					local _, id = br.select(tb)
					telescope.goto_tree(id)
				end, desc = "goto tree"},
				["<leader>m/"] = { rhs = function (browser)
					local action_set = require("telescope.actions.set")
					local tmb = require("galore.thread_message_browser")
					local tele = require("galore.telescope")
					local opts = {
						default_text=browser.search,
						attach_mappings = function (buf, map)
							local cb = function (bufnr, type)
								tele.create_search(tmb, bufnr, type, browser)
							end
							action_set.select:replace(cb)
							return true
						end
					}
					require("galore.telescope").notmuch_search(opts)
				end, desc="notmuch sub search"},
			},
		},
		message_view = {
			n = {
				["r"] = { rhs = function (message_view)
					local cb = require("galore.callback")
					local mid = message_view.line.id
					cb.mid_reply("replace", mid, "reply", {parent=message_view})
				end, desc = "reply"},
				["R"] = { rhs = function (message_view)
					local cb = require("galore.callback")
					local mid = message_view.line.id
					cb.mid_reply("replace", mid, "reply_all", {parent=message_view})
				end, desc = "reply_all"},
				["s"] = { rhs = function (message_view)
					local telescope = require("galore.telescope")
					message_view:select_attachment(telescope.save_file)
				end, desc = "save attachment"},
				["S"] = { rhs = function (message_view)
					message_view:view_attach()
				end, desc = "view attachment"},
				["q"] = { rhs = function (message_view)
					message_view:close(true)
				end, desc = "close window"},
				["<leader>mh"] = { rhs = function (message_view)
					local debug = require("galore.debug")
					debug.view_raw_file(message_view.line.filenames[1])
				end, desc = "Show raw message"},
				["<C-t>"] = { rhs = function (message_view)
					message_view:thread_view()
				end, desc = "Jump to thread view"},
				["<C-n>"] = { rhs = function (message_view)
					message_view:next()
				end, desc = "Go to next message"},
				["<C-p>"] = { rhs = function (message_view)
					message_view:prev()
				end, desc = "Go to previous message"},
				["O"] = { rhs = function (message_view)
					local tele = require("galore.telescope")
					local lgi = require 'lgi'
					local gmime = lgi.require("GMime", "3.0")
					local function cb(part)
						if not gmime.Part:is_type_of(part) then
							--- this isn't a part
							return
						end
						local dw = part:get_content()
						local stream = dw:get_stream()
						local ctx = gmime.GpgContext.new()
						local num, err = ctx:import_keys(stream)
						if err ~= nil then
							local str = string.format("Added %d keys with error: %s", num, err)
							vim.notify(str, vim.log.levels.ERROR)
						else
							local str = string.format("Added %d keys", num)
							vim.notify(str, vim.log.levels.INFO)
						end
					end
					-- message_view:select_attachment(cb)
					tele.parts_browser(message_view.message, cb)
				end, desc = "Import key from part in message"},
				["mw"] = { rhs = function (message_view)
					--- view the part in a webbrowser
					local tele = require("galore.telescope")
					local r = require("galore.render")
					local jobs = require("galore.jobs")
					local cb = function (object)
						local content = object:get_content_type()
						if content:is_type("text", "*") then
							local opts = {}
							--- this is safe because the object has to be a part
							local str = r.part_to_string(object, opts)
							jobs.pipe_str({"browser-pipe"}, str)
						end
					end
					tele.parts_browser(message_view.message, cb)
				end, desc = "View part in webbrowser"},
				["P"] = { rhs = function (message_view)
					vim.input({prompt = "Pipe message: "}, function (input)
						if input then
							local cmd = vim.fn.split(input, " ")
							local jobs = require("galore.jobs")
							jobs.pipe(cmd, message_view.message)
						end
					end)
				end, desc = "Pipe a message to command"},
				--- lsp inspired bindings
				["gd"] = { rhs = function (message_view)
					local telescope = require("galore.telescope")
					telescope.goto_parent(message_view.message, message_view.parent)
				end, desc = "goto in-reply-to"},
				["gD"] = { rhs = function (message_view)
					local telescope = require("galore.telescope")
					local message_id = message_view.message:get_message_id()
					telescope.goto_tree(message_id)
				end, desc = "goto tree"},
				["gr"] = { rhs = function (message_view)
					local telescope = require("galore.telescope")
					local refs = telescope.get_header(message_view.message, "References")
					telescope.goto_reference(refs)
				end, desc = "goto References"},
				["gR"] = { rhs = function (message_view)
					local telescope = require("galore.telescope")
					local message_id = message_view.message:get_message_id()
					telescope.goto_references(message_id)
				end, desc = "goto replies"},
			},
		},
		--- fix this later, we want to generate this from message_view
		thread_view = {
			n = {
				["r"] = { rhs = function (thread_view)
					local cb = require("galore.callback")
					local mid = thread_view:get_selected()
					cb.mid_reply("replace", mid, "reply", {parent=thread_view})
				end, desc = "reply"},
				["R"] = { rhs = function (thread_view)
					local cb = require("galore.callback")
					local mid = thread_view:get_selected()
					cb.mid_reply("replace", mid, "reply_all", {parent=thread_view})
				end, desc = "reply all"},
				--- forall?
				["s"] = { rhs = function (thread_view)
					local telescope = require("galore.telescope")
					thread_view:select_attachment(telescope.save_file)
				end, desc = "save attachment"},
				--- forall?
				["S"] = { rhs = function (thread_view)
					thread_view:view_attach()
				end, desc = "view attachment"},
				["q"] = { rhs = function (thread_view)
					thread_view:close(true)
				end, desc = "close window"},
				--- for_selected?
				["<leader>mh"] = { rhs = function (thread_view)
					local debug = require("galore.debug")
					local mid = thread_view:get_selected()
					debug.view_raw_mid(mid)
				end, desc = "show raw message"},
				["<C-n>"] = { rhs = function (thread_view)
					thread_view:next()
				end, desc = "next message"},
				["<C-p>"] = { rhs = function (thread_view)
					thread_view:prev()
				end, desc = "prev message"},
				["<C-t>"] = { rhs = function (thread_view)
					thread_view:message_view()
				end, desc = "jump to message view"},
				--- for_selected?
				["P"] = { rhs = function (thread_view)
					local mid = thread_view:get_selected()
					local message -- TODO
					vim.input({prompt = "Pipe message: "}, function (input)
						if input then
							local cmd = vim.fn.split(input, " ")
							local jobs = require("galore.jobs")
							jobs.pipe(cmd, message)
						end
					end)
				end, desc = "Pipe current message"},
			},
		},
		compose = {
			n = {
				["<leader>ms"] = { rhs =function (compose)
					compose:send()
				end, desc="Send email"},
				["<leader>ma"] = { rhs =function (compose)
					local tele = require("galore.telescope")
					tele.attach_file(compose)
				end, desc="Add attachment"},
				["<leader>md"] = { rhs = function (compose)
					compose:remove_attachment()
				end, desc="Delete attachment"},
				["<leader>mq"] = { rhs = function (compose)
					compose:save_draft()
				end, desc="Save draft"},
				["<leader>mo"] = { rhs = function (compose)
					compose:set_option_menu()
				end, desc="Set header option"},
				["<leader>mO"] = { rhs = function (compose)
					compose:unset_option()
				end, desc="Unset header option"},
				["<leader>mh"] = { rhs = function (compose)
					compose:preview()
				end, desc="preview email"},
				["gd"] = { rhs = function (compose)
					local telescope = require("galore.telescope")
					telescope.goto_message(compose)
				end, desc="goto in-reply-to"},
				["gD"] = { rhs = function (compose)
					local telescope = require("galore.telescope")
					--- Todo, there is no message in compose
					local mid = compose.message:get_message_id()
					telescope.goto_tree(mid)
				end, desc="goto tree"},
				["gR"] = { rhs = function (compose)
					local telescope = require("galore.telescope")
					--- Todo, there is no message in compose
					local mid = compose.message:get_message_id()
					telescope.goto_references(message_id)
				end, desc="goto References"},
			},
		},
		default = {
			n = {
				["q"] = function (buf)
					buf:close(true)
				end,
			}
		},
	},
	bufinit = {
		-- Should we not do this and use after/ftplugin?
		-- Or do both?
		saved = function (buffer)
		end,
		thread_message_browser = function (buffer)
		end,
		message_browser = function (buffer)
		end,
		thread_browser = function (buffer)
		end,
		message_view = function (buffer)
		end,
		thread_view = function (buffer)
		end,
		compose = function (buffer)
			-- BufWipout?
			-- vim.api.nvim_create_autocmd("BufDelete", {
			-- 	callback = function ()
			-- 		buffer:delete_tmp()
			-- 	end,
			-- 	buffer = buffer.handle})
			-- vim.api.nvim_create_autocmd("BufWritePost", {
			-- 	callback = function ()
			-- 		buffer:save_draft()
			-- 	end,
			-- 	buffer = buffer.handle})
			-- vim.api.nvim_create_autocmd("InsertLeave", {
			-- 	callback = function ()
			-- 		buffer:notify_encrypted()
			-- 	end,
			-- 	buffer = buffer.handle})
		end
	},
}

return config
