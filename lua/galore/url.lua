local function firstToUpper(str)
  return (str:gsub('^%l', string.upper))
end

local function decode(str)
  local function hex_to_char(hex)
    return string.char(tonumber(hex, 16))
  end
  return str:gsub('%%([a-fA-F0-9][a-fA-F0-9])', hex_to_char)
end

local function parse_mailto(str)
  if type(str) ~= 'string' then
    vim.api.nvim_err_write('Argument should be a string')
    return
  end
  local values = {}

  str = str:gsub('mailto:', '')
  if string.gmatch(str, '?') then
    local lp = str:gsub('.*?', '')
    for k, v in string.gmatch(lp, '([^&=?]+)=([^&=?]+)') do
      k = firstToUpper(k)
      values[k] = decode(v)
    end
  end
  local to = decode(str:gsub('?.*', ''))
  --- dunno if we should concat these
  if to and to ~= '' then
    if values['To'] then
      values['To'] = to .. ', ' .. values['To']
    else
      values['To'] = to
    end
  end
  return values
end

local function normalize(tbl)
  return { To = tbl.To, Cc = tbl.Cc, Subject = tbl.Subject, Attach = tbl.Attach, Body = tbl.Body }
end

return {
  parse_mailto,
  normalize,
}
