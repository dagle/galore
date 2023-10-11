local config = require "galore.config"
local match = require("galore.account.match")

local M = {}

--- An account manager
--- An account is required to have these functions but 
--- default values of most of these

--- @class Account
--- @field email GMime.InternetAddressMailbox
--- @field match Matcher
--- @field draft_dir string
--- @field draft_tag string
--- @field sent_tag string
--- @field pgp_id string
--- @field sign boolean -- "force" | "try" | "false", force => fail if we fail to sign
--- @field encrypt boolean -- "force" | "try" | "false",
--- @field draft_encrypt boolean 
--- @field sent_encrypt boolean
--- @field autocrypt_enable boolean
--- @field autocrypt_insert boolean maybe not
--- @field compose_headers table
--- @field custom_headers function(message)
--- @field empty_subject string
--- @field qoute_header function(date, author)
--- @field send_cmd function(message)
--- @field init function()

---@param email string
---@param settings table | nil options from default accout if not set
---@return Account
function M.new(email, settings)
  settings = settings or {}
  if type(email) ~= "string" then
    error("email has to be a string")
  end
  local account = vim.tbl_deep_extend("keep", settings, config.default_account)
  account.email = email
  return account
end

--- @param account Account
function M.init(account)
  local gmime = require("galore.gmime")

  local list = gmime.InternetAddressList.parse(nil, account.email)
  if not list or list:length() ~= 1 then
    error("Couldn't parse email: %s", account.email)
  end
  local parsed = list:get_address(0)
  account.email = parsed

  --- we install a default matcher
  if account.match == nil then
    account.match = match.detect
  end

  --- create matcher
  account.match = account.match(account.email)

  --- create update autocrypt todo

  --- run init
  if account.init then
    account:init()
  end
end

return M
