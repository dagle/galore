local config = {}

-- should read more stuff from notmuch config
config.values = {
	primary_email = "",
	other_email = {},
	db = nil,
	name = "",
	drafttag = "draft",
	draftdir = "Drafts", -- relative path of the bd!
	exclude_tags = "",
	saved_search = {},
	show_tags = true,
	threads_ratio = 0.6, -- just an idea to make it a bit
	bind_prefix = "", -- maybe
	thread_browser = true,
	verify_keys = "keyserver",
	validate_key = function (status)
		local convert = require("galore.gmime.convert")
		if convert.validate(status, "green") or convert.validate(status, "valid") then
			return true
		end
		return false
	end,
	-- autocrypt = true,
	reverse_thread = true,
	empty_topyic = "no topic",
	guess_email = false, -- if we can't determain your email use primary
	qoute_header = function(date, author)
		return "On " .. os.date("%Y-%m-%d ", date) .. author .. " wrote:"
	end,
	alt_mode = 1, -- for now, 0 never, 1 only render when there isn't an alternative and 2 always
	make_html = false,
	html_color = 0x878787,
	show_html = function(text)
		local jobs = require("galore.jobs")
		return jobs.html(text)
	end,
	signature = function()
		return nil
	end,
	tag_unread = function(message)
		local nu = require("galore.notmuch-util")
		return nu.tag_unread(message)
	end,
	sign = false,
	encrypt = false,
	gpg_id = "",
	headers = { -- order is important
		"From",
		"To",
		"Cc",
		"Date",
		"Subject",
	},
	send_cmd = function(to, from)
		from = from or "default"
		local start, stop = string.find(from, "@%a*.%a*")
		-- this only works if your entries is in the form of domain.tld
		if start == nil then
			return "msmtp", { "-a", "default", to }
		end
		local acc = string.sub(from, start+1, stop)
		return "msmtp", { "-a", acc, to }
	end,
	from_length = 25,
	show_message_descripiton = function(line)
	end,
	key_bindings = {
		global = {
			["<leader>mc"] = function ()
				require("galore.compose").create("tab")
			end,
			["<leader>mf"] = function ()
				require("galore.telescope").load_draft()
			end,
			["<leader>ms"] = function ()
				require("galore.telescope").notmuch_search()
			end,
			["<leader>mn"] = function ()
				require("galore.jobs").new()
			end,
		},
		search = {
			n = {
				["<CR>"] = function (saved)
					local cb = require("galore.callback")
					cb.select_search(saved, "replace")
				end,
				["q"] = function (saved)
					saved:close(true)
				end,
				["<C-v>"] = function (saved)
					local cb = require("galore.callback")
					cb.select_search(saved, "vsplit")
				end,
				["<C-x>"] = function (saved)
					local cb = require("galore.callback")
					cb.select_search(saved, "split")
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
				["<tab>"] = function (tmb)
					local cb = require("galore.callback")
					cb.toggle(tmb)
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
				["q"] = function (mb)
					mb:close(true)
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
					local tele = require("galore.telescope")
					local jobs = require("galore.jobs")
					local function cb(object)
						jobs.pipe({"cat"}, object)
						-- jobs.pipe({"gpg", "--import"}, object)
					end
					tele.parts_browser(message_view.message, cb)
				end,
				--- lsp inspired bindings
				["gd"] = function (message_view)
					local telescope = require("galore.telescope")
					telescope.goto_in_reply_to(message_view)
				end,
				["gD"] = function (message_view)
					local telescope = require("galore.telescope")
					telescope.goto_in_reply_tos(message_view.message)
				end,
				["gr"] = function (message_view)
					local telescope = require("galore.telescope")
					telescope.goto_reference(message_view.message)
				end,
				["gR"] = function (message_view)
					local telescope = require("galore.telescope")
					telescope.goto_references(message_view.message)
				end,
				["gM"] = function (message_view)
					local telescope = require("galore.telescope")
					telescope.goto_tree(message_view.message)
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
