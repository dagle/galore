local gmime = require("galore.gmime.gmime_ffi")
local ffi = require("ffi")

local M = {}
-- typedef void (* GMimeParserHeaderRegexFunc) (GMimeParser *parser, const char *header,
-- 					     const char *value, gint64 offset,
-- 					     gpointer user_data);
--
-- GMimeParser *g_mime_parser_new (void);
function M.parser_new()
	return gmime.g_mime_parser_new()
end
-- GMimeParser *g_mime_parser_new_with_stream (GMimeStream *stream);
function M.parser_new_with_stream(stream)
	return gmime.g_mime_parser_new_with_stream(stream)
end
--
-- void g_mime_parser_init_with_stream (GMimeParser *parser, GMimeStream *stream);
function M.parser_init_with_stream(parser, stream)
	gmime.g_mime_parser_init_with_stream(parser, stream)
end
--
-- gboolean g_mime_parser_get_persist_stream (GMimeParser *parser);
function M.parser_get_persist_stream(parser)
	return gmime.g_mime_parser_get_persist_stream(parser)
end
-- void g_mime_parser_set_persist_stream (GMimeParser *parser, gboolean persist);
function M.parser_set_persist_stream(parser, persist)
	gmime.g_mime_parser_set_persist_stream(parser, persist)
end
--
-- GMimeFormat g_mime_parser_get_format (GMimeParser *parser);
function M.parser_get_format(parser)
	return gmime.g_mime_parser_get_format(parser)
end
-- void g_mime_parser_set_format (GMimeParser *parser, GMimeFormat format);
function M.parser_set_format(parser, format)
	gmime.g_mime_parser_set_format(parser, format)
end
--
-- gboolean g_mime_parser_get_respect_content_length (GMimeParser *parser);
function M.parser_get_respect_content_length(parser)
	return gmime.g_mime_parser_get_respect_content_length(parser)
end
-- void g_mime_parser_set_respect_content_length (GMimeParser *parser, gboolean respect_content_length);
function M.parser_set_respect_content_length(parser, respect_length)
	gmime.g_mime_parser_set_respect_content_length(parser, respect_length)
end
--
-- void g_mime_parser_set_header_regex (GMimeParser *parser, const char *regex,
-- 				     GMimeParserHeaderRegexFunc header_cb,
-- 				     gpointer user_data);
function M.parser_set_header_regex(parser, regex, cb, data)
	gmime.g_mime_parser_set_header_regex(parser, regex, cb, data)
end
--
-- GMimeObject *g_mime_parser_construct_part (GMimeParser *parser, GMimeParserOptions *options);
function M.parser_construct_part(parser, options)
	return gmime.g_mime_parser_construct_part(parser, options)
end
-- GMimeMessage *g_mime_parser_construct_message (GMimeParser *parser, GMimeParserOptions *options);
function M.parser_construct_message(parser, options)
	return gmime.g_mime_parser_construct_message(parser, options)
end
--
-- gint64 g_mime_parser_tell (GMimeParser *parser);
function M.parser_tell(parser)
	return gmime.g_mime_parser_tell(parser)
end
--
-- gboolean g_mime_parser_eos (GMimeParser *parser);
function M.parser_eos(parser)
	return gmime.g_mime_parser_eos(parser)
end
--
-- char *g_mime_parser_get_mbox_marker (GMimeParser *parser);
function M.parser_get_mbox_marker(parser)
	return ffi.string(gmime.g_mime_parser_get_mbox_marker(parser))
end
-- gint64 g_mime_parser_get_mbox_marker_offset (GMimeParser *parser);
function M.parser_get_mbox_marker_offset(parser)
	return gmime.g_mime_parser_get_mbox_marker_offset(parser)
end
--
-- gint64 g_mime_parser_get_headers_begin (GMimeParser *parser);
function M.parser_get_headers_begin(parser)
	return gmime.g_mime_parser_get_headers_begin(parser)
end
-- gint64 g_mime_parser_get_headers_end (GMimeParser *parser);
function M.parser_get_headers_end(parser)
	return gmime.g_mime_parser_get_headers_end(parser)
end
--
-- void g_mime_stream_construct (GMimeStream *stream, gint64 start, gint64 end);
function M.stream_construct(stream, start, stop)
	gmime.g_mime_stream_construct(stream, start, stop)
end
--
-- ssize_t   g_mime_stream_read    (GMimeStream *stream, char *buf, size_t len);
-- XXX
function M.stream_read()
	return tonumber(gmime.g_mime_stream_read())
end
-- ssize_t e_stream_write   (GMimeStream *stream, const char *buf, size_t len);
-- XXX
function M.g_mime_stream_write()
	return tonumber(gmime.e_stream_write())
end
-- int       g_mime_stream_flush   (GMimeStream *stream);
function M.stream_flush(stream)
	return gmime.g_mime_stream_flush(stream)
end
-- int       g_mime_stream_close   (GMimeStream *stream);
function M.stream_close(stream)
	return gmime.g_mime_stream_close(stream)
end
-- gboolean  g_mime_stream_eos     (GMimeStream *stream);
function M.stream_eos(stream)
	return gmime.g_mime_stream_eos(stream)
end
-- int       g_mime_stream_reset   (GMimeStream *stream);
function M.stream_reset(stream)
	return gmime.g_mime_stream_reset(stream)
end
-- gint64    g_mime_stream_seek    (GMimeStream *stream, gint64 offset, GMimeSeekWhence whence);
function M.stream_seek(stream, offset, whence)
	return gmime.g_mime_stream_seek(stream, offset, whence)
end
-- gint64    g_mime_stream_tell    (GMimeStream *stream);
function M.stream_tell(stream)
	return gmime.g_mime_stream_tell(stream)
end
-- gint64    g_mime_stream_length  (GMimeStream *stream);
function M.stream_length(stream)
	return gmime.g_mime_stream_length(stream)
end
--
-- GMimeStream *g_mime_stream_substream (GMimeStream *stream, gint64 start, gint64 end);
function M.stream_substream(stream, start, stop)
	return gmime.g_mime_stream_substream(stream, start, stop)
end
--
-- void      g_mime_stream_set_bounds (GMimeStream *stream, gint64 start, gint64 end);
function M.stream_set_bounds(stream, start, stop)
	gmime.g_mime_stream_set_bounds(stream, start, stop)
end
--
-- ssize_t   g_mime_stream_write_string (GMimeStream *stream, const char *str);
function M.stream_write_string(stream, str)
	return tonumber(gmime.g_mime_stream_write_string(stream, str))
end
-- ssize_t   g_mime_stream_printf       (GMimeStream *stream, const char *fmt, ...);
--- XXX
function M.stream_printf(stream, fmt, ...)
	return tonumber(gmime.g_mime_stream_printf(stream, fmt, ...))
end
--
-- gint64    g_mime_stream_write_to_stream (GMimeStream *src, GMimeStream *dest);
function M.stream_write_to_stream(src, dest)
	return gmime.g_mime_stream_write_to_stream(src, dest)
end
--
-- gint64    g_mime_stream_writev (GMimeStream *stream, GMimeStreamIOVector *vector, size_t count);
--- XXX
function M.stream_writev()
	return gmime.g_mime_stream_writev()
end
--
-- GMimeStream *g_mime_stream_fs_new (int fd);
function M.stream_fs_new(fd)
	return gmime.g_mime_stream_fs_new(fd)
end
-- GMimeStream *g_mime_stream_fs_new_with_bounds (int fd, gint64 start, gint64 end);
function M.stream_fs_new_with_bounds(fd, start, stop)
	return gmime.g_mime_stream_fs_new_with_bounds(fd, start, stop)
end
--
-- GMimeStream *g_mime_stream_fs_open (const char *path, int flags, int mode, GError **err);
function M.stream_fs_open(path, flags, mode)
	local err
	local res = gmime.g_mime_stream_fs_open(path, flags, mode)
	return res, err[0]
end
--
-- gboolean g_mime_stream_fs_get_owner (GMimeStreamFs *stream);
function M.stream_fs_get_owner(stream)
	return gmime.g_mime_stream_fs_get_owner(stream)
end
-- void g_mime_stream_fs_set_owner (GMimeStreamFs *stream, gboolean owner);
function M.stream_fs_set_owner(stream, owner)
	gmime.g_mime_stream_fs_set_owner(stream, owner)
end
--
-- GMimeStream *g_mime_stream_cat_new (void);
function M.stream_cat_new()
	return gmime.g_mime_stream_cat_new()
end
--
-- int g_mime_stream_cat_add_source (GMimeStreamCat *cat, GMimeStream *source);
function M.stream_cat_add_source(cat, source)
	return gmime.g_mime_stream_cat_add_source(cat, source)
end
--
-- GMimeStream *g_mime_stream_mem_new (void);
function M.stream_mem_new()
	return gmime.g_mime_stream_mem_new()
end
-- GMimeStream *g_mime_stream_mem_new_with_byte_array (GByteArray *array);
--- XXX
function M.stream_mem_new_with_byte_array()
	return gmime.g_mime_stream_mem_new_with_byte_array()
end

-- GMimeStream *g_mime_stream_mem_new_with_buffer (const char *buffer, size_t len);
--- XXX
function M.stream_mem_new_with_buffer()
	return g_mime_stream_mem_new_with_buffer()
end
--
-- GByteArray *g_mime_stream_mem_get_byte_array (GMimeStreamMem *mem);
--- XXX
function M.stream_mem_get_byte_array()
	return gmime.g_mime_stream_mem_get_byte_array()
end

-- void g_mime_stream_mem_set_byte_array (GMimeStreamMem *mem, GByteArray *array);
--- XXX
function M.stream_mem_set_byte_array()
	gmime.g_mime_stream_mem_set_byte_array()
end

-- gboolean g_mime_stream_mem_get_owner (GMimeStreamMem *mem);
--- XXX
function M.stream_mem_get_owner()
	gmime.g_mime_stream_mem_get_owner()
end

-- void g_mime_stream_mem_set_owner (GMimeStreamMem *mem, gboolean owner);
--- XXX
function M.stream_mem_set_owner()
	gmime.g_mime_stream_mem_set_owner()
end

--- XXX
-- GMimeStream *g_mime_stream_file_new (FILE *fp);
function M.stream_file_new()
	return g_mime_stream_file_new()
end

-- GMimeStream *g_mime_stream_file_new_with_bounds (FILE *fp, gint64 start, gint64 end);
--- XXX
function M.stream_file_new_with_bounds()
end

-- GMimeStream *g_mime_stream_file_open (const char *path, const char *mode, GError **err);
function M.stream_file_open(path, mode)
	local err
	local ret = gmime.g_mime_stream_file_open(path, mode, err)
	return ret, err
end

-- gboolean g_mime_stream_file_get_owner (GMimeStreamFile *stream);
function M.stream_file_get_owner(stream)
	return gmime.g_mime_stream_file_get_owner(stream)
end

-- void g_mime_stream_file_set_owner (GMimeStreamFile *stream, gboolean owner);
function M.stream_file_set_owner(stream, owner)
	gmime.g_mime_stream_file_set_owner(stream, owner)
end

-- GMimeStream *g_mime_stream_mmap_new (int fd, int prot, int flags);
function M.stream_mmap_new(fd, prot, flags)
	return gmime.g_mime_stream_mmap_new(fd, prot, flags)
end

-- GMimeStream *g_mime_stream_mmap_new_with_bounds (int fd, int prot, int flags, gint64 start, gint64 end);
function M.stream_mmap_new_with_bounds(fd, prot, flags, start, stop)
	return gmime.g_mime_stream_mmap_new_with_bounds(fd, prot, flags, start, stop)
end

-- gboolean g_mime_stream_mmap_get_owner (GMimeStreamMmap *stream);
function M.stream_mmap_get_owner(stream)
	return gmime.g_mime_stream_mmap_get_owner(stream)
end
-- void g_mime_stream_mmap_set_owner (GMimeStreamMmap *stream, gboolean owner);
function M.stream_mmap_set_owner(stream, owner)
	gmime.g_mime_stream_mmap_set_owner(stream, owner)
end

-- GMimeStream *g_mime_stream_null_new (void);
function M.stream_null_new()
	return gmime.g_mime_stream_null_new()
end

-- void g_mime_stream_null_set_count_newlines (GMimeStreamNull *stream, gboolean count);
function M.stream_null_set_count_newlines(stream, count)
	gmime.g_mime_stream_null_set_count_newlines(stream, count)
end
-- gboolean g_mime_stream_null_get_count_newlines (GMimeStreamNull *stream);
function M.stream_null_get_count_newlines(stream)
	return gmime.g_mime_stream_null_get_count_newlines(stream)
end

-- GMimeStream *g_mime_stream_pipe_new (int fd);
function M.stream_pipe_new(fd)
	return gmime.g_mime_stream_pipe_new(fd)
end

-- gboolean g_mime_stream_pipe_get_owner (GMimeStreamPipe *stream);
function M.stream_pipe_get_owner(stream)
	return gmime.g_mime_stream_pipe_get_owner(stream)
end
-- void g_mime_stream_pipe_set_owner (GMimeStreamPipe *stream, gboolean owner);
function M.stream_pipe_set_owner(stream, owner)
	gmime.g_mime_stream_pipe_set_owner(stream, owner)
end

-- GMimeStream *g_mime_stream_buffer_new (GMimeStream *source, GMimeStreamBufferMode mode);
function M.stream_buffer_new(source, mode)
	return gmime.g_mime_stream_buffer_new(source, mode)
end

-- ssize_t g_mime_stream_buffer_gets (GMimeStream *stream, char *buf, size_t max);
--- XXX
function M.stream_buffer_gets()
	return tonumber(gmime.stream_buffer_gets())
end

-- void    g_mime_stream_buffer_readln (GMimeStream *stream, GByteArray *buffer);
--- XXX
function M.stream_buffer_readln()
	gmime.g_mime_stream_buffer_readln()
end

-- GMimeStream *g_mime_stream_filter_new (GMimeStream *stream);
function M.stream_filter_new(stream)
	return gmime.g_mime_stream_filter_new()
end

-- int g_mime_stream_filter_add (GMimeStreamFilter *stream, GMimeFilter *filter);
function M.stream_filter_add(stream, filter)
	return gmime.g_mime_stream_filter_add(stream, filter)
end
-- void g_mime_stream_filter_remove (GMimeStreamFilter *stream, int id);
function M.stream_filter_remove(stream, id)
	gmime.g_mime_stream_filter_remove(stream, id)
end
--
-- void g_mime_stream_filter_set_owner (GMimeStreamFilter *stream, gboolean owner);
function M.stream_filter_set_owner(stream, owner)
	gmime.g_mime_stream_filter_set_owner(stream, owner)
end
-- gboolean g_mime_stream_filter_get_owner (GMimeStreamFilter *stream);
function M.stream_filter_get_owner(stream)
	return gmime.g_mime_stream_filter_get_owner(stream)
end
--
-- GMimeDataWrapper *g_mime_data_wrapper_new (void);
function M.data_wrapper_new()
	return gmime.g_mime_data_wrapper_new()
end
-- GMimeDataWrapper *g_mime_data_wrapper_new_with_stream (GMimeStream *stream, GMimeContentEncoding encoding);
function M.data_wrapper_new_with_stream(stream, encoding)
	return gmime.g_mime_data_wrapper_new_with_stream(stream, encoding)
end
--
-- void g_mime_data_wrapper_set_stream (GMimeDataWrapper *wrapper, GMimeStream *stream);
function M.data_wrapper_set_stream(wrapper, stream)
	gmime.g_mime_data_wrapper_set_stream(wrapper, stream)
end
-- GMimeStream *g_mime_data_wrapper_get_stream (GMimeDataWrapper *wrapper);
function M.data_wrapper_get_stream(wrapper)
	return gmime.g_mime_data_wrapper_get_stream(stream)
end
--
-- void g_mime_data_wrapper_set_encoding (GMimeDataWrapper *wrapper, GMimeContentEncoding encoding);
function M.data_wrapper_set_encoding(wrapper)
	gmime.g_mime_data_wrapper_set_encoding(stream)
end
-- GMimeContentEncoding g_mime_data_wrapper_get_encoding (GMimeDataWrapper *wrapper);
function M.data_wrapper_get_encoding(wrapper)
	return gmime.g_mime_data_wrapper_get_encoding(wrapper)
end
--
-- ssize_t g_mime_data_wrapper_write_to_stream (GMimeDataWrapper *wrapper, GMimeStream *stream);
function M.data_wrapper_write_to_stream(wrapper)
	return tonumber(gmime.g_mime_data_wrapper_write_to_stream(wrapper))
end
--
return M
