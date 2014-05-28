"vimrc
"Logs :
"==============================================================================
"update 2012.03.25
"2013.08.15
"   - change comments to english
"   - update OS type check
"   - meger with .vimrc
"2014.05.28
"   - change NERDTree to NERDTreeToggle   
"==============================================================================

"Not compatible with vi
set nocompatible

"Get OS type
if has('win32') || has('win64')
    let os = "Windows"
    behave mswin                "For windows user
    source $VIMRUNTIME/vimrc.vim
    source $VIMRUNTIME/mswin.vim
    source c:/vim/vim_func.vim      "extend function defined
elseif has('unix')
    let os = "Linux"
    if v:lang =~ "utf8$" || v:lang =~ "UTF-8$" "set encoding
        set fileencodings=utf-8,latin1,gbk,ucs-bom,cp936
        let &termencoding=&encoding
    endif
endif


"==============================================================================
set shortmess=atl   "not show the info about shortmess children

colorscheme elflord "pablo

syntax on           "syntax highlight
set mousehide       "hide mouse
set guioptions-=m   "no gui menu
set guioptions-=T
set guifont=Courier_New:h12:cANSI   "set guifont under windows
set guicursor=a:blinkon1000,a:blinkoff1000  "set cursor blink
set novisualbell                    "beep, not flash the screen
"set visualbell                     "flash the screen instead of beep

if os == "Windows"
    set lines=12        "set window size
    set columns=150
endif

set laststatus=2    "set command bar with 2 lines

set nobackup        "no backup files

set tabstop=4       "set tab space
set sw=4            "set auto index space
set et              "expand tab, use space to replace tab

set number          "show line number
set showcmd         "show current execute command
"set smartindent
set showmatch       "show match parenthese
set incsearch       "show match when input search string

"C-V - row select; under windows is C-Q

2match Error /\%80c/    "set a 'line limit' for line, max 80

if has("autocmd")
    "detect file type
    filetype on
    filetype plugin on
    filetype indent on

    augroup vimrcEx
    au!
    autocmd FileType text setlocal textwidth=78 "set textwidth to 78 character
    autocmd BufRead *.txt set tw=78
    autocmd BufReadPost *                       "when edit a file, jump to the last cursor position
    \ if line("'\"") > 0 && line ("'\"") <= line("$") |
    \   exe "normal! g'\"" |
    \endif
endif

set iskeyword+=_,$,@,%,#,-      "not split the word when the word contain these character

if version >= 500               "validate vim or vi
    "set foldmethod=syntax      "set the fold according to syntax
    "set foldnestmax=2          "set the max fold deepth
    set foldmethod=marker
    set fmr=/*,*/
    set autochdir               "switch vim path to current path
endif

"==============================================================================
au BufRead,BufNewFile *.viki set ft=viki

"AutoCommand
"insert the file header when create new .viki file
autocmd BufNewFile *.viki exec ":call SetViKiTitle()"
"insert the file header when create new .c file - NOT work?
autocmd BufNewFile *.c exec ":call SetCTitle()"
"goto the end of the file when create the new file
autocmd BufNewFile * normal G

"==============================================================================
set tags=tags;

if os == "Windows"      "set the location of the executable ctags file
    let Tlist_Ctags_Cmd = 'ctags'   "windows need to set the PATH to contain the ctags
elseif os == "Linux"
    let Tlist_Ctags_Cmd = '/usr/bin/ctags'
endif

let Tlist_Show_One_File = 1     "only show the current file's tag
let Tlist_Exit_OnlyWindow = 1   "exit the vim if the taglist window is the last one
"let Tlist_Use_Right_Window = 1  "show the taglist window on right side
"let Tlist_Auto_Open=1           "Open taglist windows when start
let Tlist_GainFocus_On_ToggleOpen=1 "set the focal point in the taglist window

set cscopequickfix=s-,c-,d-,i-,t-,e-
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

"cd c:\code\webos
"cs add cscope.out .
"==============================================================================
map <F2> :!ctags -R<CR>
"map <F3> :!cscope<CR>
map <F4> :cw<CR>
map <F5> :Tlist<CR>
map <F6> :NERDTreeToggle<CR>
if os == "Linux"
"    map <F7> :cs add /vobs/webos/src/cscope.out /vobs/webos/src/<CR>
endif
map <F8> :DiffOrig<CR>
map <F10>:set ff=unix<CR>

set pastetoggle=<C-P> " Ctrl-P toggles paste mode
nnoremap <C-N> :set nonumber!<CR> "Ctrl-N toggles numbering line
"cd c:\code\webos
"==============================================================================
""""""""""""""""""""""""""""""
" BufExplorer
"""""""""""""""""""""""""""""""
let g:bufExplorerDefaultHelp=0       " Do not show default help.
let g:bufExplorerShowRelativePath=1  " Show relative paths.
let g:bufExplorerSortBy="mru"        " Sort by most recently used.
let g:bufExplorerSplitRight=0        " Split left.
let g:bufExplorerSplitVertical=1     " Split vertically.
let g:bufExplorerSplitVertSize = 30  " Split width
let g:bufExplorerUseCurrentWindow=1  " Open in new window.

"==============================================================================
"Linux has standard diff, no need to set the diffexpr
if os == "Windows"
    set diffexpr=MyDiff()
elseif os == "Linux"
    set diffexpr=
endif

function MyDiff()
    let opt = '-a --binary '
    if &diffopt =~ 'icase' | let opt = opt . '-i ' | endif
    if &diffopt =~ 'iwhite' | let opt = opt . '-b ' | endif
    let arg1 = v:fname_in
    if arg1 =~ ' ' | let arg1 = '"' . arg1 . '"' | endif
    let arg2 = v:fname_new
    if arg2 =~ ' ' | let arg2 = '"' . arg2 . '"' | endif
    let arg3 = v:fname_out
    if arg3 =~ ' ' | let arg3 = '"' . arg3 . '"' | endif
    let eq = ''
    if $VIMRUNTIME =~ ' '
        if &sh =~ '\<cmd'
            let cmd = '""' . $VIMRUNTIME . '\diff"'
            let eq = '"'
        else
            let cmd = substitute($VIMRUNTIME, ' ', '" ', '') . '\diff"'
        endif
    else
        let cmd = $VIMRUNTIME . '\diff'
    endif
    silent execute '!' . cmd . ' ' . opt . arg1 . ' ' . arg2 . ' > ' . arg3 . eq
endfunction
