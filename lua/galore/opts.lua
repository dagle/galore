-- Populate default options from the config file
local config = require('galore.config')

local M = {}

--- TODO how should keybindings work, should we extend the table or overwrite it?

local function parse_bufname(opt, def)
  if type(opt) == 'string' then
    return function()
      return opt
    end
  elseif type(opt) == 'function' then
    return opt
  elseif type(opt) == 'nil' then
    return def
  else
    error('Bad argument to bufname, only function(string) or string is allowed')
  end
end

local function fallbacks(...)
  for i = 1, select('#', ...) do
    local value = select(i, ...)
    if value ~= nil then
      return value
    end
  end
end

local function keybindings(opt, def)
  return fallbacks(opt, def, config.values.key_bindings.default)
end

--- values that should be copied when cloning opts from one buffer to another.
--- atm we copy nothing and rely on the default opts, maybe this isn't what we
--- want. We let future tell.
function M.bufcopy(opts)
  -- local new = vim.deepcopy(opts)
  return {}
end

local function runtime(opts)
  opts.runtime = vim.F.if_nil(opts.runtime, {})
  opts.runtime.config = vim.F.if_nil(opts.runtime.config, config.values.nm_config)
  opts.runtime.db_path = vim.F.if_nil(opts.runtime.db_path, config.values.db_path)
  opts.runtime.profile = vim.F.if_nil(opts.runtime.profile, config.values.nm_profile)
  opts.runtime.mail_root = vim.F.if_nil(opts.runtime.config, config.values.mail_root)
  opts.runtime.exclude_tags =
    vim.F.if_nil(opts.runtime.exclude_tags, config.values.synchronize_flags)
  opts.runtime.synchronize_flags =
    vim.F.if_nil(opts.runtime.synchronize_flags, config.values.synchronize_flags)
end

--- common values for all buffers
function M.buffer(opts)
end

function M.saved_options(opts)
  opts.bufname = vim.F.if_nil(opts.bufname, 'galore-saved')
  opts.key_bindings = keybindings(opts.key_bindings, config.values.key_bindings.saved)
  opts.exclude_tags = vim.F.if_nil(opts.exclude_tags, config.values.exclude_tags)
  opts.default_browser = vim.F.if_nil(opts.default_browser, config.values.default_browser)
  opts.init = vim.F.if_nil(opts.init, config.values.bufinit.saved)
end

local function default_view(def_view, context_value)
  if def_view then
    if def_view == 'context' then
      return context_value
    end
  end
  if config.values.default_view then
    if config.values.default_view == 'context' then
      return context_value
    end
  end
  return vim.F.if_nil(def_view, config.values.default_view)
end

local function browser_opts(opts)
  opts.exclude_tags = vim.F.if_nil(opts.exclude_tags, config.values.exclude_tags)
  opts.sort = vim.F.if_nil(opts.sort, config.values.sort)
  opts.limit = vim.F.if_nil(opts.limit, config.values.browser_limit)
  -- change this to format
  opts.show_message_description =
    vim.F.if_nil(opts.show_message_description, config.values.show_message_description)
  opts.emph = vim.F.if_nil(opts.emph, config.values.default_emph)
  runtime(opts)
end

function M.tmb_options(opts)
  opts.bufname = parse_bufname(opts.bufname, function(search)
    return 'galore-tmb: ' .. search
  end)
  opts.thread_reverse = vim.F.if_nil(opts.thread_reverse, config.values.thread_reverse)
  opts.thread_expand = vim.F.if_nil(opts.thread_expand, config.values.thread_expand)
  browser_opts(opts)

  opts.key_bindings =
    keybindings(opts.key_bindings, config.values.key_bindings.thread_message_browser)
  opts.default_view = default_view(default_view, 'message_view')
  opts.init = vim.F.if_nil(opts.init, config.values.bufinit.thread_message_browser)
end

function M.mb_options(opts)
  opts.bufname = parse_bufname(opts.bufname, function(search)
    return 'galore-messages: ' .. search
  end)
  browser_opts(opts)
  opts.key_bindings = keybindings(opts.key_bindings, config.values.key_bindings.message_browser)
  opts.default_view = default_view(default_view, 'message_view')
  opts.init = vim.F.if_nil(opts.init, config.values.bufinit.message_browser)
end

function M.threads_options(opts)
  opts.bufname = parse_bufname(opts.bufname, function(search)
    return 'galore-threads: ' .. search
  end)
  browser_opts(opts)
  opts.default_view = default_view(default_view, 'threads_view')
  opts.key_bindings = keybindings(opts.key_bindings, config.values.key_bindings.thread_browser)
  opts.init = vim.F.if_nil(opts.init, config.values.bufinit.thread_browser)
end

function M.view_options(opts)
  opts.bufname = parse_bufname(opts.bufname, function(filename)
    return filename
  end)
  opts.tag_unread = vim.F.if_nil(opts.tag_unread, config.values.tag_unread)
  opts.empty_tag = vim.F.if_nil(opts.empty_tag, config.values.empty_tag)
  opts.key_bindings = keybindings(opts.key_bindings, config.values.key_bindings.message_view)
  opts.key_writeback = vim.F.if_nil(opts.key_writeback, config.values.key_writeback)
  opts.init = vim.F.if_nil(opts.init, config.values.bufinit.message_view)
end

function M.thread_view_options(opts)
  opts.bufname = parse_bufname(opts.bufname, function(tid)
    return 'galore-tid:' .. tid
  end)
  opts.tag_unread = vim.F.if_nil(opts.tag_unread, config.values.tag_unread)
  opts.thread_reverse = vim.F.if_nil(opts.thread_reverse, config.values.thread_reverse)
  opts.empty_tag = vim.F.if_nil(opts.empty_tag, config.values.empty_tag)
  opts.key_bindings = keybindings(opts.key_bindings, config.values.key_bindings.thread_view)
  opts.key_writeback = vim.F.if_nil(opts.key_writeback, config.values.key_writeback)
  opts.init = vim.F.if_nil(opts.init, config.values.bufinit.thread_view)
  opts.sort = vim.F.if_nil(opts.sort, config.values.sort)
  opts.index = vim.F.if_nil(opts.index, 1)
  -- add render opts here!
  -- can we make a way for the user to select a render?
  --
  -- extra_keys ?
  -- purge_empty ?
end

function M.render_options(opts)
  opts.mulilingual = vim.F.if_nil(opts.mulilingual, config.values.multilingual)
  opts.lang_order = vim.F.if_nil(opts.lang_order, config.values.lang_order)
  opts.alt_mode = vim.F.if_nil(opts.alt_mode, config.values.alt_mode)
  opts.alt_order = vim.F.if_nil(opts.alt_order, config.values.alt_order)
  opts.qoute_header = vim.F.if_nil(opts.qoute_header, config.values.qoute_header)
  opts.show_html = vim.F.if_nil(opts.show_html, config.values.show_html)
  opts.annotate_signature = vim.F.if_nil(opts.annotate_signature, config.values.annotate_signature)
  opts.decrypt_flags = vim.F.if_nil(opts.decrypt_flags, config.values.decrypt_flags)
end

function M.compose_options(opts)
  local builder = require('galore.compose.builder')
  opts.bufname = parse_bufname(opts.bufname, function()
    return vim.fn.tempname()
  end)
  opts.empty_topic = fallbacks(opts.empty_topic, config.values.empty_topic, 'Empty subject')
  opts.key_bindings = keybindings(opts.key_bindings, config.values.key_bindings.compose)
  opts.pre_sent_hooks = vim.F.if_nil(opts.pre_sent_hooks, config.values.pre_sent_hooks)
  opts.post_sent_hooks = vim.F.if_nil(opts.post_sent_hooks, config.values.post_sent_hooks)
  opts.compose_headers = vim.F.if_nil(opts.compose_headers, config.values.compose_headers)
  opts.draft_dir = vim.F.if_nil(opts.draft_dir, config.values.draft_dir)
  opts.draft_tag = vim.F.if_nil(opts.draft_tag, config.values.draft_tag)
  opts.sent_dir = vim.F.if_nil(opts.sent_dir, config.values.sent_dir)

  opts.extra_headers = vim.F.if_nil(opts.extra_headers, config.values.extra_headers)
  opts.crypto_context = vim.F.if_nil(opts.crypto_context, config.values.crypto_context)
  opts.pgp_id = vim.F.if_nil(opts.pgp_id, config.values.pgp_id)
  opts.draft_encrypt = vim.F.if_nil(opts.draft_encrypt, config.values.draft_encrypt)

  -- opts.encrypt = vim.F.if_nil(opts.encrypt, config.values.encrypt)

  opts.bodybuilder = vim.F.if_nil(opts.bodybuilder, builder.textbuilder)
  -- opts.bodybuilder = fallbacks(opts.bodybuilder, config.values.bodybuilder, builder.textbuilder)
  ---
  opts.init = vim.F.if_nil(opts.init, config.values.bufinit.compose)
end

return M
