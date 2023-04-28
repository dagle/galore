local gu = require('galore.gmime-util')
local r = require('galore.render')
local actions = require('telescope.actions')
local fb_utils = require('telescope._extensions.file_browser.utils')
local action_state = require('telescope.actions.state')
local Path = require('plenary.path')
local scan = require('plenary.scandir')

local Message = {}

local function filter(object, types)
  if types == nil or vim.tbl_isempty(types) then
    return true
  end
  for _, v in ipairs(types) do
    if gu.mime_type(object) == v then
      return true
    end
  end
  return false
end

local function show_tree(object, types)
  if filter(object, types) then
    return gu.mime_type(object)
  end
end

function Message.parts_browser(message, selected, types)
  local state = {}
  state.select = {}
  state.part = {}
  local function browser_fun(_, part, level)
    local strbuf = {}
    for _ = 1, level - 1 do
      table.insert(strbuf, '\t')
    end
    local entry = show_tree(part, types)
    if entry then
      table.insert(strbuf, entry)
      local str = table.concat(strbuf)
      table.insert(state.select, str)
      table.insert(state.part, part)
    end
  end
  gu.message_foreach_level(message, browser_fun)
  vim.ui.select(state.select, {}, function(_, idx)
    if selected and idx then
      selected(state.part[idx])
    end
  end)
end

function Message.parts_pipe(message, cmd)
    local jobs = require('galore.jobs')
    local callback = function(object)
      local content = object:get_content_type()
      if content:is_type('text', '*') then
        local opts = {}
        --- this is safe because the object has to be a part
        local str = r.part_to_string(object, opts)
        jobs.pipe_str(cmd, str)
      end
    end
    Message.parts_browser(message, callback)
end

Message.browser = function(callback, fallback, opts)
  opts = opts or {}
  opts.prompt_title = opts.prompt_title or 'Save file'
  opts.attach_mappings = function(prompt_bufnr, _)
    actions.select_default:replace(function()
      local entry = action_state.get_selected_entry()
      if entry and entry.Path:is_dir() then
        local current_picker = action_state.get_current_picker(prompt_bufnr)
        local finder = current_picker.finder
        local path = vim.loop.fs_realpath(entry.path)

        if finder.files and finder.collapse_dirs then
          local upwards = path == Path:new(finder.path):parent():absolute()
          while true do
            local dirs = scan.scan_dir(path, { add_dirs = true, depth = 1, hidden = true })
            if #dirs == 1 and vim.fn.isdirectory(dirs[1]) then
              path = upwards and Path:new(path):parent():absolute() or dirs[1]
              -- make sure it's upper bound (#dirs == 1 implicitly reflects lower bound)
              if path == Path:new(path):parent():absolute() then
                break
              end
            else
              break
            end
          end
        end

        finder.files = true
        finder.path = path
        fb_utils.redraw_border_title(current_picker)
        current_picker:refresh(finder, { reset_prompt = true, multi = current_picker._multi })
      else
        actions.close(prompt_bufnr)
        local file
        if opts.only_navigation then
          return
        end

        if opts.strict_line or not entry then
          local text = action_state.get_current_line()
          file = text or fallback
        else
          file = entry.path
        end
        if file then
          callback(file)
        end
      end
    end)
    return true
  end
  require('telescope').extensions.file_browser.file_browser(opts)
end

Message.save_attachment = function(attachment, opts)
  Message.browser(function (file)
    gu.save_part(attachment.part, file)
  end, attachment.filename, opts)
end

Message.add_attachment = function(compose, opts)
  Message.browser(function(file)
    compose:add_attachment_path(file)
  end, nil, opts)
end

return Message
