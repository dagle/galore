local M = {}
local health = vim.health

M.check = function()
  health.start "Galore health check"
  if vim.fn.executable "notmuch" == 1 then
    health.ok "Found notmuch"
  else
    health.error "Could not find notmuch, galore won't work"
  end
  if vim.fn.executable "nm-livesearch" == 1 then
    health.ok "found the executable nm-livesearch"
  else
    health.error "Could not find nm-livesearch, galore won't work"
  end
  if vim.fn.executable "browser-pipe" == 1 then
    health.ok "found the executable browser-pipe"
  else
    health.error "Could not find browser-pipe, won't be able to view html in an external browser"
  end
  if vim.fn.executable "file" == 1 then
    health.ok "found the find executable"
  else
    health.error "Could not find file, galore won't work"
  end
  if pcall(require, "cmp") then
    health.ok "Found cmp"
  else
    health.info "Missing cmp for email completion"
  end
  if pcall(require, "telescope") then
    health.ok "Found telescope"
  else
    health.info "Missing telescope for email search"
  end
  if vim.fn.executable "mates" == 1 then
    health.ok "Found mates"
  else
    health.info "Missing optional mates for vcard support"
  end
  if vim.fn.executable "w3m" == 1 then
    health.ok "found w3m"
  else
    health.info "Missing w3m, the default html render"
  end
end

return M
