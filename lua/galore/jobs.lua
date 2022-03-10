local conf = require("galore.config")
local Job = require("plenary.job")
local u = require('galore.util')
local gs = require("galore.gmime.stream")
local gp = require("galore.gmime.parts")
local go = require("galore.gmime.object")
local ffi = require("ffi")
local uv = vim.loop

local M = {}

function M.new()
	Job
		:new({
			command = "notmuch",
			args = { "new" },
			on_exit = function(_, ret_val)
				if ret_val == 0 then
					vim.notify("Notmuch updated successfully")
				else
					vim.notify("Notmuch update failed", vim.log.levels.ERROR)
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
	local mime = u.collect(string.gmatch(ret[1], "([^/]+)"))
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

function M.w3m(text)
	local ret
	Job
		:new({
			command = "w3m",
			args = {"-dump", "-T", "text/html"},
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
				  if return_val == 0 then
					vim.notify("Mail sent")
				  else
					local err = string.format("%s failed with error: %d", cmd, return_val)
					vim.notify(err, vim.log.levels.ERROR)
				  end
			end,
		})
		:start()
end

local function raw_pipe(object, cmd, args)
	local stdout = uv.new_pipe()
	local stderr = uv.new_pipe()
	local fds = uv.pipe({nonblock=true}, {nonblock=true})
	local stream = gs.stream_pipe_new(fds.write)

	local opts = {}
	opts.args = args
	opts.stdio = { fds.read, stdout, stderr}

	local handle, pid = uv.spawn(cmd, opts, function(code, signal)
	end)

	--- Maybe something like this
	--- If you wanna pipe the buffer, don't use this
	if gp.is_part(object) then
		local part = ffi.cast("GMimePart *", object)
		if gp.part_is_attachment(part) then
			local dw = gp.part_get_content(part)
			gs.data_wrapper_write_to_stream(dw, stream)
		else
			local r = require("galore.render")
			r.part_to_stream(part, {}, stream)
		end
	else
		go.object_write_to_stream(object, nil, stream)
	end

	gs.stream_flush(stream)

	uv.read_start(stdout, function(err, data)
		assert(not err, err)
		if data then
			print(data)
		end
	end)

	uv.read_start(stderr, function(err, data)
		assert(not err, err)
		if data then
			print("stderr: ", data)
		end
	end)
end

--- use fg to spawn a terminal to display output when we want that

function M.send_mail_pipe(to, from, message)
	-- create a pipe
	local cmd, args = conf.values.send_cmd(to, from)
	local object = ffi.cast("GMimeObject *", message)
	raw_pipe(object, cmd, args)
end

--- @param cmd string
--- @param terminal boolean
--- @param obj gmime.MimeObject
function M.pipe(cmd, obj)
	-- local obj
	-- if not gp.is_part(part) then
	-- 	local message = ffi.cast("GMimeMessage *", part)
	-- 	obj = gp.message_get_body(message)
	-- end
	local args = {unpack(cmd, 2)}
	raw_pipe(obj, cmd[1], args)
end

return M
