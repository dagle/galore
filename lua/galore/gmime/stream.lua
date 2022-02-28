--- XXX todo is the buf stuff
local gmime = require("galore.gmime.gmime_ffi")
local ffi = require("ffi")

local M = {}
--
-- GMimeParser *g_mime_parser_new (void);
--- @return gmime.Parser
function M.parser_new()
	return ffi.gc(gmime.g_mime_parser_new(), gmime.g_object_unref)
end
-- GMimeParser *g_mime_parser_new_with_stream (GMimeStream *stream);
--- @param stream gmime.Stream
--- @return gmime.Parser
function M.parser_new_with_stream(stream)
	return ffi.gc(gmime.g_mime_parser_new_with_stream(stream), gmime.g_object_unref)
end
--
-- void g_mime_parser_init_with_stream (GMimeParser *parser, GMimeStream *stream);
--- @param parser gmime.Parser
--- @param stream gmime.Stream
function M.parser_init_with_stream(parser, stream)
	gmime.g_mime_parser_init_with_stream(parser, stream)
end
--
-- gboolean g_mime_parser_get_persist_stream (GMimeParser *parser);
--- @param parser gmime.Parser
--- @return boolean
function M.parser_get_persist_stream(parser)
	return gmime.g_mime_parser_get_persist_stream(parser) ~= 0
end

-- void g_mime_parser_set_persist_stream (GMimeParser *parser, gboolean persist);
--- @param parser gmime.Parser
--- @param persist boolean
function M.parser_set_persist_stream(parser, persist)
	gmime.g_mime_parser_set_persist_stream(parser, persist)
end

-- GMimeFormat g_mime_parser_get_format (GMimeParser *parser);
--- @param parser gmime.Parser
--- @return gmime.Format
function M.parser_get_format(parser)
	return gmime.g_mime_parser_get_format(parser)
end

-- void g_mime_parser_set_format (GMimeParser *parser, GMimeFormat format);
--- @param parser gmime.Parser
--- @param format gmime.Format
function M.parser_set_format(parser, format)
	gmime.g_mime_parser_set_format(parser, format)
end
--
-- gboolean g_mime_parser_get_respect_content_length (GMimeParser *parser);
--- @param parser gmime.Parser
--- @return boolean
function M.parser_get_respect_content_length(parser)
	return gmime.g_mime_parser_get_respect_content_length(parser) ~= 0
end

-- void g_mime_parser_set_respect_content_length (GMimeParser *parser, gboolean respect_content_length);
--- @param parser gmime.Parser
--- @param respect_length boolean
function M.parser_set_respect_content_length(parser, respect_length)
	gmime.g_mime_parser_set_respect_content_length(parser, respect_length)
end

-- void g_mime_parser_set_header_regex (GMimeParser *parser, const char *regex,
-- 				     GMimeParserHeaderRegexFunc header_cb,
-- 				     gpointer user_data);
--- @param parser gmime.Parser
--- @param regex string
--- @param cb fun(gmime.Parse, string, string, number, any)
--- @param data any
function M.parser_set_header_regex(parser, regex, cb, data)
	gmime.g_mime_parser_set_header_regex(parser, regex, cb, data)
end

-- GMimeObject *g_mime_parser_construct_part (GMimeParser *parser, GMimeParserOptions *options);
--- @param parser gmime.Parser
--- @param options gmime.ParserOptions
--- @return gmime.MimeObject
function M.parser_construct_part(parser, options)
	return gmime.g_mime_parser_construct_part(parser, options)
end

-- GMimeMessage *g_mime_parser_construct_message (GMimeParser *parser, GMimeParserOptions *options);
--- @param parser gmime.Parser
--- @param options gmime.ParserOptions
--- @return gmime.Message
function M.parser_construct_message(parser, options)
	return gmime.g_mime_parser_construct_message(parser, options)
end

-- gint64 g_mime_parser_tell (GMimeParser *parser);
--- @param parser gmime.Parser
--- @return number
function M.parser_tell(parser)
	return gmime.g_mime_parser_tell(parser)
end

-- gboolean g_mime_parser_eos (GMimeParser *parser);
--- @param parser gmime.Parser
--- @return boolean
function M.parser_eos(parser)
	return gmime.g_mime_parser_eos(parser) ~= 0
end

-- char *g_mime_parser_get_mbox_marker (GMimeParser *parser);
--- @param parser gmime.Parser
--- @return string
function M.parser_get_mbox_marker(parser)
	return ffi.string(gmime.g_mime_parser_get_mbox_marker(parser))
end

-- gint64 g_mime_parser_get_mbox_marker_offset (GMimeParser *parser);
--- @param parser gmime.Parser
--- @return number
function M.parser_get_mbox_marker_offset(parser)
	return gmime.g_mime_parser_get_mbox_marker_offset(parser)
end

-- gint64 g_mime_parser_get_headers_begin (GMimeParser *parser);
--- @param parser gmime.Parser
--- @return number
function M.parser_get_headers_begin(parser)
	return gmime.g_mime_parser_get_headers_begin(parser)
end

-- gint64 g_mime_parser_get_headers_end (GMimeParser *parser);
--- @param parser gmime.Parser
--- @return number
function M.parser_get_headers_end(parser)
	return gmime.g_mime_parser_get_headers_end(parser)
end

--- @param stream gmime.Stream
--- @param start number
--- @param stop number
-- void g_mime_stream_construct (GMimeStream *stream, gint64 start, gint64 end);
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

-- int       g_mime_stream_flush   (GMimeStream *stream);
--- @param stream gmime.Stream
--- @return number
function M.stream_flush(stream)
	return gmime.g_mime_stream_flush(stream)
end

-- int       g_mime_stream_close   (GMimeStream *stream);
--- @param stream gmime.Stream
--- @return number
function M.stream_close(stream)
	return gmime.g_mime_stream_close(stream)
end

-- gboolean  g_mime_stream_eos     (GMimeStream *stream);
--- @param stream gmime.Stream
--- @return boolean
function M.stream_eos(stream)
	return gmime.g_mime_stream_eos(stream) ~= 0
end

-- int       g_mime_stream_reset   (GMimeStream *stream);
--- @param stream gmime.Stream
--- @return number
function M.stream_reset(stream)
	return gmime.g_mime_stream_reset(stream)
end

-- gint64    g_mime_stream_seek    (GMimeStream *stream, gint64 offset, GMimeSeekWhence whence);
--- @param stream gmime.Stream
--- @param offset number
--- @param whence gmime.SeekWhence
--- @return number
function M.stream_seek(stream, offset, whence)
	return gmime.g_mime_stream_seek(stream, offset, whence)
end

-- gint64    g_mime_stream_tell    (GMimeStream *stream);
--- @param stream gmime.Stream
--- @return number
function M.stream_tell(stream)
	return gmime.g_mime_stream_tell(stream)
end

-- gint64    g_mime_stream_length  (GMimeStream *stream);
--- @param stream gmime.Stream
--- @return number
function M.stream_length(stream)
	return gmime.g_mime_stream_length(stream)
end

-- GMimeStream *g_mime_stream_substream (GMimeStream *stream, gint64 start, gint64 end);
--- @param stream gmime.Stream
--- @param start number
--- @param stop stop
--- @return gmime.Stream
function M.stream_substream(stream, start, stop)
	return gmime.g_mime_stream_substream(stream, start, stop)
end

-- void      g_mime_stream_set_bounds (GMimeStream *stream, gint64 start, gint64 end);
--- @param stream gmime.Stream
--- @param start number
--- @param stop stop
function M.stream_set_bounds(stream, start, stop)
	gmime.g_mime_stream_set_bounds(stream, start, stop)
end

-- ssize_t   g_mime_stream_write_string (GMimeStream *stream, const char *str);
--- @param stream gmime.Stream
--- @param str string
--- @return number
function M.stream_write_string(stream, str)
	return tonumber(gmime.g_mime_stream_write_string(stream, str))
end

-- ssize_t   g_mime_stream_printf       (GMimeStream *stream, const char *fmt, ...);
--- @param stream gmime.Stream
--- XXX
function M.stream_printf(stream, fmt, ...)
	return tonumber(gmime.g_mime_stream_printf(stream, fmt, ...))
end
--
-- gint64    g_mime_stream_write_to_stream (GMimeStream *src, GMimeStream *dest);
--- @param src gmime.Stream
--- @param dest gmime.Stream
function M.stream_write_to_stream(src, dest)
	return gmime.g_mime_stream_write_to_stream(src, dest)
end
--
-- gint64    g_mime_stream_writev (GMimeStream *stream, GMimeStreamIOVector *vector, size_t count);
--- XXX
-- function M.stream_writev(stream)
-- 	return gmime.g_mime_stream_writev(stream)
-- end
--
-- GMimeStream *g_mime_stream_fs_new (int fd);
--- @param fd number
--- @return gmime.Stream
function M.stream_fs_new(fd)
	return ffi.gc(gmime.g_mime_stream_fs_new(fd), gmime.g_object_unref)
end
-- GMimeStream *g_mime_stream_fs_new_with_bounds (int fd, gint64 start, gint64 end);
--- @param fd number
--- @param start number
--- @param stop number
--- @return gmime.Stream
function M.stream_fs_new_with_bounds(fd, start, stop)
	return ffi.gc(gmime.g_mime_stream_fs_new_with_bounds(fd, start, stop), gmime.g_object_unref)
end
--
-- GMimeStream *g_mime_stream_fs_open (const char *path, int flags, int mode, GError **err);
--- @param path string
--- @param flags number
--- @param mode number
--- @return gmime.Stream, gmime.Error
function M.stream_fs_open(path, flags, mode)
	local err = ffi.new("GError*[1]")
	local res = gmime.g_mime_stream_fs_open(path, flags, mode, err)
	return ffi.gc(res, gmime.g_object_unref), err[0]
end
--
-- gboolean g_mime_stream_fs_get_owner (GMimeStreamFs *stream);
--- @param stream gmime.Stream
--- @return boolean
function M.stream_fs_get_owner(stream)
	return gmime.g_mime_stream_fs_get_owner(stream) ~= 0
end
-- void g_mime_stream_fs_set_owner (GMimeStreamFs *stream, gboolean owner);
--- @param stream gmime.Stream
--- @param owner boolean
function M.stream_fs_set_owner(stream, owner)
	gmime.g_mime_stream_fs_set_owner(stream, owner)
end
--
-- GMimeStream *g_mime_stream_cat_new (void);
--- @return gmime.Stream
function M.stream_cat_new()
	return ffi.gc(gmime.g_mime_stream_cat_new(), gmime.g_object_unref)
end
--
-- int g_mime_stream_cat_add_source (GMimeStreamCat *cat, GMimeStream *source);
--- @param cat gmime.StreamCat
--- @param source gmime.Stream
--- @return number
function M.stream_cat_add_source(cat, source)
	return gmime.g_mime_stream_cat_add_source(cat, source)
end
--
-- GMimeStream *g_mime_stream_mem_new (void);
--- @return gmime.Stream
function M.stream_mem_new()
	return gmime.g_mime_stream_mem_new()
end

-- GMimeStream *g_mime_stream_mem_new_with_byte_array (GByteArray *array);
--- XXX
-- function M.stream_mem_new_with_byte_array()
-- 	return gmime.g_mime_stream_mem_new_with_byte_array()
-- end

--- Use a buffer as a stream, example:
--- local buf = ffi.new("char[?]", len)
--- gs.stream_mem_new_with_buffer(buf, len)
-- function M.stream_mem_new_with_buffer(buf, len)
-- 	return gmime.g_mime_stream_mem_new_with_buffer(buf, len)
-- end
-- --
-- -- GByteArray *g_mime_stream_mem_get_byte_array (GMimeStreamMem *mem);
-- --- XXX
-- function M.stream_mem_get_byte_array()
-- 	return gmime.g_mime_stream_mem_get_byte_array()
-- end
--
-- -- void g_mime_stream_mem_set_byte_array (GMimeStreamMem *mem, GByteArray *array);
-- --- XXX
-- function M.stream_mem_set_byte_array()
-- 	gmime.g_mime_stream_mem_set_byte_array()
-- end
--
-- -- gboolean g_mime_stream_mem_get_owner (GMimeStreamMem *mem);
-- --- XXX
-- function M.stream_mem_get_owner()
-- 	gmime.g_mime_stream_mem_get_owner()
-- end
--
-- -- void g_mime_stream_mem_set_owner (GMimeStreamMem *mem, gboolean owner);
-- --- XXX
-- function M.stream_mem_set_owner()
-- 	gmime.g_mime_stream_mem_set_owner()
-- end
--
-- --- XXX
-- -- GMimeStream *g_mime_stream_file_new (FILE *fp);
-- function M.stream_file_new()
-- 	return g_mime_stream_file_new()
-- end
--
-- -- GMimeStream *g_mime_stream_file_new_with_bounds (FILE *fp, gint64 start, gint64 end);
-- --- XXX
-- function M.stream_file_new_with_bounds()
-- end

-- GMimeStream *g_mime_stream_file_open (const char *path, const char *mode, GError **err);
--- @param path string
--- @param mode string
--- @return gmime.Stream, gmime.Error
function M.stream_file_open(path, mode)
	local err = ffi.new("GError*[1]")
	local ret = gmime.g_mime_stream_file_open(path, mode, err)
	return ffi.gc(ret, gmime.g_object_unref), err[0]
end

-- gboolean g_mime_stream_file_get_owner (GMimeStreamFile *stream);
--- @param stream gmime.Stream
--- @return boolean
function M.stream_file_get_owner(stream)
	return gmime.g_mime_stream_file_get_owner(stream)
end

-- void g_mime_stream_file_set_owner (GMimeStreamFile *stream, gboolean owner);
--- @param stream gmime.Stream
--- @param owner boolean
function M.stream_file_set_owner(stream, owner)
	gmime.g_mime_stream_file_set_owner(stream, owner)
end

-- GMimeStream *g_mime_stream_mmap_new (int fd, int prot, int flags);
--- @param fd number
--- @param prot number
--- @param flags number
--- @return gmime.Stream
function M.stream_mmap_new(fd, prot, flags)
	return ffi.gc(gmime.g_mime_stream_mmap_new(fd, prot, flags), gmime.g_object_unref)
end

-- GMimeStream *g_mime_stream_mmap_new_with_bounds (int fd, int prot, int flags, gint64 start, gint64 end);
--- @param fd number
--- @param prot number
--- @param flags number
--- @param start number
--- @param stop number
--- @return gmime.Stream
function M.stream_mmap_new_with_bounds(fd, prot, flags, start, stop)
	return ffi.gc(gmime.g_mime_stream_mmap_new_with_bounds(fd, prot, flags, start, stop), gmime.g_object_unref)
end

-- gboolean g_mime_stream_mmap_get_owner (GMimeStreamMmap *stream);
--- @param stream gmime.StreamMmap
--- @return boolean
function M.stream_mmap_get_owner(stream)
	return gmime.g_mime_stream_mmap_get_owner(stream) ~= 0
end

-- void g_mime_stream_mmap_set_owner (GMimeStreamMmap *stream, gboolean owner);
--- @param stream gmime.StreamMmap
--- @param owner boolean
function M.stream_mmap_set_owner(stream, owner)
	gmime.g_mime_stream_mmap_set_owner(stream, owner)
end

-- GMimeStream *g_mime_stream_null_new (void);
--- @return gmime.Stream
function M.stream_null_new()
	return ffi.gc(gmime.g_mime_stream_null_new(), gmime.g_object_unref)
end

-- void g_mime_stream_null_set_count_newlines (GMimeStreamNull *stream, gboolean count);
--- @param stream gmime.StreamNull
--- @param count boolean
function M.stream_null_set_count_newlines(stream, count)
	gmime.g_mime_stream_null_set_count_newlines(stream, count)
end

-- gboolean g_mime_stream_null_get_count_newlines (GMimeStreamNull *stream);
--- @param stream gmime.StreamNull
--- @return boolean
function M.stream_null_get_count_newlines(stream)
	return gmime.g_mime_stream_null_get_count_newlines(stream) ~= 0
end

-- GMimeStream *g_mime_stream_pipe_new (int fd);
--- @param fd number
--- @return gmime.Stream
function M.stream_pipe_new(fd)
	return ffi.gce(gmime.g_mime_stream_pipe_new(fd), gmime.g_object_unref)
end

-- gboolean g_mime_stream_pipe_get_owner (GMimeStreamPipe *stream);
--- @param stream gmime.StreamPipe
function M.stream_pipe_get_owner(stream)
	return gmime.g_mime_stream_pipe_get_owner(stream)
end

-- void g_mime_stream_pipe_set_owner (GMimeStreamPipe *stream, gboolean owner);
--- @param stream gmime.StreamPipe
--- @param owner boolean
function M.stream_pipe_set_owner(stream, owner)
	gmime.g_mime_stream_pipe_set_owner(stream, owner)
end

-- GMimeStream *g_mime_stream_buffer_new (GMimeStream *source, GMimeStreamBufferMode mode);
--- @param source gmime.Stream
--- @param mode gmime.StreamBufferMode
function M.stream_buffer_new(source, mode)
	return ffi.gc(gmime.g_mime_stream_buffer_new(source, mode), gmime.g_object_unref)
end

-- ssize_t g_mime_stream_buffer_gets (GMimeStream *stream, char *buf, size_t max);
--- @param stream gmime.Stream
--- @param len number
--- @param buf any?
--- @return string, number
function M.stream_buffer_gets(stream, len, buf)
	if not buf then
		buf = ffi.new("char[?]", len)
		local num = tonumber(gmime.stream_buffer_gets(stream, buf, len))
		local str = ffi.string(buf, num)
		gmime.g_byte_array_free(buf)
		return str, num
	else
		local num = tonumber(gmime.stream_buffer_gets(stream, buf, len))
		local str = ffi.string(buf, num)
		return str, num
	end
end

-- void    g_mime_stream_buffer_readln (GMimeStream *stream, GByteArray *buffer);
--- @param stream gmime.Stream
--- @param buf any?
--- @return string
function M.stream_buffer_readln(stream, buf)
	if not buf then
		buf = gmime.g_byte_array_new()
		gmime.g_mime_stream_buffer_readln(stream, buf)
		local str = ffi.string(buf.data)
		gmime.g_byte_array_free(buf)
		return str
	else
		gmime.g_mime_stream_buffer_readln(stream, buf)
		return ffi.string(buf.data)
	end
end

-- GMimeStream *g_mime_stream_filter_new (GMimeStream *stream);
--- @param stream gmime.Stream
--- @return gmime.Stream
function M.stream_filter_new(stream)
	return ffi.gc(gmime.g_mime_stream_filter_new(stream), gmime.g_object_unref)
end

-- int g_mime_stream_filter_add (GMimeStreamFilter *stream, GMimeFilter *filter);
--- @param stream gmime.StreamFilter
--- @param filter gmime.Filter
--- @return number
function M.stream_filter_add(stream, filter)
	return gmime.g_mime_stream_filter_add(stream, filter)
end

-- void g_mime_stream_filter_remove (GMimeStreamFilter *stream, int id);
--- @param stream gmime.StreamFilter
--- @param id number
function M.stream_filter_remove(stream, id)
	gmime.g_mime_stream_filter_remove(stream, id)
end

-- void g_mime_stream_filter_set_owner (GMimeStreamFilter *stream, gboolean owner);
--- @param stream gmime.StreamFilter
--- @param owner boolean
function M.stream_filter_set_owner(stream, owner)
	gmime.g_mime_stream_filter_set_owner(stream, owner)
end

-- gboolean g_mime_stream_filter_get_owner (GMimeStreamFilter *stream);
--- @param stream gmime.StreamFilter
--- @return boolean
function M.stream_filter_get_owner(stream)
	return gmime.g_mime_stream_filter_get_owner(stream) ~= 0
end

-- GMimeDataWrapper *g_mime_data_wrapper_new (void);
--- @return gmime.DataWrapper
function M.data_wrapper_new()
	return ffi.gc(gmime.g_mime_data_wrapper_new(), gmime.g_object_unref)
end

-- GMimeDataWrapper *g_mime_data_wrapper_new_with_stream (GMimeStream *stream, GMimeContentEncoding encoding);
--- @param stream gmime.Stream
--- @param encoding gmime.ContentEncoding
--- @return gmime.DataWrapper
function M.data_wrapper_new_with_stream(stream, encoding)
	return gmime.g_mime_data_wrapper_new_with_stream(stream, encoding)
end

-- void g_mime_data_wrapper_set_stream (GMimeDataWrapper *wrapper, GMimeStream *stream);
--- @param wrapper gmime.DataWrapper
--- @param stream gmime.Stream
function M.data_wrapper_set_stream(wrapper, stream)
	gmime.g_mime_data_wrapper_set_stream(wrapper, stream)
end

-- GMimeStream *g_mime_data_wrapper_get_stream (GMimeDataWrapper *wrapper);
--- @param wrapper gmime.DataWrapper
--- @return gmime.Stream
function M.data_wrapper_get_stream(wrapper)
	return gmime.g_mime_data_wrapper_get_stream(wrapper)
end

-- void g_mime_data_wrapper_set_encoding (GMimeDataWrapper *wrapper, GMimeContentEncoding encoding);
--- @param wrapper gmime.DataWrapper
--- @param encoding gmime.ContentEncoding
function M.data_wrapper_set_encoding(wrapper, encoding)
	gmime.g_mime_data_wrapper_set_encoding(wrapper, encoding)
end

-- GMimeContentEncoding g_mime_data_wrapper_get_encoding (GMimeDataWrapper *wrapper);
--- @param wrapper gmime.DataWrapper
--- @return gmime.ContentEncoding
function M.data_wrapper_get_encoding(wrapper)
	return gmime.g_mime_data_wrapper_get_encoding(wrapper)
end

-- ssize_t g_mime_data_wrapper_write_to_stream (GMimeDataWrapper *wrapper, GMimeStream *stream);
--- @param wrapper gmime.DataWrapper
--- @param stream gmime.Stream
--- @return number
function M.data_wrapper_write_to_stream(wrapper, stream)
	return gmime.g_mime_data_wrapper_write_to_stream(wrapper, stream)
end
--
return M
