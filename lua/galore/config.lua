local M = {}

function M.cb(fun)
  return string.format("<cmd>lua require'galore.callback'.call('%s')<cr>", fun)
end
-- function M.cb2(fun)
--   return string.format("<cmd>lua require'galore.callback'.%s<cr>", fun)
-- end

-- should read more stuff from notmuch config
M.values = {
	primary_email = "",
	other_email = {},
	db = nil,
	name = "",
	drafts = "drafts",
	exclude_tags = "",
	saved_search = {},
	show_tags = true,
	threads_open = "replace", -- maybe remove these
	threads_ratio = 0.6, -- just an idea to make it a bit
	message_open = "split",
	bind_prefix = "", -- maybe
	expand_threads = true,
	make_html = false,
	autocrypt = true,
	reverse_thread = true,
	qoute_header = function(date, author)
		return "On " .. os.date("%Y-%m-%d ", date) .. author .. " wrote:"
	end,
	from_string = function(email)
		return M.values.name .. " <" .. email .. ">"
	end,
	alt_mode = 1, -- for now, 0 never, 1 only render when there isn't an alternative and 2 always
	show_html = function (text) -- maybe it should give you a buffer etc to render better
		return text
	end,
	signature = function ()
		return nil
	end,
	tag_unread = function (_)
	end,
	sign = false,
	encrypt = false,
	gpg_id = "Testi McTest",
	headers = {
		'Subject', 'To', 'From', 'Date',
	},
	send_cmd = function(to, from)
		from = from or 'default'
		return "msmtp", {"-a", "default", to}
	end,
	-- need to support modes
	key_bindings = {
		global = {
			["<leader>mc"] = '<cmd>lua require("galore.compose").create("tab")<CR>',
			["<leader>mf"] = '<cmd>lua require("galore.telescope").load_draft()<CR>',
			["<leader>mn"] = '<cmd>lua require("galore.jobs").new()<CR>',
		},
		search = {
			n = {
				["<CR>"] = M.cb("select_search"),
				["q"] = M.cb("close_saved"),
				["<C-x>"] = M.cb("split_search"),
				["<C-v>"] = M.cb("vsplit_search"),
			},
		},
		thread_browser = {
			n = {
				["<CR>"] = M.cb("select_thread"),
				["q"] = M.cb("close_thread"),
			},
		},
		message_browser = {
			n = {
				["a"] = M.cb("change_tag"),
				["<CR>"] = M.cb("select_message"),
				["q"] = M.cb("close_thread"),
				["<tab>"] = M.cb("toggle"),
			},
		},
		message_view = {
			n = {
				["r"] = M.cb("message_reply"),
				["R"] = M.cb("message_reply_all"),
				["s"] = M.cb("save_attach"),
				["S"] = M.cb("view_attach"),
				["q"] = M.cb("close_message"),
				["<C-n>"] = M.cb("next"),
				["<C-p>"] = M.cb("prev"),
			},
		},
		thread_view= {
			["r"] = M.cb("message_reply"),
			["q"] = M.cb("close_message"),
		},
		compose = {
			n = {
				["<leader>ms"] = M.cb("compose_send"),
				["<leader>ma"] = M.cb("compose_add_attachment"),
			},
		},
	}
}

-- M.runtime = {}

return M
