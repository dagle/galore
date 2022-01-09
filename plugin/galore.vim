command Galore :lua require('galore').open()
" command -complete=custom,notmuch#CompSearchTerms -nargs=* NmSearch :call v:lua.require('notmuch').search_terms("<args>")

" vim: tabstop=2:shiftwidth=2:expandtab
