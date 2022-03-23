command -nargs=0 Galore :lua require('galore').open()
command -nargs=0 GaloreCompose :lua require('galore.compose').create("replace")
command -nargs=0 GaloreNew :lua require('galore.jobs').new()
command -nargs=1 GaloreSearch :lua require('galore.message_browser'):create(<f-args>, "replace", nil)
command -nargs=1 GaloreSearchThread :lua require('galore.thread_message_browser'):create(<f-args>, "replace", nil)

" command AddAttachment :lua require('galore.compose').add_attachment("<args>")
" command -complete=custom,notmuch#CompSearchTerms -nargs=* NmSearch :call v:lua.require('notmuch').search_terms("<args>")

" vim: tabstop=2:shiftwidth=2:expandtab
