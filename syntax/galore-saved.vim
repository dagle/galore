syntax region GaloreSaved start=/^/ end=/$/					oneline contains=GaloreSavedCount

syntax match GaloreSavedCount "\d*"				contained nextgroup=GaloreSavedUnread
syntax match GaloreSavedUnread "(\d*)"				contained nextgroup=GaloreSavedName
syntax match GaloreSavedName "\s\+.*\s"				contained nextgroup=GaloreSavedSearch
syntax match  GaloreSavedSearch    "([^()]\+)"

highlight link GaloreSavedCount     Statement
highlight GaloreSavedUnread		ctermfg=224 guifg=#9c453e
highlight link GaloreSavedName      Type
highlight link GaloreSavedSearch    String

" highlight CursorLine term=reverse cterm=reverse gui=reverse

