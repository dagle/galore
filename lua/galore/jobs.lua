local conf = require("galore.config")
local Job = require("plenary.job")

local M = {}

function M.new()
	Job
		:new({
			command = "notmuch",
			args = { "new" },
			on_exit = function(_, ret_val)
				if ret_val == 0 then
					print("Notmuch updated successfully")
				else
					print("Notmuch update failed")
				end
			end,
		})
		:start()
end

function M.get_type(file)
	local ret
	Job
		:new({
			command = "file",
			args = { "-b", "--mime-type", file },
			on_exit = function(j, _)
				ret = j:result()
			end,
		})
		:sync()
	local mime = M.collect(string.gmatch(ret[1], "([^/]+)"))
	if #mime ~= 2 then
		return nil
	end
	return unpack(mime)
end

function M.html(text)
	local ret
	Job
		:new({
			command = "html2text",
			args = {},
			writer = text,
			on_exit = function(j, _)
				ret = j:result()
			end,
		})
		:sync()
	return ret
end

function M.send_mail(to, from, message_str)
	local cmd, args = conf.values.send_cmd(to, from)
	Job
		:new({
			command = cmd,
			args = args,
			writer = message_str,
			on_exit = function(j, return_val)
				-- do something notify the user
				-- that the mail has fail or not
				print("mail sent!")
			end,
		})
		:start() -- or start()
end

return M
