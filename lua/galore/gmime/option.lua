local gmime = require("galore.gmime.gmime_ffi")
local ffi = require("ffi")

local M = {}

-- typedef void (*GMimeParserWarningFunc) (gint64 offset, GMimeParserWarning errcode, const gchar *item, gpointer user_data);

-- GMimeParserOptions *g_mime_parser_options_get_default (void);
--- @return gmime.ParserOptions
function M.parser_options_get_default()
	return gmime.g_mime_parser_options_get_default()
end

-- GMimeParserOptions *g_mime_parser_options_new (void);
--- @return gmime.ParserOptions
function M.parser_options_new()
	return ffi.gc(gmime.g_mime_parser_options_new(), gmime.g_mime_parser_options_free)
end

-- void g_mime_parser_options_free (GMimeParserOptions *options);
-- function M.parser_options_free(option)
-- 	gmime.g_mime_parser_options_free(option)
-- end

-- GMimeParserOptions *g_mime_parser_options_clone (GMimeParserOptions *options);
--- @param option gmime.ParserOptions
function M.parser_options_clone(option)
	return ffi.gc(gmime.g_mime_parser_options_clone(option), gmime.g_mime_parser_options_free)
end

-- GMimeRfcComplianceMode g_mime_parser_options_get_address_compliance_mode (GMimeParserOptions *options);
--- @param option gmime.ParserOptions
function M.parser_options_get_address_compliance_mode(option)
	return gmime.g_mime_parser_options_get_address_compliance_mode(option)
end

-- void g_mime_parser_options_set_address_compliance_mode (GMimeParserOptions *options, GMimeRfcComplianceMode mode);
--- @param option gmime.ParserOptions
--- @param mode gmime.RfcComplianceMode
function M.parser_options_set_address_compliance_mode(option, mode)
	gmime.g_mime_parser_options_set_address_compliance_mode(option, mode)
end

-- gboolean g_mime_parser_options_get_allow_addresses_without_domain (GMimeParserOptions *options);
--- @param option gmime.ParserOptions
--- @return gmime.RfcComplianceMode
function M.parser_options_get_allow_addresses_without_domain(option)
	return gmime.g_mime_parser_options_get_allow_addresses_without_domain(option) ~= 0
end

-- void g_mime_parser_options_set_allow_addresses_without_domain (GMimeParserOptions *options, gboolean allow);
--- @param option gmime.ParserOptions
--- @param allow boolean
function M.parser_options_set_allow_addresses_without_domain(option, allow)
	gmime.g_mime_parser_options_set_allow_addresses_without_domain(option, allow)
end

-- GMimeRfcComplianceMode g_mime_parser_options_get_parameter_compliance_mode (GMimeParserOptions *options);
--- @param option gmime.ParserOptions
--- @return boolean
function M.parser_options_get_parameter_compliance_mode(option)
	return gmime.g_mime_parser_options_get_parameter_compliance_mode(option)
end

-- void g_mime_parser_options_set_parameter_compliance_mode (GMimeParserOptions *options, GMimeRfcComplianceMode mode);
--- @param option gmime.ParserOptions
--- @param mode gmime.RfcComplianceMode
function M.parser_options_set_parameter_compliance_mode(option, mode)
	gmime.g_mime_parser_options_set_parameter_compliance_mode(option, mode)
end

-- GMimeRfcComplianceMode g_mime_parser_options_get_rfc2047_compliance_mode (GMimeParserOptions *options);
--- @param option gmime.ParserOptions
--- @return gmime.RfcComplianceMode
function M.parser_options_get_rfc2047_compliance_mode(option)
	return gmime.g_mime_parser_options_get_rfc2047_compliance_mode(option)
end

-- void g_mime_parser_options_set_rfc2047_compliance_mode (GMimeParserOptions *options, GMimeRfcComplianceMode mode);
--- @param option gmime.ParserOptions
--- @param mode gmime.RfcComplianceMode
function M.parser_options_set_rfc2047_compliance_mode(option, mode)
	gmime.g_mime_parser_options_set_rfc2047_compliance_mode(option, mode)
end

-- const char **g_mime_parser_options_get_fallback_charsets (GMimeParserOptions *options);
--- @param option gmime.ParserOptions
function M.parser_options_get_fallback_charsets(option)
	local list = {}
	local ret = gmime.g_mime_parser_options_get_fallback_charsets(option)
	local i = 0
	while ret[i] do
		local str = ffi.string(ret[i])
		table.insert(list, str)
		i = i + 1
	end
	return list
end

-- void g_mime_parser_options_set_fallback_charsets (GMimeParserOptions *options, const char **charsets);
--- @param option gmime.ParserOptions
--- @param charsets string[]
-- XXX
function M.parser_options_set_fallback_charsets(option, charsets)
	-- local charset  = ffi.new("char*[1]")
	gmime.g_mime_parser_options_set_fallback_charsets(option)
	-- return charset
end

-- GMimeParserWarningFunc g_mime_parser_options_get_warning_callback (GMimeParserOptions *options);
--- @param option gmime.ParserOptions
-- XXX
function M.parser_options_get_warning_callback(option)
	return gmime.g_mime_parser_options_get_warning_callback(option)
end

-- void g_mime_parser_options_set_warning_callback (GMimeParserOptions *options, GMimeParserWarningFunc warning_cb,
-- 						 gpointer user_data);
-- XXX
function M.parser_options_set_warning_callback(option, cb, data)
	gmime.g_mime_parser_options_set_warning_callback(option, cb, data)
end

-- const char *g_mime_param_get_name (GMimeParam *param);
--- @param param gmime.Param
--- @return string
function M.param_get_name(param)
	return ffi.string(gmime.g_mime_param_get_name(param))
end

-- const char *g_mime_param_get_value (GMimeParam *param);
--- @param param gmime.Param
--- @return string
function M.param_get_value(param)
	return ffi.string(gmime.g_mime_param_get_value(param))
end

-- void g_mime_param_set_value (GMimeParam *param, const char *value);
--- @param param gmime.Param
--- @param value string
function M.param_set_value(param, value)
	gmime.g_mime_param_set_value(param, value)
end

-- const char *g_mime_param_get_charset (GMimeParam *param);
--- @param param gmime.Param
--- @return string
function M.param_get_charset(param)
	return ffi.string(gmime.g_mime_param_get_charset(param))
end

-- void g_mime_param_set_charset (GMimeParam *param, const char *charset);
--- @param param gmime.Param
--- @param charset string
function M.param_set_charset(param, charset)
	gmime.g_mime_param_set_charset(param, charset)
end

-- const char *g_mime_param_get_lang (GMimeParam *param);
--- @param param gmime.Param
--- @return string
function M.param_get_lang(param)
	return ffi.string(gmime.g_mime_param_get_lang(param))
end

-- void g_mime_param_set_lang (GMimeParam *param, const char *lang);
--- @param param gmime.Param
--- @param lang string
function M.param_set_lang(param, lang)
	gmime.g_mime_param_set_lang(param, lang)
end

-- GMimeParamEncodingMethod g_mime_param_get_encoding_method (GMimeParam *param);
--- @param param gmime.Param
--- @return gmime.ParamEncodingMethod
function M.param_get_encoding_method(param)
	return gmime.g_mime_param_get_encoding_method(param)
end

-- void g_mime_param_set_encoding_method (GMimeParam *param, GMimeParamEncodingMethod method);
--- @param param gmime.Param
--- @param method gmime.ParamEncodingMethod
function M.param_set_encoding_method(param, method)
	gmime.g_mime_param_set_encoding_method(param, method)
end

-- GMimeParamList *g_mime_param_list_new (void);
--- @return gmime.ParamList
function M.param_list_new()
	return ffi.gc(gmime.g_mime_param_list_new(), gmime.g_object_unref)
end

-- GMimeParamList *g_mime_param_list_parse (GMimeParserOptions *options, const char *str);
--- @return gmime.ParamList
function M.param_list_parse(potions, str)
	return ffi.gc(gmime.g_mime_param_list_parse(potions, str), gmime.g_object_unref)
end

-- int g_mime_param_list_length (GMimeParamList *list);
--- @param list gmime.ParamList
--- @return number
function M.param_list_length(list)
	return gmime.g_mime_param_list_length(list)
end

-- void g_mime_param_list_clear (GMimeParamList *list);
--- @param list gmime.ParamList
function M.param_list_clear(list)
	gmime.g_mime_param_list_clear(list)
end

-- void g_mime_param_list_set_parameter (GMimeParamList *list, const char *name, const char *value);
--- @param list gmime.ParamList
--- @param name string
--- @param value string
function M.param_list_set_parameter(list, name, value)
	gmime.g_mime_param_list_set_parameter(list, name, value)
end

-- GMimeParam *g_mime_param_list_get_parameter (GMimeParamList *list, const char *name);
--- @param list gmime.ParamList
--- @param name string
--- @return gmime.Param
function M.param_list_get_parameter(list, name)
	return gmime.g_mime_param_list_get_parameter(list, name)
end

-- GMimeParam *g_mime_param_list_get_parameter_at (GMimeParamList *list, int index);
--- @param list gmime.ParamList
--- @param index number
--- @return gmime.Param
function M.param_list_get_parameter_at(list, index)
	return gmime.g_mime_param_list_get_parameter_at(list, index)
end

-- gboolean g_mime_param_list_remove (GMimeParamList *list, const char *name);
--- @param list gmime.ParamList
--- @param name string
--- @return boolean
function M.param_list_remove(list, name)
	return gmime.g_mime_param_list_remove(list, name) ~= 0
end

-- gboolean g_mime_param_list_remove_at (GMimeParamList *list, int index);
--- @param list gmime.ParamList
--- @param index number
--- @return boolean
function M.param_list_remove_at(list, index)
	return gmime.g_mime_param_list_remove_at(list, index) ~= 0
end

-- void g_mime_param_list_encode (GMimeParamList *list, GMimeFormatOptions *options, gboolean fold, GString *str);
--- @param list gmime.ParamList
--- @param option gmime.Option
--- @param fold boolean
--- @param str string
function M.param_list_encode(list, option, fold, str)
	gmime.g_mime_param_list_encode(list, option, fold, str)
end

-- GMimeFormatOptions *g_mime_format_options_get_default (void);
--- @return gmime.FormatOptions
function M.format_options_get_default()
	return gmime.g_mime_format_options_get_default()
end

-- GMimeFormatOptions *g_mime_format_options_new (void);
--- @return gmime.FormatOptions
function M.format_options_new()
	return ffi.gc(gmime.g_mime_format_options_new(), gmime.g_mime_format_options_free)
end

-- void g_mime_format_options_free (GMimeFormatOptions *options);
-- function M.format_options_free()
-- 	gmime.g_mime_format_options_free()
-- end

-- GMimeFormatOptions *g_mime_format_options_clone (GMimeFormatOptions *options);
--- @param option gmime.FormatOptions
--- @return gmime.FormatOptions
function M.format_options_clone(option)
	return ffi.gc(gmime.g_mime_format_options_clone(option), gmime.g_mime_format_options_free)
end

-- GMimeParamEncodingMethod g_mime_format_options_get_param_encoding_method (GMimeFormatOptions *options);
--- @param option gmime.FormatOptions
--- @return gmime.ParamEncodingMethod
function M.format_options_get_param_encoding_method(option)
	return gmime.g_mime_format_options_get_param_encoding_method(option)
end

-- void g_mime_format_options_set_param_encoding_method (GMimeFormatOptions *options, GMimeParamEncodingMethod method);
--- @param option gmime.FormatOptions
--- @param method gmime.ParamEncodingMethod
function M.format_options_set_param_encoding_method(option, method)
	gmime.g_mime_format_options_set_param_encoding_method(option, method)
end

-- GMimeNewLineFormat g_mime_format_options_get_newline_format (GMimeFormatOptions *options);
--- @param option gmime.FormatOptions
--- @return gmime.NewLineFormat
function M.format_options_get_newline_format(option)
	return gmime.g_mime_format_options_get_newline_format(option)
end

-- void g_mime_format_options_set_newline_format (GMimeFormatOptions *options, GMimeNewLineFormat newline);
--- @param option gmime.FormatOptions
--- @param newline gmime.NewLineFormat
function M.format_options_set_newline_format(option, newline)
	gmime.g_mime_format_options_set_newline_format(option, newline)
end

-- const char *g_mime_format_options_get_newline (GMimeFormatOptions *options);
--- @param option gmime.FormatOptions
--- @return string
function M.format_options_get_newline(option)
	return ffi.string(gmime.g_mime_format_options_get_newline(option))
end

-- GMimeFilter *g_mime_format_options_create_newline_filter (GMimeFormatOptions *options, gboolean ensure_newline);
--- @param option gmime.FormatOptions
--- @param ensure_newline boolean
--- @return gmime.Filter
function M.format_options_create_newline_filter(option, ensure_newline)
	return gmime.g_mime_format_options_create_newline_filter(option, ensure_newline)
end

-- gboolean g_mime_format_options_is_hidden_header (GMimeFormatOptions *options, const char *header);
--- @param option gmime.FormatOptions
--- @param header string
--- @return boolean
function M.format_options_is_hidden_header(option, header)
	return gmime.g_mime_format_options_is_hidden_header(option, header) ~= 0
end

-- void g_mime_format_options_add_hidden_header (GMimeFormatOptions *options, const char *header);
--- @param option gmime.FormatOptions
--- @param header string
function M.format_options_add_hidden_header(option, header)
	gmime.g_mime_format_options_add_hidden_header(option, header)
end

-- void g_mime_format_options_remove_hidden_header (GMimeFormatOptions *options, const char *header);
--- @param option gmime.FormatOptions
--- @param header string
function M.format_options_remove_hidden_header(option, header)
	gmime.g_mime_format_options_remove_hidden_header(option, header)
end

-- void g_mime_format_options_clear_hidden_headers (GMimeFormatOptions *options);
--- @param option gmime.FormatOptions
function M.format_options_clear_hidden_headers(option)
	gmime.g_mime_format_options_clear_hidden_headers(option)
end

return M
