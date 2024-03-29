local config = require('galore.config')
local lgi = require('lgi')
local gmime = lgi.require('GMime', '3.0')
local glib = lgi.require('GLib', '2.0')

local M = {}

function M.get_domainname(mail_str)
  local fqdn = mail_str:gsub('.*@(%w*)%.(%w*).*', '%1.%2')
  return fqdn
end

function M.insert_current_date(message)
  local time = os.time()
  local gtime = glib.DateTime.new_from_unix_local(time)
  message:set_date(gtime)
end

function M.make_id(from)
  local fdqn = M.get_domainname(from)
  return gmime.utils_generate_message_id(fdqn)
end

function M.mime_type(object)
  local ct = object:get_content_type()
  if ct then
    local type = ct:get_mime_type()
    return type
  end
end

function M.parse_message(filename)
  local stream = gmime.StreamFile.open(filename, 'r')
  local parser = gmime.Parser.new_with_stream(stream)
  local opts = gmime.ParserOptions.new()
  local message = parser:construct_message(opts)
  return message
end

--- tries to recorstruct a partial message,
--- if the message isn't partial then just parse the
--- message
-- idx needs to be in bound
function M.reconstruct(filenames, idx)
  if #filenames == 1 then
    return M.parse_message(filenames[idx])
  end
  local parts = {}

  local main_message = M.parse_message(filenames[idx])
  if main_message then
    local is_partial = false
    main_message:foreach(function(_, part)
      if gmime.MessagePartial:is_type_of(part) then
        is_partial = true
        local id = part:get_id(part)
        parts[id] = {}
      end
    end)
    if not is_partial then
      return main_message
    end

    for filename in ipairs(filenames) do
      local message = M.parse_message(filename)
      message:foreach(function(_, part)
        if gmime.MessagePartial:is_type_of(part) then
          local id = part:get_id(part)
          table.insert(parts[id], part)
        end
      end)
    end
    --- TODO
    --- we only return the first message of the partials
    for _, partial in pairs(parts) do
      if #partial == partial[1]:get_total() then
        local message = gmime.MessagePartial.reconstruct_message(partial)
        return message
      end
    end
    -- fall back to original message
    return main_message
  end
end

function M.make_ref(message, opts)
  local ref_str = message:get_header('References')
  local ref
  if ref_str then
    ref = gmime.References.parse(nil, ref_str)
  else
    ref = gmime.References.new()
  end
  local mid = message:get_message_id()
  local reply = gmime.References.parse(nil, mid)
  ref:append(mid)
  opts.headers = opts.headers or {}
  opts.headers.References = M.references_format(ref)
  opts.headers['In-Reply-To'] = M.references_format(reply)
end

function M.references_format(refs)
  if refs == nil then
    return nil
  end
  local box = {}
  for ref in M.reference_iter(refs) do
    table.insert(box, '<' .. ref .. '>')
  end
  return table.concat(box, '\n\t')
end

function M.is_multipart_alt(object)
  local type = M.mime_type(object)
  if type == 'multipart/alternative' then
    return true
  end
  return false
end

function M.is_multipart_multilingual(object)
  local type = M.mime_type(object)
  if type == 'multipart/alternative' then
    return true
  end
  return false
end

function M.is_multipart_related(object)
  local type = M.mime_type(object)
  if type == 'multipart/alternative' then
    return true
  end
  return false
end

function M.multipart_foreach_level(part, parent, fun, level)
  if parent ~= part then
    fun(parent, part, level)
  end
  if gmime.Multipart:is_type_of(part) then
    local i = 0
    local j = part:get_count()
    level = level + 1
    while i < j do
      local child = part:get_part(i)
      M.multipart_foreach_level(child, part, fun, level)
      i = i + 1
    end
  end
end

function M.message_foreach_level(message, fun)
  local level = 1
  if not message or not fun then
    return
  end
  local part = message:get_mime_part()
  fun(part, part, level)

  if gmime.Multipart:is_type_of(part) then
    M.multipart_foreach_level(part, part, fun, level)
  end
end

--- @param str string
--- @param opts gmime.ParserOptions|nil
--- @return function
function M.reference_iter_str(str, opts)
  local refs = gmime.Reference.parse(opts, str)
  if refs == nil then
    return function()
      return nil
    end
  end
  return M.reference_iter(refs)
end

--- @return function
function M.reference_iter(refs)
  local i = 0
  return function()
    if i < refs:length() then
      local ref = refs:get_message_id(i)
      i = i + 1
      return ref
    end
  end
end

function M.header_iter(object)
  local ls = object:get_header_list()
  if ls == nil then
    return function()
      return nil
    end
  end
  local j = ls:get_count()
  local i = 0
  return function()
    if i < j then
      local header = ls:get_header_at(i)
      if header == nil then
        return nil, nil
      end
      local key = header:get_name()
      local value = header:get_value()
      i = i + 1
      return key, value
    end
  end
end

function M.internet_address_list_iter_str(str, opt)
  local list = gmime.InternetAddressList.parse(opt, str)
  if list == nil then
    return function()
      return nil
    end
  end
  return M.internet_address_list_iter(list)
end

function M.internet_address_list_iter(list)
  local i = 0
  return function()
    if i < list:length() then
      local addr = list:get_address(i)
      i = i + 1
      return addr
    end
  end
end

return M
