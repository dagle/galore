syntax region nmSaved start=/^/ end=/$/					oneline contains=nmSavedCount

syntax match nmSavedCount "\d*"				contained nextgroup=nmSavedName	
syntax match nmSavedName "\s\+.*\s"				contained nextgroup=nmSavedSearch
syntax match  nmSavedSearch    "([^()]\+)"

highlight link nmSavedCount     Statement
highlight link nmSavedName      Type
highlight link nmSavedSearch    String

" highlight CursorLine term=reverse cterm=reverse gui=reverse

