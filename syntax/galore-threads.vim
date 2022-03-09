setlocal conceallevel=3
setlocal concealcursor=nciv

" init should set this value
let nmFromLength = 10 
let nmFromStr = "syntax match nmFrom		'\s\+[^│]\{0,5}'						contained nextgroup=nmFromConc"

" Use this for now, I kinda want it to be order indpendent
" Could I make the order generated and loaded on init?
" conceal
syntax region nmThreads		start=/^/ end=/$/					oneline contains=nmDate
syntax match nmDate		"[0-9A-Za-z.\-]\+\(\s[a-z0-9:.]\+\)\?\(\sago\)\?"	contained nextgroup=nmThreadCount
syntax match nmThreadCount	"\s\+\[[0-9]\+\/[0-9()]\+\]"				contained nextgroup=nmFrom
syntax match nmFrom		'\s\+[^│]\{0,25}'						contained nextgroup=nmFromConc
" execute nmFromStr
syntax match nmFromConc		"[^│]*"						        contained nextgroup=nmFromEnd conceal
syntax match nmFromEnd		"│"						        contained nextgroup=nmSubject
syntax match nmSubject		/.\{0,}\(([^()]\+)$\)\@=/				contained nextgroup=nmTags
syntax match nmTags		"(.*)$"							contained

highlight nmFrom		ctermfg=224 guifg=Orange
highlight nmFromConc	ctermfg=224 guifg=Green
highlight nmFromEnd		ctermfg=224 guifg=Red
highlight link nmDate		String
highlight link nmThreadCount	Comment
highlight link nmSubject	Statement
highlight link nmTags		Comment
