---@diagnostic disable: undefined-field

local gmime = require("galore.gmime.gmime_ffi")
local ffi = require("ffi")

local M = {}

function M.strdup(mem)
	local str = ffi.string(mem)
	gmime.free(mem)
	return str
end

function M.gc_nil(var, func)
	if var ~= nil then
		return ffi.gc(var, func)
	end
end

function M.gbytes_str(gbyte)
	local size = ffi.new("gsize[1]")
	local data = gmime.g_bytes_get_data(gbyte, size);
	return ffi.string(data, size[0])
end

function M.safestring(ptr)
	if ptr == nil then
		return nil
	end
	return ffi.string(ptr)
end

function M.convert_error(err)
	if err == nil then
		return nil
	end
	local ret = {err.domain, err.code, ffi.string(err.message)}
	gmime.g_error_free(err)
	return ret
end

return M
