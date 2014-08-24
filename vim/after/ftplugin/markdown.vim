" Turn on concealing of bold, italic markers
set conceallevel=2
set concealcursor=nc

" Org-mode-like extensions to Markdown

if exists(':Switch')
  let b:switch_custom_definitions = [
    \   {
    \     '^\(\s*[-+\*]\) TODO \(.*\)': '\1 DONE \2',
    \     '^\(\s*[-+\*]\) DONE \(.*\)': '\1 WAITING \2',
    \     '^\(\s*[-+\*]\) WAITING \(.*\)': '\1 CANCELED \2',
    \     '^\(\s*[-+\*]\) CANCELED \(.*\)': '\1 \2',
    \     '^\(\s*[-+\*]\) \%(TODO\|DONE\|WAITING\|CANCELED\|\[[ x]\]\)\@!\(.*\)': '\1 TODO \2',
    \   },
    \   {
    \     '^\(\s*\)-- \(.*\)': '\1++ \2',
    \     '^\(\s*\)++ \(.*\)': '\1-- \2',
    \   },
    \   {
    \     '^\(\s*[-+\*]\) \[ \] \(.*\)': '\1 [x] \2',
    \     '^\(\s*[-+\*]\) \[x\] \(.*\)': '\1 [ ] \2',
    \   },
    \ ]

  nnoremap <buffer> <CR> :Switch<CR>
endif

" Smart <Enter> in insert mode
inoremap <buffer><expr> <CR> helper#markdown#OpenLine("\<CR>")

" Also for normal mode o/O
nnoremap <buffer><expr> o helper#markdown#OpenLine("o")
nnoremap <buffer><expr> O helper#markdown#OpenLine("O")

" Timestamp insertion
inoremap <buffer> <C-g>. [<C-r>=strftime("%Y-%m-%d %a")<CR>]
inoremap <buffer> <C-g>! [<C-r>=strftime("%Y-%m-%d %a %H:%M")<CR>]

" Promote/demote headings
nnoremap <buffer> <Left> :call helper#markdown#PromoteHeading()<CR>
nnoremap <buffer> <Right> :call helper#markdown#DemoteHeading()<CR>

" Follow link under cursor
nnoremap <buffer> gx :call helper#markdown#FollowLinkUnderCursor()<CR>

" Smart dashes
iabbrev <buffer><expr> --- helper#markdown#InsertDashes()

" Use pandoc to run off a PDF with :make
silent! compiler pandoc

" Recompile file on save if compiled version already exists
augroup AfterMarkdown
  autocmd!
  autocmd BufWritePost *.md call helper#make#Recompile(expand('<afile>'))
augroup END
