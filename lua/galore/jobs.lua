local config = require("galore.config")
local runtime = require("galore.runtime")
local Job = require("plenary.job")
local u = require('galore.util')
local gu = require('galore.gmime.util')
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

--- XXX this should be done in glib
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

local function to_string(any)
	local object = ffi.cast("GMimeObject *", any)
	local mem = gs.stream_mem_new()
	go.object_write_to_stream(object, runtime.format_opts, mem)
	gs.stream_flush(mem)
	return gu.mem_to_string(mem)
end

--- XXX remove these string functions, in the future when the raw functions work
function M.send_mail_str(message)
	local message_str = to_string(message)
	local cmd, args = config.values.send_cmd()
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


function M.insert_mail_str(message, folder, tags)
	local message_str = to_string(message)
	local folderflag = string.format("--folder=%s", folder)
	local args = vim.tbl_flatten({"insert", "--create-folder", folderflag, tags})
	Job:new({
			command = "notmuch",
			args = args,
			writer = message_str,
			on_exit = function(j, return_val)
				  if return_val == 0 then
					vim.notify("Mail addedd to draft")
				  else
					local err = string.format("%s failed with error: %d", "notmuch insert", return_val)
					vim.notify(err, vim.log.levels.ERROR)
				  end
			end,
		})
		:start()
end

--- Add a callback to this?
--- TODO set env for testing etc
local function raw_pipe(object, cmd, args)
	local stdout = uv.new_pipe()
	local stderr = uv.new_pipe()
	local stdin = uv.new_pipe()

	local fds = uv.pipe({nonblock=true}, {nonblock=true})
	local stream = gs.stream_pipe_new(fds.write)
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
		if code ~= 0 then
			print(cmd .. " existed with: ", code)
			vim.notify(cmd .. " exited with: ".. tostring(code), vim.log.levels.ERROR)
		else
			vim.notify("Email sent")
		end
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
		go.object_write_to_stream(object, runtime.format_opts, stream)
	end

	gs.stream_flush(stream)
	gs.stream_close(stream)

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

	uv.shutdown(stdin, function()
		print("stdin shutdown", stdin)
		uv.close(handle, function()
			print("process closed", handle, pid)
		end)
	end)
end

function M.insert_mail(message, folder, tags)
	local object = ffi.cast("GMimeObject *", message)
	local parent_dir = config.values.select_dir(message)
	local folderflag = string.format("--folder=%s%s", parent_dir, folder)
	local args = vim.tbl_flatten({"insert", "--create-folder", folderflag, tags})
	raw_pipe(object, "notmuch", args)
end

--- being able to spawn in a terminal
function M.send_mail(message)
	local cmd, args = config.values.send_cmd(message)
	local object = ffi.cast("GMimeObject *", message)
	raw_pipe(object, cmd, args)
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

--- @param cmd string
--- @param obj gmime.MimeObject
function M.pipe(cmd, obj)
	local args = {unpack(cmd, 2)}
	raw_pipe(obj, cmd[1], args)
end

return M
