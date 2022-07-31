--- @diagnostic disable: undefined-field

local gmime = require("galore.gmime.gmime_ffi")
local convert = require("galore.gmime.convert")
local safe = require("galore.gmime.funcs")
local ffi = require("ffi")
local M = {}

--- @param options gmime.ParserOptions
--- @param content_type gmime.ContentType
--- @return gmime.MimeObject
function M.mime_object_new(options, content_type)
	return ffi.gc(gmime.g_mime_object_new(options, content_type), gmime.g_object_unref)
end

--- @param options gmime.ParserOptions
--- @param type string
--- @param subtype string
--- @return gmime.MimeObject
function M.object_new_type(options, type, subtype)
	return ffi.gc(gmime.g_mime_object_new_type(options, type, subtype), gmime.g_object_unref)
end

--- @param object gmime.MimeObject
--- @param content_type gmime.ContentType
function M.object_set_content_type(object, content_type)
	gmime.g_mime_object_set_content_type(object, content_type)
end

--- @param object gmime.MimeObject
--- @return gmime.ContentType
function M.object_get_content_type(object)
	return gmime.g_mime_object_get_content_type(object)
end

--- @param object gmime.MimeObject
--- @param name string
--- @param value string
function M.object_set_content_type_parameter(object, name, value)
	gmime.g_mime_object_set_content_type_parameter(object, name, value)
end

--- @param object gmime.MimeObject
--- @param name string
function M.object_get_content_type_parameter(object, name)
	return safe.safestring(gmime.g_mime_object_get_content_type_parameter(object, name))
end

--- @param object gmime.MimeObject
--- @param disposition gmime.ContentDisposition
function M.object_set_content_disposition(object, disposition)
	gmime.g_mime_object_set_content_disposition(object, disposition)
end

--- @param object gmime.MimeObject
--- @return gmime.ContentDisposition
function M.object_get_content_disposition(object)
	return gmime.g_mime_object_get_content_disposition(object)
end

--- @param object gmime.MimeObject
--- @param disposition string
function M.object_set_disposition(object, disposition)
	gmime.g_mime_object_set_disposition(object, disposition)
end

--- @param object gmime.MimeObject
--- @return string
function M.object_get_disposition(object)
	return safe.safestring(gmime.g_mime_object_get_disposition(object))
end

--- @param object gmime.MimeObject
--- @param name string
--- @param value string
function M.object_set_content_disposition_parameter(object, name, value)
	gmime.g_mime_object_set_content_disposition_parameter(object, name, value)
end

--- @param object gmime.MimeObject
--- @param name string
--- @return string
function M.object_get_content_disposition_parameter(object, name)
	return ffi.string(gmime.g_mime_object_get_content_disposition_parameter(object, name))
end

--- @param object gmime.MimeObject
--- @param content_id string
function M.object_set_content_id(object, content_id)
	gmime.g_mime_object_set_content_id(object, content_id)
end

--- @param object gmime.MimeObject
--- @return string
function M.object_get_content_id(object)
	gmime.g_mime_object_get_content_id(object)
end

--- @param object gmime.MimeObject
--- @param header string
--- @param value string
--- @param charset string
function M.object_prepend_header(object, header, value, charset)
	gmime.g_mime_object_prepend_header(object, header, value, charset)
end

--- @param object gmime.MimeObject
--- @param header string
--- @param value string
--- @param charset string
function M.object_append_header(object, header, value, charset)
	gmime.g_mime_object_append_header(object, header, value, charset)
end

--- @param object gmime.MimeObject
--- @param header string
--- @param value string
--- @param charset string|nil
function M.object_set_header(object, header, value, charset)
	gmime.g_mime_object_set_header(object, header, value, charset)
end

--- @param object gmime.MimeObject
--- @param header string
--- @return string
function M.object_get_header(object, header)
	return safe.safestring(gmime.g_mime_object_get_header(object, header))
end

--- @param object gmime.MimeObject
--- @param header string
--- @return boolean
function M.object_remove_header(object, header)
	return gmime.g_mime_object_remove_header(object, header) ~= 0
end

--- @param object gmime.MimeObject
--- @return gmime.HeaderList
function M.object_get_header_list(object)
	return gmime.g_mime_object_get_header_list(object)
end

--- @param object gmime.MimeObject
--- @param options gmime.FormatOptions
--- @return string
function M.object_get_headers(object, options)
	local mem = gmime.g_mime_object_get_headers(object, options)
	return convert.strdup(mem)
end

--- @param object gmime.MimeObject
--- @param options gmime.FormatOptions
--- @param stream gmime.Stream
--- @return number
function M.object_write_to_stream(object, options, stream)
	return gmime.g_mime_object_write_to_stream(object, options, stream)
end

--- @param object gmime.MimeObject
--- @param options gmime.FormatOptions
--- @param stream gmime.Stream
--- @return number
function M.object_write_content_to_stream(object, options, stream)
	return gmime.g_mime_object_write_content_to_stream(object, options, stream)
end

--- @param object gmime.MimeObject
--- @param options gmime.FormatOptions
--- @return number
function M.object_to_string(object, options)
	local mem = gmime.g_mime_object_to_string(object, options)
	return convert.strdup(mem)
end

--- @param object gmime.MimeObject
--- @param constraint gmime.EncodingConstraint
function M.object_encode(object, constraint)
	gmime.g_mime_object_encode(object, constraint)
end

--- @param object any
function M.g_object_unref(object)
	gmime.g_object_unref(object)
end

return M
