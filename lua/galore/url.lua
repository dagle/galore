-- functions to parse a mailto url.

local function decode(str)
  local function hex_to_char(hex)
    return string.char(tonumber(hex, 16))
  end
  return str:gsub("%%([a-fA-F0-9][a-fA-F0-9])", hex_to_char)
end

-- We only trust these fields.
local function to_template(values)
  local tmpl = {}

  tmpl.headers = {}

  for _, v in ipairs { "to", "cc", "bcc", "subject" } do
    tmpl.headers[v] = values[v]
  end

  tmpl.body = values.body
  tmpl.attachments = values.attach
end

--- @param str string
local function parse_mailto(str)
  -- we do this because the str comes from the
  -- from another program
  if type(str) ~= "string" then
    vim.api.nvim_err_write "Argument should be a string"
    return
  end
  local values = {}

  if not str:sub(1, 7) == "mailto:" then
    return
  end

  str = str:sub(8)

  if string.gmatch(str, "?") then
    local lp = str:gsub(".*?", "")
    for k, v in string.gmatch(lp, "([^&=?]+)=([^&=?]+)") do
      k = k:lower()
      values[k] = decode(v)
    end
  end

  local to = decode(str:gsub("?.*", ""))
  if to and to ~= "" then
    if values["to"] then
      values["to"] = to .. ", " .. values["To"]
    else
      values["to"] = to
    end
  end

  return values
end

return {
  parse_mailto,
  to_template,
}
