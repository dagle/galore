local nm = require('galore.notmuch')
local gu = require('galore.gmime-util')
local u = require('galore.util')
local conf = require('galore.config')
local jobs = require('galore.jobs')

local M = {}

--- The thread will be freed on return, don't return the thread
--- @param message any a message
--- @param f function a function that takes a thread
--- @return any returns the value after running f
function M.message_with_thread(message, f)
	local id = nm.message_get_thread_id(message)
	local db = nm.message_get_db(message)
	local query = nm.create_query(db, "thread:"..id)
	for thread in nm.query_get_threads(query) do
		local ret = f(thread)
		nm.query_destroy(query)
		return ret
	end
	-- this shouldn't really happen
	nm.query_destro(query)
end

local function _get_index(messages, m1, i)
	for m2 in messages do
		if nm.message_get_id(m1) == nm.message_get_id(m2) then
			return true, i
		end
		local sorted = nm.message_get_replies(m2)
		local match, i2 = _get_index(sorted, m1, i+1)
		if match then
			return match, i2
		end
		i = i2
	end
	return false, i
end

--- gets the index of message is in a thread
function M.get_index(thread, m1)
	local messages = nm.thread_get_toplevel_messages(thread)
	-- for m2 in messages do
	local match, i = _get_index(messages, m1, 1)
	if match then
		return i
	end
	return nil
end

local function get(db, name)
	return table.concat(u.collect(nm.config_get_values_string(db, name)))
end

local function gets(db, name)
	return u.collect(nm.config_get_values_string(db, name))
end

local function _change_tag(message, str, tags)
	local start, stop = string.find(str, "[+-]%a+")
	if start == nil then
		return
	end
	local tag = string.sub(str, start+1, stop)
	local status = 0
	if string.sub(str, start, start) == "+" then
		if not tags[tag] then
			status = nm.message_add_tag(message, tag)
		end
	else
		if tags[tag] then
			status = nm.message_remove_tag(message, tag)
		end
	end
	if status ~= 0 then
		print("Change tag failed with: " .. status)
	end
	if stop == #str then
		return
	end
	_change_tag(message, string.sub(str, stop+1, #str))
end

-- gets a single massage from an unique id
local function id_get_message(db, id)
	local q = nm.create_query(db, "id:".. id)
	for m in nm.query_get_messages(q) do
		return m, q
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
		local new_message, q = id_get_message(new_db, id)
		func(new_message)
		nm.query_destroy(q)
	end)
end

function M.change_tag(message, str)
	M.with_message_writer(message, function(new_message)
		local values = u.values(nm.message_get_tags(new_message))
		_change_tag(new_message, str, values)
	end)
end

local function tag_unread(message)
	M.change_tag(message, "-unread")
end

local function addr_trim(name, addr)
	if name ~= nil and name ~= "" then
		return string.gsub(name,"via .*", "")
	end
	return addr
end

local function message_description(level, tree, thread_num, thread_total, date, from, subtitle, tags)
	local t = table.concat(tags, " ")
	local formated
	from = gu.show_addr(from, addr_trim, 25)
	if thread_num > 1 then
		formated = string.format("%s [%02d/%02d] %s; %s▶ (%s)", date, thread_num, thread_total, from, tree, t)
	else
		formated = string.format("%s [%02d/%02d] %s; %s (%s)", date, thread_num, thread_total, from, subtitle, t)
	end
	formated = string.gsub(formated, "\n", "")
	return formated
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
	conf.values.show_message_description = message_description
end
return M
