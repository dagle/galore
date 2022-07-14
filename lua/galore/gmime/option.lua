--- @diagnostic disable: undefined-field

local gmime = require("galore.gmime.gmime_ffi")
local ffi = require("ffi")

local M = {}

--- @return gmime.ParserOptions
function M.parser_options_get_default()
	return gmime.g_mime_parser_options_get_default()
end

--- @return gmime.ParserOptions
function M.parser_options_new()
	return ffi.gc(gmime.g_mime_parser_options_new(), gmime.g_mime_parser_options_free)
end

--- @param option gmime.ParserOptions
function M.parser_options_clone(option)
	return ffi.gc(gmime.g_mime_parser_options_clone(option), gmime.g_mime_parser_options_free)
end

--- @param option gmime.ParserOptions
--- @return boolean
--- returns true if we are in strict mode
function M.parser_options_get_address_compliance_mode(option)
	return gmime.g_mime_parser_options_get_address_compliance_mode(option) == gmime.GMIME_RFC_COMPLIANCE_STRICT
end

--- @param option boolean
--- @param strict gmime.RfcComplianceMode
function M.parser_options_set_address_compliance_mode(option, strict)
	if strict then
		gmime.g_mime_parser_options_set_address_compliance_mode(option, gmime.GMIME_RFC_COMPLIANCE_STRICT)
		return
	end
	gmime.g_mime_parser_options_set_address_compliance_mode(option, gmime.GMIME_RFC_COMPLIANCE_LOOSE)
end

--- @param option gmime.ParserOptions
--- @return boolean
--- returns true if we are in strict mode
function M.parser_options_get_allow_addresses_without_domain(option)
	return gmime.g_mime_parser_options_get_allow_addresses_without_domain(option) == gmime.GMIME_RFC_COMPLIANCE_STRICT
end

--- @param option gmime.ParserOptions
--- @param strict boolean
function M.parser_options_set_allow_addresses_without_domain(option, strict)
	if strict then
		gmime.g_mime_parser_options_set_allow_addresses_without_domain(option, gmime.GMIME_RFC_COMPLIANCE_STRICT)
		return
	end
	gmime.g_mime_parser_options_set_allow_addresses_without_domain(option, gmime.GMIME_RFC_COMPLIANCE_LOOSE)
end

--- @param option gmime.ParserOptions
--- @return boolean
--- returns true if we are in strict mode
function M.parser_options_get_parameter_compliance_mode(option)
	return gmime.g_mime_parser_options_get_parameter_compliance_mode(option) == gmime.GMIME_RFC_COMPLIANCE_STRICT
end

--- @param option gmime.ParserOptions
--- @param strict boolean
function M.parser_options_set_parameter_compliance_mode(option, strict)
	if strict then
		gmime.g_mime_parser_options_set_parameter_compliance_mode(option, gmime.GMIME_RFC_COMPLIANCE_STRICT)
		return
	end
	gmime.g_mime_parser_options_set_parameter_compliance_mode(option, gmime.GMIME_RFC_COMPLIANCE_LOOSE)
end

--- @param option gmime.ParserOptions
--- @return boolean
--- returns true if we are in strict mode
function M.parser_options_get_rfc2047_compliance_mode(option)
	return gmime.g_mime_parser_options_get_rfc2047_compliance_mode(option) == gmime.GMIME_RFC_COMPLIANCE_STRICT
end

--- @param option gmime.ParserOptions
--- @param strict boolean
function M.parser_options_set_rfc2047_compliance_mode(option, strict)
	if strict then
		gmime.g_mime_parser_options_set_rfc2047_compliance_mode(option, gmime.GMIME_RFC_COMPLIANCE_STRICT)
		return
	end
	gmime.g_mime_parser_options_set_rfc2047_compliance_mode(option, gmime.GMIME_RFC_COMPLIANCE_STRICT)
end

--- @param option gmime.ParserOptions
--- @return string[]
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

--- @param option gmime.ParserOptions
--- @param charsets string[]
function M.parser_options_set_fallback_charsets(option, charsets)
	local cs = ffi.new("char*[?]", #charsets)
	for i, charset in ipairs(charsets) do
		cs[i] = charset
	end
	gmime.g_mime_parser_options_set_fallback_charsets(option, cs)
end

--- @param option gmime.ParserOptions
function M.parser_options_get_warning_callback(option)
	return gmime.g_mime_parser_options_get_warning_callback(option)
end

--- @param option gmime.Option
--- @param cb funcref
--- @param data any
function M.parser_options_set_warning_callback(option, cb, data)
	gmime.g_mime_parser_options_set_warning_callback(option, cb, data)
end

--- @param param gmime.Param
--- @return string
function M.param_get_name(param)
	return ffi.string(gmime.g_mime_param_get_name(param))
end

--- @param param gmime.Param
--- @return string
function M.param_get_value(param)
	return ffi.string(gmime.g_mime_param_get_value(param))
end

--- @param param gmime.Param
--- @param value string
function M.param_set_value(param, value)
	gmime.g_mime_param_set_value(param, value)
end

--- @param param gmime.Param
--- @return string
function M.param_get_charset(param)
	return ffi.string(gmime.g_mime_param_get_charset(param))
end

--- @param param gmime.Param
--- @param charset string
function M.param_set_charset(param, charset)
	gmime.g_mime_param_set_charset(param, charset)
end

--- @param param gmime.Param
--- @return string
function M.param_get_lang(param)
	return ffi.string(gmime.g_mime_param_get_lang(param))
end

--- @param param gmime.Param
--- @param lang string
function M.param_set_lang(param, lang)
	gmime.g_mime_param_set_lang(param, lang)
end

--- @param param gmime.Param
--- @return gmime.ParamEncodingMethod
function M.param_get_encoding_method(param)
	return gmime.g_mime_param_get_encoding_method(param)
end

--- @param param gmime.Param
--- @param method gmime.ParamEncodingMethod
function M.param_set_encoding_method(param, method)
	gmime.g_mime_param_set_encoding_method(param, method)
end

--- @return gmime.ParamList
function M.param_list_new()
	return ffi.gc(gmime.g_mime_param_list_new(), gmime.g_object_unref)
end

--- @return gmime.ParamList
function M.param_list_parse(potions, str)
	return ffi.gc(gmime.g_mime_param_list_parse(potions, str), gmime.g_object_unref)
end

--- @param list gmime.ParamList
--- @return number
function M.param_list_length(list)
	return gmime.g_mime_param_list_length(list)
end

--- @param list gmime.ParamList
function M.param_list_clear(list)
	gmime.g_mime_param_list_clear(list)
end

--- @param list gmime.ParamList
--- @param name string
--- @param value string
function M.param_list_set_parameter(list, name, value)
	gmime.g_mime_param_list_set_parameter(list, name, value)
end

--- @param list gmime.ParamList
--- @param name string
--- @return gmime.Param
function M.param_list_get_parameter(list, name)
	return gmime.g_mime_param_list_get_parameter(list, name)
end

--- @param list gmime.ParamList
--- @param index number
--- @return gmime.Param
function M.param_list_get_parameter_at(list, index)
	return gmime.g_mime_param_list_get_parameter_at(list, index)
end

--- @param list gmime.ParamList
--- @param name string
--- @return boolean
function M.param_list_remove(list, name)
	return gmime.g_mime_param_list_remove(list, name) ~= 0
end

--- @param list gmime.ParamList
--- @param index number
--- @return boolean
function M.param_list_remove_at(list, index)
	return gmime.g_mime_param_list_remove_at(list, index) ~= 0
end

--- @param list gmime.ParamList
--- @param option gmime.Option
--- @param fold boolean
--- @param str string
function M.param_list_encode(list, option, fold, str)
	gmime.g_mime_param_list_encode(list, option, fold, str)
end

--- @return gmime.FormatOptions
function M.format_options_get_default()
	return gmime.g_mime_format_options_get_default()
end

--- @return gmime.FormatOptions
function M.format_options_new()
	return ffi.gc(gmime.g_mime_format_options_new(), gmime.g_mime_format_options_free)
end

--- @param option gmime.FormatOptions
--- @return gmime.FormatOptions
function M.format_options_clone(option)
	return ffi.gc(gmime.g_mime_format_options_clone(option), gmime.g_mime_format_options_free)
end

--- @param option gmime.FormatOptions
--- @return gmime.ParamEncodingMethod
function M.format_options_get_param_encoding_method(option)
	return gmime.g_mime_format_options_get_param_encoding_method(option)
end

--- @param option gmime.FormatOptions
--- @param method gmime.ParamEncodingMethod
function M.format_options_set_param_encoding_method(option, method)
	gmime.g_mime_format_options_set_param_encoding_method(option, method)
end

--- @param option gmime.FormatOptions
--- @return gmime.NewLineFormat
function M.format_options_get_newline_format(option)
	return gmime.g_mime_format_options_get_newline_format(option)
end

--- @param option gmime.FormatOptions
--- @param newline gmime.NewLineFormat
function M.format_options_set_newline_format(option, newline)
	gmime.g_mime_format_options_set_newline_format(option, newline)
end

--- @param option gmime.FormatOptions
--- @return string
function M.format_options_get_newline(option)
	return ffi.string(gmime.g_mime_format_options_get_newline(option))
end

--- @param option gmime.FormatOptions
--- @param ensure_newline boolean
--- @return gmime.Filter
function M.format_options_create_newline_filter(option, ensure_newline)
	return gmime.g_mime_format_options_create_newline_filter(option, ensure_newline)
end

--- @param option gmime.FormatOptions
--- @param header string
--- @return boolean
function M.format_options_is_hidden_header(option, header)
	return gmime.g_mime_format_options_is_hidden_header(option, header) ~= 0
end

--- @param option gmime.FormatOptions
--- @param header string
function M.format_options_add_hidden_header(option, header)
	gmime.g_mime_format_options_add_hidden_header(option, header)
end

--- @param option gmime.FormatOptions
--- @param header string
function M.format_options_remove_hidden_header(option, header)
	gmime.g_mime_format_options_remove_hidden_header(option, header)
end

--- @param option gmime.FormatOptions
function M.format_options_clear_hidden_headers(option)
	gmime.g_mime_format_options_clear_hidden_headers(option)
end

return M
