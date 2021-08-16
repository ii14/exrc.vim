" exrc.vim - Secure exrc reimplementation
" License: UNLICENSE <https://www.unlicense.org>
" Website: https://github.com/ii14/exrc.vim

echomsg ':: Test API'

let g:exrc#names = ['_exrc.vim', '_exrc2.vim', '_exrc 3.vim', '_exrc.lua']
let g:exrc#cache_file = g:TMP.cache_file
source $EXRC_RUNTIME/autoload/exrc.vim

unlet! g:SOURCED

echomsg 'Should not source with clean cache file'
  call writefile(['let g:SOURCED = 1'], g:TMP.rc_file)
  Assert exrc#source() == '_exrc.vim'
  Assert !exists('g:SOURCED')

echomsg 'Should source when trusting file'
  call exrc#trust(g:TMP.rc_file, 0)
  Assert g:SOURCED == 1
  unlet! g:SOURCED

echomsg 'Should source after file was trusted'
  Assert exrc#source() == ''
  Assert g:SOURCED == 1
  unlet! g:SOURCED

echomsg 'Should not source after file was changed'
  call writefile(['let g:SOURCED = 2'], g:TMP.rc_file)
  Assert exrc#source() == '_exrc.vim'
  Assert !exists('g:SOURCED')

echomsg 'Should source after file was trusted'
  call exrc#trust(g:TMP.rc_file, 0)
  Assert g:SOURCED == 2
  unlet! g:SOURCED

echomsg 'Should not source after file was changed to previous version'
  call writefile(['let g:SOURCED = 1'], g:TMP.rc_file)
  Assert exrc#source() == '_exrc.vim'
  Assert !exists('g:SOURCED')
  call delete(g:TMP.rc_file)

if has('nvim-0.5')
  echomsg 'Should source lua files'
    call writefile(['vim.g.SOURCED = 3'], g:TMP.rc_lua_file)
    call exrc#trust(g:TMP.rc_lua_file, 0)
    Assert g:SOURCED == 3
    unlet! g:SOURCED
    call delete(g:TMP.rc_lua_file)
else
  echomsg 'No nvim-0.5, skipping lua tests'
endif

echomsg 'Should not source blacklisted files'
  call writefile(['let g:SOURCED = 4'], g:TMP.rc_file)
  call exrc#blacklist(g:TMP.rc_file)
  Assert exrc#source() == ''
  Assert !exists('g:SOURCED')

echomsg 'Should not trust blacklisted files without force flag'
  call exrc#trust(g:TMP.rc_file, 0)
  Assert exrc#source() == ''
  Assert !exists('g:SOURCED')

echomsg 'Should trust blacklisted files with force flag'
  call exrc#trust(g:TMP.rc_file, 1)
  Assert g:SOURCED == 4
  unlet! g:SOURCED

echomsg 'Should not source blacklisted files that were previously trusted'
  call exrc#blacklist(g:TMP.rc_file)
  Assert exrc#source() == ''
  Assert !exists('g:SOURCED')

echomsg 'Should source second candidate if first candidate is blacklisted'
  call writefile(['let g:SOURCED = 5'], g:TMP.rc_file2)
  call exrc#trust(g:TMP.rc_file2, 0)
  Assert g:SOURCED == 5
  unlet! g:SOURCED
  call delete(g:TMP.rc_file)
  call delete(g:TMP.rc_file2)

echomsg 'Should trust and source files with spaces in their path'
  call writefile(['let g:SOURCED = 6'], g:TMP.rc_file3)
  call exrc#trust(g:TMP.rc_file3, 0)
  Assert g:SOURCED == 6
  unlet! g:SOURCED
  call delete(g:TMP.rc_file3)
