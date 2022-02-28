command Galore :lua require('galore').open()
command GaloreCompose :lua require('galore.compose').create("tab")
command GaloreNew :lua require('galore.jobs').new()
" command AddAttachment :lua require('galore.compose').add_attachment("<args>")
" command -complete=custom,notmuch#CompSearchTerms -nargs=* NmSearch :call v:lua.require('notmuch').search_terms("<args>")

" vim: tabstop=2:shiftwidth=2:expandtab
