local ok, cmp = pcall(require, "cmp")
if not ok then
	print("Error can't load cmp needed for address book")
	return
end

local Job = require("plenary.job")
local u = require("galore.util")

local source = {}

source.query = "not list and not tag:spam"

source.new = function()
	return setmetatable({ cache = {} }, {
		__index = source,
	})
end

---Return this source is available in current context or not. (Optional)
---@return boolean
function source:is_available()
	return vim.bo.filetype == "mail"
end

---Return the debug name of this source. (Optional)
---@return string
function source:get_debug_name()
	return "notmuch_nm"
end

---Return keyword pattern for triggering completion. (Optional)
---If this is ommited, nvim-cmp will use default keyword pattern. See |cmp-config.completion.keyword_pattern|
---@return string
function source:get_keyword_pattern()
	return [[\k\+]]
end

---Return trigger characters for triggering completion. (Optional)
-- can we make this work, so @ is part of the match?
-- function source:get_trigger_characters()
-- 	return { '@' }
-- end

---Invoke completion. (Required)
---@param params cmp.SourceCompletionApiParams
---@param callback fun(response: lsp.CompletionResponse|nil)
function source:complete(params, callback)
	local bufnr = vim.api.nvim_get_current_buf()

	if u.completion_header(params.context.cursor_before_line) then
		callback(nil)
		return
	end
	if not self.cache[bufnr] then
		Job
			:new({
				command = "notmuch",
				args = { "address", self.query },
				on_exit = function(j, ret_val)
					if ret_val ~= 0 then
						callback(nil)
						return
					end
					local ret = j:result()
					local tbl = {}
					for _, mbox in ipairs(ret) do
						table.insert(tbl, {
							label = string.format("%s", mbox),
						})
					end
					self.cache[bufnr] = tbl
					callback(self.cache[bufnr])
				end,
			})
			:start()
	else
		callback(self.cache[bufnr])
	end
end

---Resolve completion item. (Optional)
---@param completion_item lsp.CompletionItem
---@param callback fun(completion_item: lsp.CompletionItem|nil)
function source:resolve(completion_item, callback)
	callback(completion_item)
end

---Execute command after item was accepted.
---@param completion_item lsp.CompletionItem
---@param callback fun(completion_item: lsp.CompletionItem|nil)
function source:execute(completion_item, callback)
	callback(completion_item)
end

cmp.register_source("notmuch_addr", source.new())
