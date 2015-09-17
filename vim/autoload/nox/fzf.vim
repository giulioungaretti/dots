" autoload/nox/fzf.vim - Sources and sinks for fzf
" Maintainer:   Noah Frederick
"
" Portions adapted from fzf.vim:
" https://github.com/junegunn/fzf.vim
"
" ------------------------------------------------------------------
" Common
" ------------------------------------------------------------------
function! s:strip(str)
  return substitute(a:str, '^\s*\|\s*$', '', 'g')
endfunction

function! s:escape(path)
  return escape(a:path, ' %#''"\')
endfunction

function! s:ansi(str, color, bold)
  return printf("\x1b[%s%sm%s\x1b[m", a:color, a:bold ? ';1' : '', a:str)
endfunction

for [s:c, s:a] in items({'black': 30, 'red': 31, 'green': 32, 'yellow': 33, 'blue': 34, 'magenta': 35})
  execute "function! s:".s:c."(str, ...)\n"
        \ "  return s:ansi(a:str, ".s:a.", get(a:, 1, 0))\n"
        \ "endfunction"
endfor

function! s:buflisted()
  return filter(range(1, bufnr('$')), 'buflisted(v:val)')
endfunction

function! s:fzf(opts, bang)
  return fzf#run(extend(a:opts, a:bang ? {} : {'down': 20}))
endfunction

let s:default_action = {
      \ 'ctrl-t': 'tab split',
      \ 'ctrl-x': 'split',
      \ 'ctrl-v': 'vsplit'
      \ }

function! s:expect()
  return ' --expect='.join(keys(s:default_action), ',')
endfunction

function! s:common_sink(lines) abort
  if len(a:lines) < 2
    return
  endif
  let key = remove(a:lines, 0)
  let cmd = get(s:default_action, key, 'edit')
  try
    let autochdir = &autochdir
    set noautochdir
    for item in a:lines
      execute cmd s:escape(item)
    endfor
  finally
    let &autochdir = autochdir
  endtry
endfunction

" ------------------------------------------------------------------
" Buffers
" ------------------------------------------------------------------
function! s:bufopen(lines)
  if len(a:lines) < 2
    return
  endif

  let actions = copy(s:default_action)
  let actions['ctrl-d'] = 'bwipeout'
  let cmd = get(actions, remove(a:lines, 0), '')
  let bufs = map(copy(a:lines), 'matchstr(v:val, "\\[*\\zs[0-9]*\\ze\\]")')

  if cmd ==# 'bwipeout'
    execute cmd join(bufs)
    return
  endif

  for buf in bufs
    if !empty(cmd)
      execute 'silent' cmd
    endif
    execute 'buffer' buf
  endfor
endfunction

function! s:format_buffer(b)
  let name = bufname(a:b)
  let name = empty(name) ? '[No Name]' : name
  let flag = a:b == bufnr('') ? s:blue('%') :
        \ (a:b == bufnr('#') ? s:magenta('#') : ' ')
  let modified = getbufvar(a:b, '&modified') ? s:red(" \u25cf") : ''
  let readonly = getbufvar(a:b, '&modifiable') ? '' : s:blue(" \u25cb")
  let extra = join(filter([modified, readonly], '!empty(v:val)'), '')
  return s:strip(printf("[%s] %s\t%s\t%s", s:blue(a:b), flag, name, extra))
endfunction

function! nox#fzf#Buffers(bang)
  let bufs = s:buflisted()

  " Remove current and alternate buffers from list
  call filter(bufs, "v:val != bufnr('#') && v:val != bufnr('%')")

  if bufnr('#') > 0
    call add(bufs, bufnr('#'))
  endif

  let height = min([len(bufs), &lines * 4 / 10]) + 1

  call map(bufs, 's:format_buffer(v:val)')

  call fzf#run(extend({
        \   'source':  reverse(bufs),
        \   'sink*':   function('s:bufopen'),
        \   'options': '--prompt "Buffers > " -m -x --reverse --ansi -d "\t" -n 2,1..2'.s:expect().',ctrl-d',
        \ }, a:bang ? {} : {'down': height}))
endfunction

" ------------------------------------------------------------------
" History
" ------------------------------------------------------------------
function! s:all_files()
  return extend(
        \ filter(reverse(copy(v:oldfiles)),
        \        "v:val !~ 'fugitive:\\|NERD_tree\\|^/tmp/\\|.git/'"),
        \ filter(map(s:buflisted(), 'bufname(v:val)'), '!empty(v:val)'))
endfunction

function! nox#fzf#History(bang)
  call s:fzf({
        \   'source':  reverse(s:all_files()),
        \   'sink*':   function('<SID>common_sink'),
        \   'options': '--prompt "History > " -m' . s:expect(),
        \ }, a:bang)
endfunction

" ------------------------------------------------------------------
" Tags
" ------------------------------------------------------------------
function! s:tags_sink(lines)
  if len(a:lines) < 2
    return
  endif

  let cmd = get(s:default_action, a:lines[0], 'edit')
  let parts = split(a:lines[1], '\t\zs')
  let excmd = matchstr(parts[2:], '^.*\ze;"\t')
  execute 'silent' cmd s:escape(parts[1][:-2])
  let [magic, &magic] = [&magic, 0]
  execute excmd
  let &magic = magic
endfunction

function! nox#fzf#Tags(bang)
  if empty(tagfiles())
    echohl WarningMsg
    echom 'Preparing tags'
    echohl None
    call system('ctags -R --languages=-javascript,sql')
  endif

  call s:fzf({
        \ 'source':  'cat '.join(map(tagfiles(), 'fnamemodify(v:val, ":S")')).
        \            '| grep -v "^!"',
        \ 'options': '+m -d "\t" --with-nth 1,4.. -n 1 --prompt "Tags > "'.s:expect(),
        \ 'sink*':   function('s:tags_sink')}, a:bang)
endfunction

" ------------------------------------------------------------------
" Lines
" ------------------------------------------------------------------
function! s:line_handler(lines)
  if len(a:lines) < 2
    return
  endif
  let cmd = get(s:default_action, a:lines[0], '')
  if !empty(cmd)
    execute 'silent' cmd
  endif

  let keys = split(a:lines[1], '\t')
  execute 'buffer' keys[0][1:-2]
  execute keys[1][0:-2]
  normal! ^zz
endfunction

function! s:lines()
  let cur = []
  let rest = []
  let buf = bufnr('')
  for b in s:buflisted()
    call extend(b == buf ? cur : rest,
          \ map(getbufline(b, 1, "$"),
          \ 'printf("[%s]\t%s:\t%s", s:blue(b), s:yellow(v:key + 1), v:val)'))
  endfor
  return extend(cur, rest)
endfunction

function! nox#fzf#Lines(bang)
  call s:fzf({
        \ 'source':  <SID>lines(),
        \ 'sink*':   function('<SID>line_handler'),
        \ 'options': '+m --tiebreak=index --prompt "Lines > " --ansi --extended --nth=3..'.s:expect()
        \}, a:bang)
endfunction

" ------------------------------------------------------------------
" BLines
" ------------------------------------------------------------------
function! s:buffer_line_handler(lines)
  if len(a:lines) < 2
    return
  endif
  let cmd = get(s:default_action, a:lines[0], '')
  if !empty(cmd)
    execute 'silent' cmd
  endif

  execute split(a:lines[1], '\t')[0][0:-2]
  normal! ^zz
endfunction

function! s:buffer_lines()
  return map(getline(1, "$"),
        \ 'printf("%s:\t%s", s:yellow(v:key + 1), v:val)')
endfunction

function! nox#fzf#BLines(bang)
  call s:fzf({
        \ 'source':  <SID>buffer_lines(),
        \ 'sink*':   function('<SID>buffer_line_handler'),
        \ 'options': '+m --tiebreak=index --prompt "BLines > " --ansi --extended --nth=2..'.s:expect()
        \}, a:bang)
endfunction

" ------------------------------------------------------------------
" Marks
" ------------------------------------------------------------------
function! s:format_mark(line)
  return substitute(a:line, '\S', '\=s:yellow(submatch(0))', '')
endfunction

function! s:mark_sink(lines)
  if len(a:lines) < 2
    return
  endif
  let cmd = get(s:default_action, a:lines[0], '')
  if !empty(cmd)
    execute 'silent' cmd
  endif
  execute 'normal! `'.matchstr(a:lines[1], '\S').'zz'
endfunction

function! nox#fzf#Marks(bang)
  redir => cout
  silent marks
  redir END
  let list = split(cout, "\n")
  call s:fzf({
        \ 'source':  extend(list[0:0], map(list[1:], 's:format_mark(v:val)')),
        \ 'sink*':   function('s:mark_sink'),
        \ 'options': '+m -x --ansi --tiebreak=index --header-lines 1 --tiebreak=begin --prompt "Marks > "'.s:expect()}, a:bang)
endfunction

" vim:set et sw=2:
