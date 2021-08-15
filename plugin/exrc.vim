" exrc.vim - Secure exrc reimplementation
" License: UNLICENSE <https://www.unlicense.org>
" Website: https://github.com/ii14/exrc.vim

if exists('g:loaded_exrc')
  finish
endif
let g:loaded_exrc = 1

command! -bar -nargs=? -complete=file ExrcTrust
  \ call exrc#trust(expand(<q-args> ==# '' ? '%' : <q-args>))
command! -bar ExrcEdit call exrc#edit()
command! -bar ExrcSource call exrc#source()

augroup ExrcPlugin
  autocmd!
  if exists('##DirChanged')
    autocmd DirChanged * if v:event.scope ==# 'global' | call exrc#source() | endif
  endif
  if v:vim_did_enter
    call exrc#source()
  else
    autocmd VimEnter * call exrc#source()
  endif
augroup END

" vim: et sw=2 sts=2
