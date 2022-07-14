---@diagnostic disable: undefined-field

local gmime = require("galore.gmime.gmime_ffi")
local convert = require("galore.gmime.convert")
local safe = require("galore.gmime.funcs")
local ffi = require("ffi")

local M = {}

--- @return gmime.Parser
function M.parser_new()
	return ffi.gc(gmime.g_mime_parser_new(), gmime.g_object_unref)
end

--- @param stream gmime.Stream
--- @return gmime.Parser
function M.parser_new_with_stream(stream)
	return ffi.gc(gmime.g_mime_parser_new_with_stream(stream), gmime.g_object_unref)
end

--- @param parser gmime.Parser
--- @param stream gmime.Stream
function M.parser_init_with_stream(parser, stream)
	gmime.g_mime_parser_init_with_stream(parser, stream)
end

--- @param parser gmime.Parser
--- @return boolean
function M.parser_get_persist_stream(parser)
	return gmime.g_mime_parser_get_persist_stream(parser) ~= 0
end

--- @param parser gmime.Parser
--- @param persist boolean
function M.parser_set_persist_stream(parser, persist)
	gmime.g_mime_parser_set_persist_stream(parser, persist)
end

--- @param parser gmime.Parser
--- @return gmime.Format
function M.parser_get_format(parser)
	return gmime.g_mime_parser_get_format(parser)
end

--- @param parser gmime.Parser
--- @param format gmime.Format
function M.parser_set_format(parser, format)
	gmime.g_mime_parser_set_format(parser, format)
end

--- @param parser gmime.Parser
--- @return boolean
function M.parser_get_respect_content_length(parser)
	return gmime.g_mime_parser_get_respect_content_length(parser) ~= 0
end

--- @param parser gmime.Parser
--- @param respect_length boolean
function M.parser_set_respect_content_length(parser, respect_length)
	gmime.g_mime_parser_set_respect_content_length(parser, respect_length)
end

--- @param parser gmime.Parser
--- @param regex string
--- @param cb fun(gmime.Parse, string, string, number, any)
--- @param data any
function M.parser_set_header_regex(parser, regex, cb, data)
	gmime.g_mime_parser_set_header_regex(parser, regex, cb, data)
end

--- @param parser gmime.Parser
--- @param options gmime.ParserOptions
--- @return gmime.MimeObject
function M.parser_construct_part(parser, options)
	return gmime.g_mime_parser_construct_part(parser, options)
end

--- @param parser gmime.Parser
--- @param options gmime.ParserOptions
--- @return gmime.Message
function M.parser_construct_message(parser, options)
	return gmime.g_mime_parser_construct_message(parser, options)
end

--- @param parser gmime.Parser
--- @return number
function M.parser_tell(parser)
	return gmime.g_mime_parser_tell(parser)
end

--- @param parser gmime.Parser
--- @return boolean
function M.parser_eos(parser)
	return gmime.g_mime_parser_eos(parser) ~= 0
end

--- @param parser gmime.Parser
--- @return string
function M.parser_get_mbox_marker(parser)
	return ffi.string(gmime.g_mime_parser_get_mbox_marker(parser))
end

--- @param parser gmime.Parser
--- @return number
function M.parser_get_mbox_marker_offset(parser)
	return gmime.g_mime_parser_get_mbox_marker_offset(parser)
end

--- @param parser gmime.Parser
--- @return number
function M.parser_get_headers_begin(parser)
	return gmime.g_mime_parser_get_headers_begin(parser)
end

--- @param parser gmime.Parser
--- @return number
function M.parser_get_headers_end(parser)
	return gmime.g_mime_parser_get_headers_end(parser)
end

--- @param stream gmime.Stream
--- @param start number
--- @param stop number
function M.stream_construct(stream, start, stop)
	gmime.g_mime_stream_construct(stream, start, stop)
end

--- @param stream gmime.Stream
--- @param len number
--- @return string, number
function M.stream_read(stream, len)
	local buf = ffi.new("char[?]", len)
	local ret = tonumber(gmime.g_mime_stream_read(stream, buf, len))
	local str = ffi.string(buf)
	return str, ret
end

--- @param stream gmime.Stream
--- @param string string
--- @return number
function M.stream_write(stream, string)
	return tonumber(gmime.e_stream_write(stream, string, #string))
end

--- @param stream gmime.Stream
--- @return number
function M.stream_flush(stream)
	return gmime.g_mime_stream_flush(stream)
end

--- @param stream gmime.Stream
--- @return number
function M.stream_close(stream)
	return gmime.g_mime_stream_close(stream)
end

--- @param stream gmime.Stream
--- @return boolean
function M.stream_eos(stream)
	return gmime.g_mime_stream_eos(stream) ~= 0
end

--- @param stream gmime.Stream
--- @return number
function M.stream_reset(stream)
	return gmime.g_mime_stream_reset(stream)
end

--- @param stream gmime.Stream
--- @param offset number
--- @param whence gmime.SeekWhence
--- @return number
function M.stream_seek(stream, offset, whence)
	return gmime.g_mime_stream_seek(stream, offset, whence)
end

--- @param stream gmime.Stream
--- @return number
function M.stream_tell(stream)
	return gmime.g_mime_stream_tell(stream)
end

--- @param stream gmime.Stream
--- @return number
function M.stream_length(stream)
	return gmime.g_mime_stream_length(stream)
end

--- @param stream gmime.Stream
--- @param start number
--- @param stop stop
--- @return gmime.Stream
function M.stream_substream(stream, start, stop)
	return ffi.gc(gmime.g_mime_stream_substream(stream, start, stop), gmime.g_object_unref)
end

--- @param stream gmime.Stream
--- @param start number
--- @param stop stop
function M.stream_set_bounds(stream, start, stop)
	gmime.g_mime_stream_set_bounds(stream, start, stop)
end

--- @param stream gmime.Stream
--- @param str string
--- @return number
function M.stream_write_string(stream, str)
	return tonumber(gmime.g_mime_stream_write_string(stream, str))
end

--- @param stream gmime.Stream
--- @param fmt string
--- @param ... any
--- @return number
function M.stream_printf(stream, fmt, ...)
	return tonumber(gmime.g_mime_stream_printf(stream, fmt, ...))
end

--- @param src gmime.Stream
--- @param dest gmime.Stream
--- @return number
function M.stream_write_to_stream(src, dest)
	return gmime.g_mime_stream_write_to_stream(src, dest)
end

--- @param fd number
--- @return gmime.Stream
function M.stream_fs_new(fd)
	return ffi.gc(gmime.g_mime_stream_fs_new(fd), gmime.g_object_unref)
end

--- @param fd number
--- @param start number
--- @param stop number
--- @return gmime.Stream
function M.stream_fs_new_with_bounds(fd, start, stop)
	return ffi.gc(gmime.g_mime_stream_fs_new_with_bounds(fd, start, stop), gmime.g_object_unref)
end

--- @param path string
--- @param flags number
--- @param mode number
--- @return gmime.Stream, gmime.Error
function M.stream_fs_open(path, flags, mode)
	local err = ffi.new("GError*[1]")
	local res = gmime.g_mime_stream_fs_open(path, flags, mode, err)
	return ffi.gc(res, gmime.g_object_unref), safe.convert_error(err[0])
end

--- @param stream gmime.Stream
--- @return boolean
function M.stream_fs_get_owner(stream)
	return gmime.g_mime_stream_fs_get_owner(stream) ~= 0
end

--- @param stream gmime.Stream
--- @param owner boolean
function M.stream_fs_set_owner(stream, owner)
	gmime.g_mime_stream_fs_set_owner(stream, owner)
end

--- @return gmime.Stream
function M.stream_cat_new()
	return ffi.gc(gmime.g_mime_stream_cat_new(), gmime.g_object_unref)
end

--- @param cat gmime.StreamCat
--- @param source gmime.Stream
--- @return number
function M.stream_cat_add_source(cat, source)
	return gmime.g_mime_stream_cat_add_source(cat, source)
end

--- @return gmime.Stream
function M.stream_mem_new()
	return gmime.g_mime_stream_mem_new()
end

--- @param array gmime.ByteArray
--- @return gmime.Stream
function M.stream_mem_new_with_byte_array(array)
	return ffi.gc(gmime.g_mime_stream_mem_new_with_byte_array(array), gmime.g_object_unref)
end

--- @param buf string
--- @return gmime.Stream
function M.stream_mem_new_with_buffer(buf)
	return ffi.gc(gmime.g_mime_stream_mem_new_with_buffer(buf, #buf), gmime.g_object_unref)
end

--- @param mem gmime.StreamMem
--- @return gmime.ByteArray
function M.stream_mem_get_byte_array(mem)
	return gmime.g_mime_stream_mem_get_byte_array(mem)
end

--- @param mem gmime.StreamMem
--- @param array gmime.ByteArray
function M.stream_mem_set_byte_array(mem, array)
	gmime.g_mime_stream_mem_set_byte_array(mem, array)
end

--- @param mem gmime.StreamMem
--- @return boolean
function M.stream_mem_get_owner(mem)
	return gmime.g_mime_stream_mem_get_owner(mem) ~= 0
end

--- @param mem gmime.StreamMem
--- @param owner boolean
function M.stream_mem_set_owner(mem, owner)
	gmime.g_mime_stream_mem_set_owner(mem, owner)
end

--- @param path string
--- @param mode string
--- @return gmime.Stream, gmime.Error
--- XXX free error
function M.stream_file_open(path, mode)
	local err = ffi.new("GError*[1]")
	local ret = gmime.g_mime_stream_file_open(path, mode, err)
	return ffi.gc(ret, gmime.g_object_unref), safe.convert_error(err[0])
end

--- @param stream gmime.Stream
--- @return boolean
function M.stream_file_get_owner(stream)
	return gmime.g_mime_stream_file_get_owner(stream)
end

--- @param stream gmime.Stream
--- @param owner boolean
function M.stream_file_set_owner(stream, owner)
	gmime.g_mime_stream_file_set_owner(stream, owner)
end

--- @param fd number
--- @param prot number
--- @param flags number
--- @return gmime.Stream
function M.stream_mmap_new(fd, prot, flags)
	return ffi.gc(gmime.g_mime_stream_mmap_new(fd, prot, flags), gmime.g_object_unref)
end

--- @param fd number
--- @param prot number
--- @param flags number
--- @param start number
--- @param stop number
--- @return gmime.Stream
function M.stream_mmap_new_with_bounds(fd, prot, flags, start, stop)
	return ffi.gc(gmime.g_mime_stream_mmap_new_with_bounds(fd, prot, flags, start, stop), gmime.g_object_unref)
end

--- @param stream gmime.StreamMmap
--- @return boolean
function M.stream_mmap_get_owner(stream)
	return gmime.g_mime_stream_mmap_get_owner(stream) ~= 0
end

--- @param stream gmime.StreamMmap
--- @param owner boolean
function M.stream_mmap_set_owner(stream, owner)
	gmime.g_mime_stream_mmap_set_owner(stream, owner)
end

--- @return gmime.Stream
function M.stream_null_new()
	return ffi.gc(gmime.g_mime_stream_null_new(), gmime.g_object_unref)
end

--- @param stream gmime.StreamNull
--- @param count boolean
function M.stream_null_set_count_newlines(stream, count)
	gmime.g_mime_stream_null_set_count_newlines(stream, count)
end

--- @param stream gmime.StreamNull
--- @return boolean
function M.stream_null_get_count_newlines(stream)
	return gmime.g_mime_stream_null_get_count_newlines(stream) ~= 0
end

--- @param fd number
--- @return gmime.Stream
function M.stream_pipe_new(fd)
	return ffi.gc(gmime.g_mime_stream_pipe_new(fd), gmime.g_object_unref)
end

--- @param stream gmime.StreamPipe
function M.stream_pipe_get_owner(stream)
	return gmime.g_mime_stream_pipe_get_owner(stream)
end

--- @param stream gmime.StreamPipe
--- @param owner boolean
function M.stream_pipe_set_owner(stream, owner)
	gmime.g_mime_stream_pipe_set_owner(stream, owner)
end

--- @param source gmime.Stream
--- @param mode gmime.StreamBufferMode
function M.stream_buffer_new(source, mode)
	return ffi.gc(gmime.g_mime_stream_buffer_new(source, mode), gmime.g_object_unref)
end

--- @param stream gmime.Stream
--- @param len number
--- @return string, number
function M.stream_buffer_gets(stream, len)
	local buf = ffi.new("char[?]", len)
	local num = tonumber(gmime.stream_buffer_gets(stream, buf, len))
	local str = ffi.string(buf, num)
	return str, num
end

--- @param stream gmime.Stream
--- @return string
function M.stream_buffer_readln(stream)
	local buf = gmime.g_byte_array_new()
	gmime.g_mime_stream_buffer_readln(stream, buf)
	local str = ffi.string(buf.data, buf.len)
	gmime.g_byte_array_free(buf)
	return str
end

--- @param stream gmime.Stream
--- @return gmime.Stream
function M.stream_filter_new(stream)
	return ffi.gc(gmime.g_mime_stream_filter_new(stream), gmime.g_object_unref)
end

--- @param stream gmime.StreamFilter
--- @param filter gmime.Filter
--- @return number
function M.stream_filter_add(stream, filter)
	return gmime.g_mime_stream_filter_add(stream, filter)
end

--- @param stream gmime.StreamFilter
--- @param id number
function M.stream_filter_remove(stream, id)
	gmime.g_mime_stream_filter_remove(stream, id)
end

--- @param stream gmime.StreamFilter
--- @param owner boolean
function M.stream_filter_set_owner(stream, owner)
	gmime.g_mime_stream_filter_set_owner(stream, owner)
end

--- @param stream gmime.StreamFilter
--- @return boolean
function M.stream_filter_get_owner(stream)
	return gmime.g_mime_stream_filter_get_owner(stream) ~= 0
end

--- @return gmime.DataWrapper
function M.data_wrapper_new()
	return ffi.gc(gmime.g_mime_data_wrapper_new(), gmime.g_object_unref)
end

--- @param stream gmime.Stream
--- @param encoding gmime.ContentEncoding
--- @return gmime.DataWrapper
function M.data_wrapper_new_with_stream(stream, encoding)
	local eencoding = convert.to_encoding(encoding)
	return gmime.g_mime_data_wrapper_new_with_stream(stream, eencoding)
end

--- @param wrapper gmime.DataWrapper
--- @param stream gmime.Stream
function M.data_wrapper_set_stream(wrapper, stream)
	gmime.g_mime_data_wrapper_set_stream(wrapper, stream)
end

--- @param wrapper gmime.DataWrapper
--- @return gmime.Stream
function M.data_wrapper_get_stream(wrapper)
	return gmime.g_mime_data_wrapper_get_stream(wrapper)
end

--- @param wrapper gmime.DataWrapper
--- @param encoding gmime.ContentEncoding
function M.data_wrapper_set_encoding(wrapper, encoding)
	gmime.g_mime_data_wrapper_set_encoding(wrapper, encoding)
end

--- @param wrapper gmime.DataWrapper
--- @return gmime.ContentEncoding
function M.data_wrapper_get_encoding(wrapper)
	return gmime.g_mime_data_wrapper_get_encoding(wrapper)
end

--- @param wrapper gmime.DataWrapper
--- @param stream gmime.Stream
--- @return number
function M.data_wrapper_write_to_stream(wrapper, stream)
	return gmime.g_mime_data_wrapper_write_to_stream(wrapper, stream)
end
--
return M
