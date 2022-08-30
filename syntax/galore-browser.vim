setlocal conceallevel=3
setlocal concealcursor=nciv

" init should set this value
let GaloreFromLength = 10 
" let GaloreFromStr = "syntax match GaloreFrom		'\s\+[^│]\{0,5}'						contained nextgroup=GaloreFromConc"

" Use this for now, I kinda want it to be order indpendent
" Could I make the order generated and loaded on init?
" conceal
syntax region GaloreThreads		start=/^/ end=/$/					oneline contains=GaloreDate
syntax match GaloreDate		"[0-9A-Za-z.\-]\+\(\s[a-z0-9:.]\+\)\?\(\sago\)\?"	contained nextgroup=GaloreThreadCount
syntax match GaloreThreadCount	"\s\+\[[0-9]\+\/[0-9()]\+\]"				contained nextgroup=GaloreFrom
syntax match GaloreFrom		'\s\+[^│]\{0,25}'						contained nextgroup=GaloreFromConc
" execute GaloreFromStr
syntax match GaloreFromConc		"[^│]*"						        contained nextgroup=GaloreFromEnd conceal
syntax match GaloreFromEnd		"│"						        contained nextgroup=GaloreSubject
syntax match GaloreSubject		/.\{0,}\(([^()]\+)$\)\@=/				contained nextgroup=GaloreTags
syntax match GaloreTags		"(.*)$"							contained

highlight GaloreFrom		ctermfg=224 guifg=Orange
highlight GaloreFromConc	ctermfg=224 guifg=Green
highlight GaloreFromEnd		ctermfg=224 guifg=Red
highlight link GaloreDate		String
highlight link GaloreThreadCount	Comment
highlight link GaloreSubject	Statement
highlight link GaloreTags		Comment
