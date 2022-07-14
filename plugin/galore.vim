command -nargs=0 Galore :lua require('galore').open()
command -nargs=? GaloreCompose :lua require('galore').compose(<f-args>)
command -nargs=0 GaloreNew :lua require('galore.jobs').new()
"command -nargs=1 GaloreSearch :lua require('galore.message_browser'):create(<f-args>, "replace", nil)

"command -nargs=1 GaloreChangeTag :lua require("galore.command").current(require("galore.callback").change_tag, <f-args>)
" command -nargs=1 GaloreAddAttachment :lua require("galore.command").method('add:_attachment', <f-args>)
