command -nargs=0 Galore :lua require('galore').open()
command -nargs=? GaloreCompose :lua require('galore').compose(<f-args>)
command -nargs=0 GaloreNew :lua require('galore.jobs').new()
