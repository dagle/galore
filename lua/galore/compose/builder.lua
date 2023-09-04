local gmime = require "galore.gmime"

local gu = require "galore.gmime-util"
local gcu = require "galore.crypt-utils"
local u = require "galore.util"
local runtime = require "galore.runtime"
local log = require "galore.log"

local M = {}

local function make_attach(attach)
  local mime = vim.iter(string.gmatch(attach.mime_type, "([^/]+)")):totable()
  if mime and #mime < 2 then
    log.error "bad mime-type"
  end
  local attachment = gmime.Part.new_with_type(mime[1], mime[2])
  attachment:set_disposition "attachment"
  attachment:set_filename(attach.filename)
  return attachment
end

local function create_path_attachment(attach)
  local attachment = make_attach(attach)

  local fd = assert(vim.loop.fs_open(attach.path, "r", 0644))
  local stream = gmime.StreamFs.new(fd)

  local content = gmime.DataWrapper.new_with_stream(stream, gmime.ContentEncoding.DEFAULT)
  attachment:set_content(content)
  return attachment
end

local function create_part_attachment(attach)
  local attachment = make_attach(attach)

  local content = attach.part:get_content()
  attachment:set_content(content)
  return attachment
end

local function create_data_attachment(attach)
  local attachment = make_attach(attach)

  local stream = gmime.StreamMem.new()

  local content = gmime.DataWrapper.new_with_stream(stream, gmime.ContentEncoding.DEFAULT)
  attachment:set_content(content)
  stream:write(stream, attach.data)
  stream:flush()
  return attachment
end

-- @param attach attachment
-- @return A MimePart object containing an attachment
-- Support encryption?
local function create_attachment(attach)
  if attach.data then
    return create_data_attachment(attach)
  elseif attach.part then
    return create_part_attachment(attach)
  elseif attach.path then
    return create_path_attachment(attach)
  else
    return nil
  end
end

-- encrypt a part and return the multipart
function M.secure(part, pgp_id, opts, recipients)
  local ctx = opts.crypto_context()
  if opts.encrypt then
    local encrypt, err = gmime.MultipartEncrypted.encrypt(ctx, part, opts.sign, pgp_id, opts.encrypt_flags, recipients)
    if encrypt ~= nil then
      return encrypt
    end

    if opts.encrypt == "MUST" then
      local str = string.format("Couldn't encrypt message: %s", err)
      log.error(str)
    end
  end
  if opts.sign then
    local signed, err = gcu.sign(ctx, part, pgp_id)
    if signed ~= nil then
      return signed
    else
      local str = string.format("Could not sign message: %s", err)
      log.error(str)
    end
  end
  -- if we don't want to sign and failed to encrypt (but isn't a must)
  -- we just return the part as is
  return part
end

local function required_headers(message)
  local function l(list)
    return list:length(list) > 0
  end
  local from = message:get_from()
  local to = message:get_to()
  local sub = message:get_subject()
  return l(from) and l(to) and sub and sub ~= ""
end

function M.textbuilder(text)
  local body = gmime.TextPart.new_with_subtype "plain"
  body:set_text(table.concat(text, "\n"))
  return body
end

--- TODO Should take a template called msg
--- The rest should be in opts
--- define what can be in a message and opts

-- create a message from strings
-- @param buf table parameters:
-- headers: headers to set, address_headers are parsed and concated
-- body: A body to send to bodybuilder
-- @param opts table. Accept these values:
-- mid: string if you don't want an autogenerated message-id.
-- encrypt: nil | "try" | "must"
-- sign: bool
-- pgp_id: id of your pgp-key, required if we want to sign the email
-- encrypt_flags: "none"|"session"|"noverify"|"keyserver"|"online"
-- @param attachments list of table. See attachment format
-- @param extra_headers list headers that we set before buf (can be overwritten)
-- @param bodybuilder function(any) string
-- @return a gmime message

-- function M.create_message(buf, opts, attachments, extra_headers, builder)

--- creates a message from a msg.
--- A msg describes a toplevel message, it's a table that is a reduced form of
--- https://datatracker.ietf.org/doc/html/rfc8621#section-4.1.4 with only
--- headers, body part. Then to create a complex message, just apply a custom
--- bodybuilder.

--- sender, from, to, cc, bcc, replyto

--- message-id
--- subject
--- date?
--- in-reply-to
--- references

function M.create_message(msg, opts)
  opts = opts or {}
  local current -- our current position in the mime tree
  local message = gmime.Message.new(true)

  for k, v in pairs(msg.headers) do
    message:set_header(k, v, opts.charset)
  end

  for k, v in pairs(msg.addresses) do
    local address = message:get_addresses(k)
    address:append(v)
  end

  if not msg.headers["Message-Id"] then
    local id = gu.make_id(msg.headers.from)
    message:set_message_id(id)
  end

  if not msg.date then
    gu.insert_current_date(message)
  end

  if not required_headers(message) then
    log.error "Missing non-optional headers"
    return
  end

  -- make a body
  current = opts.bodybuilder(msg.body)

  -- add attachments
  if not vim.tbl_isempty(msg.attachments) then
    local multipart = gmime.Multipart.new_with_subtype "mixed"
    multipart:add(current)
    current = multipart
    for _, attach in pairs(msg.attachments) do
      local attachment = create_attachment(attach)
      if attachment then
        multipart:add(attachment)
      end
    end
  end

  -- encryt the message
  if opts.encrypt or opts.sign then
    local recipients = {}
    local rec = message:get_all_recipients()
    for ia in gu.internet_address_list_iter(rec) do
      table.insert(recipients, ia:to_string())
    end

    local pgp_id
    if type(opts.pgp_id) == "function" then
      pgp_id = opts.pgp_id(msg.from)
    elseif type(opts.pgp_id) == "string" then
      pgp_id = opts.pgp_id
    end

    local secure = M.secure(current, pgp_id, opts, recipients)
    if secure then
      current = secure
    end
  end

  message:set_mime_part(current)

  return message
end

return M
