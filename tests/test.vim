" exrc.vim - Secure exrc reimplementation
" License: UNLICENSE <https://www.unlicense.org>
" Website: https://github.com/ii14/exrc.vim

let g:exrc#names = ['.exrc', '.exrc.lua']
let g:exrc#cache_file = g:TMP.cache_file
source $EXRC_RUNTIME/autoload/exrc.vim

unlet! g:SOURCED

echomsg '; Should not source with clean cache file'
call writefile(['let g:SOURCED = 1'], g:TMP.rc_file)
call exrc#source()
Assert !exists('g:SOURCED')

echomsg '; Should source when trusting file'
call exrc#trust(g:TMP.rc_file)
Assert g:SOURCED == 1
unlet! g:SOURCED

echomsg '; Should source after file was trusted'
call exrc#source()
Assert g:SOURCED == 1
unlet! g:SOURCED

echomsg '; Should not source after file was changed'
call writefile(['let g:SOURCED = 2'], g:TMP.rc_file)
call exrc#source()
Assert !exists('g:SOURCED')

echomsg '; Should source after file was trusted'
call exrc#trust(g:TMP.rc_file)
Assert g:SOURCED == 2
unlet! g:SOURCED

echomsg '; Should not source after file was changed to previous version'
call writefile(['let g:SOURCED = 1'], g:TMP.rc_file)
Assert !exists('g:SOURCED')
call delete(g:TMP.rc_file)

if has('nvim-0.5.0')
  echomsg '; Should source lua files'
  call writefile(['vim.g.SOURCED = 3'], g:TMP.rc_lua_file)
  call exrc#trust(g:TMP.rc_lua_file)
  Assert g:SOURCED == 3
  unlet! g:SOURCED
  call delete(g:TMP.rc_lua_file)
else
  echomsg 'No nvim-0.5.0, skipping lua tests'
endif
