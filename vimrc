set nocompatible

"set colorsheme
colorscheme delek

syntax on
set mousehide
"no gui menu
set guioptions-=m
set guioptions-=T
"no backup files
set nobackup
"set tab space
set tabstop=4
"set auto index space
set sw=4
"use space to replace tab
set et                      "set expandtab
set incsearch

set laststatus=2
"set guifont under windows
set guifont=Courier_New:h14:cANSI
"set window size
set lines=12
set columns=150
"set cursor blink
set guicursor=a:blinkon1000,a:blinkoff1000
"set a 'line' on line
2match Error /\%80c/
"detect file type
filetype on
filetype plugin on
filetype indent on

set iskeyword+=_,$,@,%,#,-

set shortmess=atl

set novisualbell
"show line number
set number
"hide line number
"set number!

"Not format the paste content
"set paste
"Auto format the paste content
"set nopaste

"set foldmethod=syntax
"set foldnestmax=2
if version >= 500
    set foldmethod=marker
    set fmr=/*,*/
    set autochdir           "switch vim path to current path
endif
"show current execute command
set showcmd
"show match parenthese
set showmatch
"ctags
set tags=tags;

"if MySys() == "windows"     
"    let Tlist_Ctags_Cmd = 'ctags'
"elseif MySys() == "linux"  
"    let Tlist_Ctags_Cmd = '/usr/bin/ctags'

let Tlist_Show_One_File = 1   
let Tlist_Exit_OnlyWindow = 1  
"let Tlist_Use_Right_Window = 1 
"let Tlist_Auto_Open=1          "Open taglist windows when start
let Tlist_GainFocus_On_ToggleOpen=1 

"cscope
set cscopequickfix=s-,c-,d-,i-,t-,e-

"if $BNTDEV == "leo.wang"
"cs add /vobs/webos/src/cscope.out /vobs/webos/src/ <CR>
"endif

set nocscopeverbose

if !exists(":DiffOrig")
    command DiffOrig vert new | set bt=nofile | r # | 0d_ | diffthis
          \ | wincmd p | diffthis
endif

nmap <C-_>s :cs find s <C-R>=expand("<cword>")<CR><CR>
nmap <C-_>g :cs find g <C-R>=expand("<cword>")<CR><CR>
nmap <C-_>c :cs find c <C-R>=expand("<cword>")<CR><CR>
nmap <C-_>t :cs find t <C-R>=expand("<cword>")<CR><CR>
nmap <C-_>e :cs find e <C-R>=expand("<cword>")<CR><CR>
nmap <C-_>f :cs find f <C-R>=expand("<cfile>")<CR><CR>
nmap <C-_>i :cs find i <C-R>=expand("<cfile>")<CR><CR>
nmap <C-_>d :cs find d <C-R>=expand("<cword>")<CR><CR>

func! CompileRunGcc()
exec "w"
exec "!gcc % -o %<"
exec "! ./%<"
endfunc

"key map
map <F2> :!ctags -R<CR>
map <F3> :!cscope<CR>
map <F4> :cw<CR>
map <F5> :Tlist<CR>
map <F6> :NERDTree<CR>
map <F7> :cs add /vobs/webos/src/cscope.out /vobs/webos/src/<CR>
map <F8> :DiffOrig<CR>

map <F10>:set ff=unix<CR>
