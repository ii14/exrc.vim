" exrc.vim - Secure exrc reimplementation
" License: UNLICENSE <https://www.unlicense.org>
" Website: https://github.com/ii14/exrc.vim

if !exists('$EXRC_RUNTIME')
  let $EXRC_RUNTIME = expand('<sfile>:p:h:h')
endif
if !exists('$EXRC_LOG_FILE')
  let $EXRC_LOG_FILE = 'test.log'
endif

let s:ok = v:true
let g:TMP = {
  \ 'rc_file'     : getcwd().'/_exrc.vim',
  \ 'rc_file2'    : getcwd().'/_exrc2.vim',
  \ 'rc_file3'    : getcwd().'/_exrc 3.vim',
  \ 'rc_lua_file' : getcwd().'/_exrc.lua',
  \ 'cache_file'  : getcwd().'/_exrc_cache',
  \ }


fun! Cleanup()
  for file in values(g:TMP)
    call delete(file)
  endfor
endfun

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
      if exists('$EXRC_VERBOSE')
        echomsg printf('%s:%s: OK: %s', a:file, a:lnum, a:expr)
      endif
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
    echomsg '* $EXRC_RUNTIME = '.string($EXRC_RUNTIME)
    echomsg '* $EXRC_LOG_FILE = '.string($EXRC_LOG_FILE)
    for key in sort(keys(g:TMP))
      echomsg '* g:TMP.'.key.' = '.string(g:TMP[key])
    endfor
    version
    echomsg repeat('-', 80)
  endif

  call Cleanup()
  try
    source $EXRC_RUNTIME/tests/test_config.vim
    call Cleanup()
    source $EXRC_RUNTIME/tests/test_api.vim
  catch
    let s:ok = v:false
    echohl ErrorMsg
    echomsg v:exception
    echohl None
  endtry
  call Cleanup()

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
redir END

if exists('$EXRC_CI')
  if s:ok
    quit
  else
    cquit
  endif
endif
