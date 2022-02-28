local gmime = require("galore.gmime.gmime_ffi")
local ffi = require("ffi")

local M = {}

--- Convert an allocated malloced char * to a gced string
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

--- Do I need these if I do gc_nil?
--- XXX
function M.safe_unref(ptr)
	if ptr ~= nil then
		gmime.g_object_unref(ptr)
	end
end

--- Do I need these if I do gc_nil?
--- XXX
function M.safe_ref(ptr)
	if ptr ~= nil then
		gmime.g_object_ref(ptr)
	end
end

-- Do I need to do this?
-- XXX
function M.cast(str, mem)
	local ptr = M.gc_nil(ffi.cast(str, mem), gmime.g_object_unref)
	M.safe_ref(ptr)
	return ptr
end

-- DUP
function M.safestring(ptr)
	if ptr == nil then
		return nil
	end
	return ffi.string(ptr)
end

