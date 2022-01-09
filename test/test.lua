local gm = require('galore.gmime')
local render = require('galore.render')
-- local log = require('log')

-- because we don't have vim.inspect

if P == nil then
	function dump(o)
		if type(o) == 'table' then
			local s = '{ '
			for k,v in pairs(o) do
				if type(k) ~= 'number' then k = '"'..k..'"' end
				s = s .. '['..k..'] = ' .. dump(v) .. ','
			end
			return s .. '} '
		else
			return tostring(o)
		end
	end
	function P(o)
		print(dump(o))
	end
end


render.draw = function(_, array)
	P(array)
end

-- first run shouldn't be equal, because we fix and clean up some
-- parts of the message. But after the first clean, reading and writing
-- messages should be compareable.
-- local file = ""
-- local message = gm.parse_message(file)
-- local headers = render.get_headers(message)
-- local structured = render.show_message(message)
--
-- local updated = render.create_message(structured.body, headers, structured.attachment)
--
-- gm.write_message("file" .. ".test1", updated)
--
-- for i in 1,3  do
-- 	file = "" .. "test" .. i
-- 	message = gm.parse_message(file)
-- 	headers = render.get_headers(message)
-- 	structured = render.show_message(message)
--
-- 	updated = render.create_message(structured.body, headers, structured.attachment)
-- 	gm.write_message("file" .. ".test" .. i, updated)
-- end
--
-- for i in 1,2 do
-- 	local file1 = "" .. "test" .. i
-- 	local file2 = "" .. "test" .. i+1
-- 	diff(file1, file2)
-- end

local path = "/home/dagle/mail/posteo/INBOX/cur"
local files = io.popen("ls " .. path)
gm.init()
local reply_filter= gm.filter_reply(true)
for file in files:lines() do
	P(file)
	local newfile = path .. file
	local gmessage = gm._parse_message(newfile)
	if gmessage then
		render.show_message(gmessage, nil, false)
	end
end
