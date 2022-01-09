local nm = require('galore.notmuch')
local u = require('galore.util')
local conf = require('galore.config')
local jobs = require('galore.jobs')

local M = {}

local function get(db, name)
	return table.concat(u.collect(nm.config_get_values_string(db, name)))
end

local function gets(db, name)
	return u.collect(nm.config_get_values_string(db, name))
end

function M.change_tag(message, str)
	local start, stop = string.find(str, "[+-]%a+")
	if start == nil then
		return
	end
	local tag = string.sub(str, start+1, stop)
	local status
	if string.sub(str, start, start) == "+" then
		status = nm.message_add_tag(message, tag)
	else
		status = nm.message_remove_tag(message, tag)
	end
	if status ~= 0 then
		-- print a warning
	end
	if stop == #str then
		return
	end
	M.change_tag(message, string.sub(str, stop+1, #str))
end

-- gets a single massage from an unique id
local function id_get_message(db, id)
	local q = nm.create_query(db, "id:".. id)
	for m in nm.query_get_messages(q) do
		return m
	end
end

function M.with_db_writer(db, func)
	local path = nm.db_get_path(db)
	local write_db = nm.db_open(path, 1)
	func(write_db)
	nm.db_close(write_db)
end

function M.with_message_writer(message, func)
	local id = nm.message_get_id(message)
	local db = nm.message_get_db(message)
	M.with_db_writer(db, function(new_db)
		local new_message = id_get_message(new_db, id)
		func(new_message)
	end)
end

-- we can't get the db
-- function M.with_thread_writer(thread, func)
-- 	local id = nm.thread_get_id(message)
-- 	local db = nm.thread_get_d
-- end

local function tag_unread(message)
	-- M.change_tag(message, "-unread +read")
	M.with_message_writer(message, function(new_message)
		M.change_tag(new_message, "-unread")
	end)
end

function M.gen_config(path, config, profile)
	local mode = 0
	local db = nm.db_open_with_config(path, mode, config, profile)
	local name = get(db, "user.name")
	local primary_email = get(db, "user.primary_email")
	local other_email = gets(db, "user.other_email")
	local exclude_tags = gets(db, "search.exclude_tags")
	conf.values.db = db
	conf.values.name = name
	conf.values.primary_email = primary_email
	conf.values.other_email = other_email
	conf.values.exclude_tags = exclude_tags
	conf.values.show_html = jobs.html
	conf.values.tag_unread = tag_unread
end
return M
