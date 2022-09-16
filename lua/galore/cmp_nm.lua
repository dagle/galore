local ok, cmp = pcall(require, "cmp")

if not ok then
	vim.api.nvim_err_writeln("Error can't load cmp needed for address book")
	return
end
local Job = require("plenary.job")

local completion_pattern =  "\\c^\\(Resent-\\)\\?\\(To\\|B\\?Cc\\|Reply-To\\|From\\|Mail-Followup-To\\|Mail-Copies-To\\):"

local defaults = {
  line_pattern = completion_pattern,
  query = "not list and not tag:spam"
}

local source = {}

source.new = function()
	return setmetatable({ cache = {} }, {
		__index = source,
	})
end

---@return boolean
function source:is_available()
	-- local opts = vim.tbl_deep_extend('keep', params.option, defaults)
	-- return vim.bo.filetype == opts.mail
	return vim.bo.filetype == "mail"
end

---@return string
function source:get_debug_name()
	return "notmuch"
end

---@return string
function source:get_keyword_pattern(params)
	return [[\K\+]]
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
	local opts = vim.tbl_deep_extend('keep', params.option, defaults)
	local bufnr = vim.api.nvim_get_current_buf()

	if not (vim.fn.match(params.context.cursor_before_line, opts.line_pattern) >= 0) then
		return
	end

	if not self.cache[bufnr] then
		Job
			:new({
				command = "notmuch",
				args = {
					"address",
					"--deduplicate=address",
					opts.query },
				on_exit = function(j, ret_val)
					if ret_val ~= 0 then
						callback(nil)
						return
					end
					local ret = j:result()
					local tbl = {}
					for _, mbox in ipairs(ret) do
						table.insert(tbl, {
							label =  mbox
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
