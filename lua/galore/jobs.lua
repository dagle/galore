local config = require("galore.config")
local runtime = require("galore.runtime")
local Job = require("plenary.job")
local log = require("galore.log")

local lgi = require 'lgi'
local gmime = lgi.require("GMime", "3.0")

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
	return ret
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

-- add cols?
function M.w3m(text)
	local ret
	Job
		:new({
			command = "w3m",
			args = {"-dump", "-T", "text/html"},
			writer = text,
			on_exit = function(j, code, signal)
				ret = j:result()
			end,
		})
		:sync()
	return ret
end

function M.pipe_str(cmd, text)
	local args = {unpack(cmd, 2)}
	Job
		:new({
			command = cmd[1],
			args = args,
			writer = text,
			on_exit = function(j, code, signal)
			end,
		})
		:sync()
end

--- Add a callback to this?
--- TODO set env for testing etc
local function raw_pipe(object, cmd, args, cb)
	local stdout = uv.new_pipe()
	local stderr = uv.new_pipe()
	local stdin = uv.new_pipe()

	local fds = uv.pipe({nonblock=true}, {nonblock=true})
	-- local stream = gs.stream_pipe_new(fds.write)
	local stream = gmime.StreamPipe.new(fds.write)
	stdin:open(fds.read)
	local handle
	local pid

	local opts = {
		args = args,
		-- stdio = { fds.read, stdout, stderr}
		stdio = { stdin, stdout, stderr}
	}

	handle, pid = uv.spawn(cmd, opts, function(code, signal)
		stdin:close()
		stdout:close()
		stderr:close()
		vim.schedule(function()
			if code ~= 0 then
				log.log(cmd .. " exited with: ".. tostring(code), vim.log.levels.ERROR)
			else
				if cb then
					cb()
				end
			end
		-- add a cb here?
		end)
	end)

	--- Maybe something like this
	--- If you wanna pipe the buffer, don't use this
	--- this isn't async, but maybe it shouldn't be beacuse
	--- the function that calls raw_pipe should be async.
	--- since creating a message could be a pita too
	---
	--- TODO
	--- should I just vim.schedule() this?
	--- Nope! You should install a worker!
	-- if gp.is_part(object) then
	if gmime.Part:is_type_of(object) then
		local part = object
		if part:is_attachment() then
			local dw = part:get_content()
			dw:write_to_stream(stream)
		else
			local r = require("galore.render")
			r.part_to_stream(part, {}, stream)
		end
	else
		object:write_to_stream(runtime.format_opts, stream)
	end

	stream:flush()
	stream:close()
	-- gs.stream_flush(stream)
	-- gs.stream_close(stream)

	uv.read_start(stdout, function(err, data)
		assert(not err, err)
		-- we shouldn't really do anything with the data, maybe log it
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

	uv.shutdown(stdin, function()
		print("stdin shutdown", stdin)
		uv.close(handle, function()
			print("process closed", handle, pid)
		end)
	end)
end

function M.insert_mail(message, folder, tags)
	local parent_dir = config.values.select_dir(message)
	local folderflag = string.format("--folder=%s%s", parent_dir, folder)
	local args = vim.tbl_flatten({"insert", "--create-folder", folderflag, tags})
	raw_pipe(message, "notmuch", args)
end

--- being able to spawn in a terminal
function M.send_mail(message, cb)
	local cmd, args = config.values.send_cmd(message)
	raw_pipe(message, cmd, args, cb)
end

function M.pipe_input(object)
	vim.ui.input({
		prompt = "command: "
	}, function (ret)
		if ret ~= nil then
			local cmd = vim.split(ret, " ")
			raw_pipe(cmd, object)
		end
	end)
end

--- @param cmd string[]
--- @param obj gmime.MimeObject
function M.pipe(cmd, obj)
	local args = {unpack(cmd, 2)}
	raw_pipe(obj, cmd[1], args)
end

return M
