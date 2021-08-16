" exrc.vim - Secure exrc reimplementation
" License: UNLICENSE <https://www.unlicense.org>
" Website: https://github.com/ii14/exrc.vim

if exists('g:loaded_exrc')
  finish
endif
let g:loaded_exrc = 1

function! s:Source(mods) abort
  let mods = split(a:mods, ' ')
  let silent = index(mods, 'silent') != -1 || index(mods, 'silent!') != -1
  let candidate = exrc#source()
  if !silent && candidate !=# ''
    if index(mods, 'confirm') == -1
      echohl WarningMsg
      echomsg 'Unknown config found. Run :ExrcEdit and :ExrcTrust to add config to the trusted files'
      echohl None
    else
      let candidate = fnamemodify(candidate, ':p')
      let choice = confirm(
        \ 'exrc.vim: Unknown config found: '.candidate,
        \ "&ignore\n&edit\n&blacklist\n&trust", 1)
      if choice == 2
        execute 'edit '.candidate
      elseif choice == 3
        call exrc#blacklist(candidate)
      elseif choice == 4
        call exrc#trust(candidate, 1)
      endif
    endif
  endif
endfunction

command! -bar -bang -nargs=? -complete=file ExrcTrust
  \ call exrc#trust(expand(<q-args> ==# '' ? '%' : <q-args>), <bang>0)

command! -bar ExrcEdit call exrc#edit()

command! -bar ExrcSource call s:Source(<q-mods>)

augroup ExrcPlugin
  autocmd!
  if exists('##DirChanged')
    autocmd DirChanged * nested if v:event.scope ==# 'global' | confirm ExrcSource | endif
  endif
  if v:vim_did_enter
    confirm ExrcSource
  else
    autocmd VimEnter * nested confirm ExrcSource
  endif
augroup END

" vim: et sw=2 sts=2
