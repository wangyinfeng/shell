"define viki SetTitle
func! SetViKiTitle()

call setline(1, "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%")
call append(line("."), "#TITLE:")
call append(line(".")+1, "#DOC fmt=html:css=zb.css")
call append(line(".")+2, "#DATE: today")
call append(line(".")+3, "#AU:henry")
call append(line(".")+4, "#MAKETITLE")
call append(line(".")+5, "%#LIST:toc")
call append(line(".")+6, "%#OPT:plain! nolist!")
call append(line(".")+7, "%#IMG: IMGFILE")
call append(line(".")+8, "%{img w=  h=  :  }")
call append(line(".")+9, "%#Verbatim<<ppp")
call append(line(".")+10,"%")
call append(line(".")+11,"%ppp")
call append(line(".")+12,"")
endfunc

"define C SetTitle
func! SetCTitle()
call setline(1, "/*====================================================================")
call append(line("."), " *Description:")
call append(line(".")+1, " *DATE:")
call append(line(".")+2, " *Modify:")
call append(line(".")+3, " *")
call append(line(".")+4, "===================================================================*/")
call append(line(".")+5, "")
endfunc

"define comment insert in C
func! InsertComment()
call setline(line("."),"/*  */")
endfunc

func! CompileRunGcc()
exec "w"
exec "!gcc % -o %<"
exec "! ./%<"
endfunc
