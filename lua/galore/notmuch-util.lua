local nm = require("galore.notmuch")
local u = require("galore.util")

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
		return f(thread)
	end
end

--- Get a single message and convert it into a line
function M.get_message(message)
	local id = nm.message_get_id(message)
	local tid = nm.message_get_thread_id(message)
	local filenames = u.collect(nm.message_get_filenames(message))
	local sub = nm.message_get_header(message, "Subject")
	local tags = u.collect(nm.message_get_tags(message))
	local from = nm.message_get_header(message, "From")
	local date = nm.message_get_date(message)
	local key = u.collect(nm.message_get_properties(message, "session-key", true))
	return {
		id = id,
		tid = tid,
		filenames = filenames,
		level = 1,
		pre = "",
		index = 1,
		total = 1,
		date = date,
		from = from,
		sub = sub,
		tags = tags,
		key = key,
	}
end

local function pop_helper(line, iter, i)
	for message in iter do
		if line.id == nm.message_get_id(message) then
			line.index = i
			break
		end
		local new_iter = nm.message_get_replies(message)
		i = pop_helper(line, new_iter, i+1)
	end
	return i
end

function M.line_populate(db, line)
	local id = line.id
	local query = nm.create_query(db, "mid:" .. id)
	for thread in nm.query_get_threads(query) do
		local i = 1
		line.total = nm.thread_get_total_messages(thread)
		local iter = nm.thread_get_toplevel_messages(thread)
		pop_helper(line, iter, i)
	end
end

local function update_tags(message, changes)
	nm.message_freeze(message)
	for _, change in ipairs(changes) do
		local status
		local op = string.sub(change, 1, 1)
		local tag = string.sub(change, 2)
		if op == "-" then
			status = nm.message_remove_tag(message, tag)
		elseif op == "+" then
			status = nm.message_add_tag(message, tag)
		end
		if status ~= nil then
			-- print error
		end
	end
	nm.message_thaw(message)
	nm.message_tags_to_maildir_flags(message)
end

function M.change_tag(db, id, str)
	local changes = vim.split(str, " ")
	local message = nm.db_find_message(db, id)
	if message == nil then
		vim.notify("Can't change tag, message not found", vim.log.levels.ERROR)
		return
	end
	nm.db_atomic_begin(db)
	update_tags(message, changes)
	nm.db_atomic_end(db)
end

function M.tag_if_nil(db, id, tag)
	local message = nm.db_find_message(db, id)
	local tags = u.collect(nm.message_get_tags(message))
	if vim.tbl_isempty(tags) and tag then
		M.change_tag(db, id, tag)
	end
end

function M.update_line(db, line_info)
	local message = nm.db_find_message(db, line_info.id)
	local new_info = M.get_message(message)
	line_info.id = new_info.id
	line_info.filenames = new_info.filenames
	line_info.tags = new_info.tags
end

return M
