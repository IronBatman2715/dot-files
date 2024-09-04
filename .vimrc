" A mix of settings with some edits from me.
" I do not use Vim for much outside of server maintenance, so no plugins.
"
" Notable portions from:
" - https://github.com/brandon-wallace/vimrc
" - https://github.com/jyalim/myconfig

" INIT ---------------------------------------------------------------- {{{

" Disable compatibility with vi as this can cause issues.
set nocompatible

" Enable type file detection
filetype on

" Load an indent file to the detached file type
filetype indent on

" Turn syntax highlighting on
syntax on

" Show line numbers
set number

" Highlight cursor position
set cursorline
"set cursorcolumn

" Auto wrap lines
set whichwrap+=<,>,h,l,[,]

" Do NOT wrap lines to fit editor window
set nowrap

" Show partial command you typed on last line
set showcmd

" Show current mode on last line
set showmode

" }}}

" WHITESPACES --------------------------------------------------------------- {{{

" Set auto-indent
set autoindent

" Handle tabs according to `:help tabstop`
set tabstop=8 
set softtabstop=4
set shiftwidth=4
set noexpandtab

" Shows tabs and leading/trailing spaces
" toggle with `:set list` and `:set nolist`
set list
set listchars=tab:>-,lead:_,trail:_
highlight SpecialKey ctermfg=DarkGray

" }}}

" STATE MANAGEMENT ------------------------------------------------------------- {{{

" Set the number of lines to save in history.
set history=1000

" TODO: `mkdir` calls seem to fill stdout after first run on new install

" Set a central location for temporary (swp) files.
if isdirectory($HOME . '/.vim/tmp') == 0
    :silent !mkdir -m 700 -p ~/.vim/tmp > /dev/null 2>&1
endif
set directory=~/.vim/tmp ",~/.local/tmp/vim,/var/tmp,/tmp,

" Set a directory to save file backups.
if isdirectory($HOME . '/.vim/backup') == 0
    :silent !mkdir -m 700 -p ~/.vim/backup > /dev/null 2>&1
endif
set backupdir=~/.vim/backup
set backup

" Set a directory to save undo data.
if exists("+undofile")
    " feature only present in 7.3+

    if isdirectory( $HOME . '/.vim/undo' ) == 0
        :silent !mkdir -m 700 -p ~/.vim/undo > /dev/null 2>&1
    endif

    set undodir=~/.vim/undo
    set undofile
endif

" Re-read file if it is changed external to Vim AND there are not changes in the buffer.
set autoread

" Switch to another buffer without saving.
"set hidden

" }}}

" SEARCH --------------------------------------------------------------- {{{

" Ignore capital letters in search
set ignorecase

" Override ignorecase option if searching for capital letters
set smartcase

" Show matching words during search
set showmatch

" Use highlighting during search
set hlsearch

" }}}

" COMPLETION (wildmenu) ------------------------------------------------- {{{

" Enable auto-completion menu after pressing TAB
set wildmenu

" Make wildmenu behave like Bash completion
set wildmode=list:longest

" Ignore common file types that will never be edited with Vim
set wildignore=*.docx,*.jpg,*.png,*.gif,*.pdf,*.pyc,*.exe,*.flv,*.img,*.xlsx

" }}}

" VIMSCRIPT ------------------------------------------------------------- {{{

" Enable the marker method of folding.
" `zo` to open a single fold under the cursor
" `zc` to close the fold under the cursor
" `zR` to open all folds
" `zM` to close all folds
augroup filetype_vim
    autocmd!
    autocmd FileType vim setlocal foldmethod=marker
augroup END

" }}}

" STATUS LINE ------------------------------------------------------------- {{{

" Clear status line when vimrc is reloaded.
set statusline=

" Show full path to the file.
set statusline+=\ %F

" Display modified flag for unsaved files.
set statusline+=\ %m

" Display the file type.
set statusline+=\ %Y

" Display if a file is read only.
set statusline+=\ %R

" Split the left side from the right side.
set statusline+=%=

" Display the ascii code of the character under cursor.
set statusline+=\ ascii:\ %b

" Display the hex code of the character under cursor.
set statusline+=\ hex:\ 0x%B

" Show the line number the cursor is on.
set statusline+=\ ln:\ %l

" Show the column number the cursor is on.
set statusline+=\ col:\ %c

" Show the total number of lines in the file.
set statusline+=\ lc:\ %L

" Show the percentage of cursor is currently out of lines in file. 
set statusline+=\ percent:\ %p%%

" Add a space character.
set statusline+=\ 

" Show the status on the second to last line.
set laststatus=2

" }}}
