local gs = require("galore.gmime.stream")
local go = require("galore.gmime.object")
local runtime = require("galore.runtime")
local Buffer = require("galore.lib.buffer")
local gu = require("galore.gmime.util")
local ffi = require("ffi")
local ft = require("plenary.filetype")

local M = {}

--- Functions to aid in debugging.
--- Atm it's just functions to view raw messages

function M.view_raw_file(filename, kind)
	Buffer.create({
		name = filename,
		ft = "mail",
		kind = kind or "floating",
		cursor = "top",
		init = function(_)
			vim.cmd(":e " .. filename)
		end,
	})
end

function M.view_raw_attachment(name, part, kind)
	kind = kind or "floating"

	Buffer.create({
		name = name,
		ft = ft.detect(name),
		kind = kind or "floating",
		cursor = "top",
		init = function(buffer)
			M.attachment_view_buffer = buffer
			local buf = gu.part_to_buf(part)
			local fixed = vim.split(buf, "\n", false)
			buffer:set_lines(0, 0, true, fixed)
			buffer:set_lines(-2, -1, true, {})
		end,
	})
end

function M.view_raw_message(message, kind)
	if not message then
		return
	end
	local object = ffi.cast("GMimeObject *", message)
	local mem = gs.stream_mem_new()
	go.object_write_to_stream(object, runtime.format_opts, mem)
	gs.stream_flush(mem)
	local str = gu.mem_to_string(mem)
	local tbl = vim.split(str, "\n")
	Buffer.create({
		name = "Galore-preview",
		ft = "mail",
		kind = kind or "floating",
		cursor = "top",
		init = function(buffer)
			buffer:set_lines(0, 0, true, tbl)
		end,
	})
end

return M
