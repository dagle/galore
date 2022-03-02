local nm = require("galore.notmuch")
local gu = require("galore.gmime-util")
local u = require("galore.util")
local conf = require("galore.config")

local M = {}

--- The thread will be freed on return, don't return the thread
--- @param message any a message
--- @param f function a function that takes a thread
--- @return any returns the value after running f
function M.message_with_thread(message, f)
	local id = nm.message_get_thread_id(message)
	local db = nm.message_get_db(message)
	local query = nm.create_query(db, "thread:" .. id)
	for thread in nm.query_get_threads(query) do
		local ret = f(thread)
		nm.query_destroy(query)
		return ret
	end
	-- this shouldn't really happen
	nm.query_destroy(query)
end

local function _get_index(messages, m1, i)
	for m2 in messages do
		if nm.message_get_id(m1) == nm.message_get_id(m2) then
			return true, i
		end
		local sorted = nm.message_get_replies(m2)
		local match, i2 = _get_index(sorted, m1, i + 1)
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

local special_tags = {
    draft = true,
    flagged = true,
    passed = true,
    replied = true,
    unread = true,
}

--- @param message notmuch.Message
--- @param str string + adds tag, - removes tag
--- @param tags string current tags the message has
--- @return boolean if the change in tags can would trigger a maildir change
local function _change_tag(message, str, tags, state)
	local start, stop = string.find(str, "[+-]%a+")
	local special = false
	if start == nil then
		return
	end
	local tag = string.sub(str, start + 1, stop)
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
		vim.notify("Change tag failed with: " .. status)
		return false
	end
	special = special_tags[tag]
	if stop == #str then
		return
	end
	return special or _change_tag(message, string.sub(str, stop + 1, #str))
end

-- gets a single massage from an unique id
local function id_get_message(db, id)
	local q = nm.create_query(db, "id:" .. id)
	for m in nm.query_get_messages(q) do
		return m, q
	end
end

-- can I make a async version of these
function M.with_db_writer(db, func)
	local path = nm.db_get_path(db)
	local write_db = nm.db_open(path, 1)
	nm.db_atomic_begin(write_db)
	func(write_db)
	nm.db_atomic_end(write_db)
	nm.db_destroy(write_db)
end

-- function M.with_db_writer(db, func)
-- 	nm.db_reopen(db, 1)
-- 	nm.db_atomic_begin(db)
-- 	func(db)
-- 	nm.db_atomic_end(db)
-- 	nm.db_reopen(db, 0)
-- end

function M.with_message_writer(message, func)
	local id = nm.message_get_id(message)
	local db = nm.message_get_db(message)
	M.with_db_writer(db, function(new_db)
		local new_message, q = id_get_message(new_db, id)
		func(new_message)
		nm.query_destroy(q)
	end)
end

-- XXX this might be a bad idea since it makes it harder to re-render?
local function _optimize_search(db, messages, str)
	-- get all the messages
	local querybuf = {}
	for message in messages do
		table.insert(querybuf, "id:" .. nm.message_get_id(message))
	end
	local query = table.concat(querybuf, " or ")
	local q = nm.create_query(db, query)
	return nm.query_get_messages(q), q
	-- update the query to only include the ones that needs to be updated
end

local function update_message(message, str)
	local values = u.values(nm.message_get_tags(message))
	nm.message_freeze(message)
	local change = _change_tag(message, str, values)
	nm.message_thaw(message)
	nm.message_tags_to_maildir_flags(message)
	return change
end

function M.change_tag(db, line_infos, str)
	if type(line_infos[1]) == "table" then
		M.with_db_writer(db, function(new_db)
			-- maybe do _optimized_query, so we fetch all the messages and only
			-- messages that needs to be updated, that we we only need to do one query
			-- local new_messages = _optimize_search(new_db, messages, str)
			local rets = {}
			for _, line_info in ipairs(line_infos) do
				local new_message, q = id_get_message(new_db, line_info[1])
				local ret = update_message(new_message, str)
				table.insert(rets, ret)
				nm.query_destroy(q)
			end
			return rets
		end)
	else
		M.with_db_writer(db, function(new_db)
			local new_message, q = id_get_message(new_db, line_infos[1])
			local change = update_message(new_message, str)
			nm.query_destroy(q)
			return change
		end)
	end
end

function M.tag_unread(line_info)
	return M.change_tag(conf.values.db, line_info, "-unread")
end

-- local function M_change_tag_job(db, messages, str)
-- 	if type(messages) == "table" then
-- 		P(nil)
-- 	else
--
-- 		Job:new({
--
-- 		)
-- 	end
-- end

local function message_description(level, tree, thread_num, thread_total, date, from, subtitle, tags)
	local t = table.concat(tags, " ")
	local formated
	-- from = gu.show_addr(from, u.addr_trim, 25)
	from = u.string_setlength(from, 25)
	if thread_num > 1 then
		formated = string.format("%s [%02d/%02d] %s│ %s▶ (%s)", date, thread_num, thread_total, from, tree, t)
	else
		formated = string.format("%s [%02d/%02d] %s│ %s (%s)", date, thread_num, thread_total, from, subtitle, t)
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
	conf.values.show_message_description = message_description
end
return M
