setlocal conceallevel=3
setlocal concealcursor=nciv

" Use this for now, I kinda want it to be order indpendent
" Could I make the order generated and loaded on init?
syntax region nmThreads		start=/^/ end=/$/					oneline contains=nmDate
syntax match nmDate		"[0-9A-Za-z.\-]\+\(\s[a-z0-9:.]\+\)\?\(\sago\)\?"	contained nextgroup=nmThreadCount
syntax match nmThreadCount	"\s\+\[[0-9]\+\/[0-9()]\+\]"				contained nextgroup=nmFrom
syntax match nmFrom		"\s\+.*;"						contained nextgroup=nmSubject
syntax match nmSubject		/.\{0,}\(([^()]\+)$\)\@=/				contained nextgroup=nmTags
syntax match nmTags		"(.*)$"							contained

highlight nmFrom		ctermfg=224 guifg=Orange gui=italic
highlight link nmDate		String
highlight link nmThreadCount	Comment
highlight link nmSubject	Statement
highlight link nmTags		Comment
