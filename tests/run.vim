" exrc.vim - Secure exrc reimplementation
" License: UNLICENSE <https://www.unlicense.org>
" Website: https://github.com/ii14/exrc.vim

if !exists('$EXRC_RUNTIME')
  let $EXRC_RUNTIME = expand('<sfile>:p:h:h')
endif
if !exists('$EXRC_LOG_FILE')
  let $EXRC_LOG_FILE = 'test.log'
endif

let g:RC_FILE     = getcwd().'/.exrc'
let g:RC_LUA_FILE = getcwd().'/.exrc.lua'
let g:CACHE_FILE  = getcwd().'/exrc_cache'

let s:tmp_files = [g:RC_FILE, g:RC_LUA_FILE, g:CACHE_FILE]
let s:ok = v:true


fun! Abort(...) abort
  if a:0
    try
      let l:msg = a:0 == 1 ? a:1 : call('printf', a:000)
    catch
      let l:msg = printf(
        \ 'Abort() printf error: %s (in %s)',
        \ v:exception, v:throwpoint)
    endtry
  else
    let l:msg = 'Aborted'
  endif
  throw l:msg
endfun

com! -bar -nargs=+ Assert
  \ call Assert(<q-args>, expand('<sfile>:.'), expand('<slnum>'))
fun! Assert(expr, file, lnum) abort
  try
    if eval(a:expr)
      echomsg printf(
        \ '%s:%s: OK: %s',
        \ a:file, a:lnum, a:expr)
      return
    endif
  catch
    call Abort(
      \ '%s:%s: UNCAUGHT EXCEPTION: %s (in %s)',
      \ a:file, a:lnum, v:exception, v:throwpoint)
  endtry
  call Abort(
    \ '%s:%s: ASSERTION FAILED: %s',
    \ a:file, a:lnum, a:expr)
endfun


redir! > $EXRC_LOG_FILE
  if exists('$EXRC_CI')
    echomsg strftime('%Y-%m-%d %H:%M:%S')
    echomsg '$EXRC_RUNTIME  = '.string($EXRC_RUNTIME)
    echomsg '$EXRC_LOG_FILE = '.string($EXRC_LOG_FILE)
    version
    echomsg repeat('-', 80)
  endif

  for file in s:tmp_files
    call delete(file)
  endfor

  try
    source $EXRC_RUNTIME/tests/test.vim
  catch
    let s:ok = v:false
    echohl ErrorMsg
    echomsg v:exception
    echohl None
  endtry

  echomsg repeat('-', 80)
  if s:ok
    echohl Question
    echomsg 'TEST PASSED'
    echohl None
  else
    echohl ErrorMsg
    echomsg 'TEST FAILED'
    echohl None
  endif

  for file in s:tmp_files
    call delete(file)
  endfor
redir END

if exists('$EXRC_CI')
  if s:ok
    quit
  else
    cquit
  endif
endif
