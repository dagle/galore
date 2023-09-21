local gu = require('galore.gmime-util')
local ac = require('galore.address-compare')

local lgi = require 'lgi'
local glib = lgi.GLib

local r = require('galore.render')
local config = require('galore.config')
local runtime = require('galore.runtime')
local u = require('galore.util')
local gmime = require("galore.gmime")
local log = require('galore.log')
-- local glib = 

local Templ = {}

--- TODO: s/2//

--- @alias Path_attachment2 {filename: string, path: string, mime_type: string}
--- @alias Part_attachment2 {filename: string, part: GMime.Part, mime_type: string}
--- @alias Data_attachment2 {filename: string, data: userdata, mime_type: string}

--- @alias Attachment2 Path_attachment2 | Part_attachment2 | Data_attachment2

--- @class Template2
--- headers can't contain any of the headers in addresses
--- or date etc. Doing so will cause UB and overwrite it.
--- @field headers table<string, string>
-- add subject?
--- @field addresses table<string, GMime.InternetAddressList|nil>
--- @field date number|nil
--- @field body string[]
--- @field attachments Attachment2[]

---@param templ Template2?
---@return Template2
function Templ:new (templ)
  templ = templ or {
    headers = {},
    addresses = {},
    date = nil,
    body = nil,
    attachments = {},
  }
  setmetatable(templ, self)
  self.__index = self
  return templ
end

function Templ.compose_new()
  local msg = Templ:new()
  local addresses = {}
  local our = gmime.InternetAddressMailbox.new(config.values.name, config.values.primary_email)
  addresses.from = { our }

  msg.addresses = addresses
  return msg
end

function Templ.response_message(message, opts)
  local msg = Templ:new()
  local addresses = msg.addresses
  local headers = msg.headers

  local at = gmime.AddressType

  local our = ac.get_our_email(message)

  addresses.to = our

  local sub = message:get_subject()
  headers.subject = u.add_prefix(sub, 'Re:')

  local from = get_backup(message, { at.REPLY_TO, at.FROM, at.SENDER })

  if not from then
    error("Couldn't reply to message, couldn't find any sender field")
  end

  if not opts.type or opts.type == 'reply' then
    addresses.to = from
  elseif opts.type == 'reply_all' then

    addresses.to = response_addr(message, at.TO, our)
    add_no_dup(addresses.to, from)

    addresses.cc = response_addr(message, at.TO, our)
    addresses.bcc = response_addr(message, at.TO, our)
  elseif opts.type == 'mailinglist' then
    local ml = message:get_header('List-Post')
    if ml then
      addresses.to = gmime.InternetAddressList.parse(nil, ml)
    else
      error("Message isn't a mailing list")
    end
  end

  return msg
end

function Templ.smart_response(message, opts)
  local ml = message:get_header('List-Post')
  if ml then
    opts.type = 'mailinglist'
  end
  return Templ.response_message(message, opts)
end

---@param message GMime.Message
---@param opts any
function Templ:load_body(message, opts)
  local bufrender = r.new({
    verify = false,
  }, r.default_render)
  local buffer = {}
  local state = r.render_message(bufrender, message, buffer, opts)
  self.body = buffer
  vim.list_extend(self.attachments, state.attachments)
end

function Templ.load_template(message)
  local msg = Templ:new()

  for k, v in gu.header_iter(message) do
    msg.headers[k] = v
  end

  msg:load_body(msg)
  return msg
end

local function resent(message, to)
  local msg = Templ:new()
  local headers = msg.headers
  local at = gmime.AddressType
  local addresses = msg.addresses

  local our = ac.get_our_email(message)

  addresses.from = our

  addresses.to = to

  headers['Resent-To'] = pp(message:get_address(at.TO))
  headers['Resent-From'] = pp(message:get_address(at.FROM))
  headers['Resent-Cc'] = pp(message:get_address(at.CC))
  headers['Resent-Bcc'] = pp(message:get_address(at.BCC))
  headers['Recent-Date'] = pp(message:get_date())
  headers['Recent-Id'] = message:get_message_id()
  -- insert before the body
  msg.headers = headers

  return msg
end

function Templ.bounce(message)
  local at = gmime.AddressType
  local from = get_backup(message, { at.REPLY_TO, at.FROM, at.SENDER })

  local msg = resent(message, from)

  local sub = message:get_subject()
  sub = u.add_prefix(sub, 'Return:')
  msg.headers.subject = sub

  table.insert(msg.body, 1, { "--- This email isn't for me ---" })
  return msg
end

function Templ.forward_resent(message, to_str)
  local to = gmime.InternetAddressList.parse(nil, to_str)

  local msg = resent(message, to)

  local sub = message:get_subject()
  sub = u.add_prefix(sub, 'FWD:')
  msg.headers.subject = sub

  table.insert(msg.body, 1, { '--- Forwarded message ---' })

  return msg
end

function Templ.subscribe(message)
  local msg = Templ:new()
  local headers = msg.headers
  local addresses = msg.addresses

  local unsub = message:get_header('List-Subscribe')
  if unsub == nil then
    log.error('Subscribe header not found')
  end
  local our = ac.get_our_email(message)
  addresses.from = { our }
  headers.to = { u.unmailto(unsub) }
  headers.subject = 'Subscribe'
end

function Templ.unsubscribe(message)
  local msg = Templ:new()
  local headers = msg.headers
  local addresses = msg.addresses

  local unsub = message:get_header('List-Unsubscribe')
  if unsub == nil then
    log.error('Subscribe header not found')
  end
  local our = ac.get_our_email(message)
  addresses.from = { our }
  addresses.to = u.unmailto(unsub)
  headers.subject = 'Unsubscribe'
end

--- If the message contains a 'Mail-Reply-To' header, we replace the
--- to address to mft header
--- @param message GMime.Message
function Templ:mft_response(message, opts)
  local addresses = self.addresses

  local mft = message:get_header('Mail-Reply-To')
  if mft ~= nil then
    local to = gmime.InternetAddressList.parse(nil, mft)
    addresses.to = { to }
  end
end

-- insert a mft into the email message if we are not subscribed
--- @param message GMime.Message
function Templ:mft_insert_notsubbed(message)
  local headers = self.headers
  local addresses = self.addresses
  headers['Mail-Reply-To'] = self.headers['Reply-To']
  local to = addresses.to
  local cc = addresses.cc
  local ml = message:get_header('List-Post')
  if ml and not (issubscribed(to) or issubscribed(cc)) then
    ml = gmime.InternetAddressList.parse(nil, ml)
    if ml ~= nil then
      ml:add(headers.From)
      headers['Mail-Followup-To'] = pp(ml)
    end
  end
  self.headers = headers
end

function Templ:send_key(pgp_id)
  local attachments = self.attachments
  pgp_id = pgp_id or config.values.pgp_id
  if not pgp_id then
    error("Couldn't find your pgp key")
  end
  local key = get_key(pgp_id)
  table.insert(
    attachments,
    { filename = 'opengpg_pubkey.asc', data = key, mime_type = 'application/pgp-keys' }
  )
end

return Templ
