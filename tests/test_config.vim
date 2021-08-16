" exrc.vim - Secure exrc reimplementation
" License: UNLICENSE <https://www.unlicense.org>
" Website: https://github.com/ii14/exrc.vim

echomsg ':: Test Config'

fun! TrySource()
  try
    source $EXRC_RUNTIME/autoload/exrc.vim
  catch
    return v:exception
  endtry
  return ''
endfun

echomsg 'Should throw when g:exrc#names is a number'
  let g:exrc#names = 1
  Assert TrySource() =~# '^exrc.vim:'
  unlet! g:exrc#names

echomsg 'Should throw when g:exrc#names is an empty list'
  let g:exrc#names = []
  Assert TrySource() =~# '^exrc.vim:'
  unlet! g:exrc#names

echomsg 'Should throw when g:exrc#names list contains a number'
  let g:exrc#names = [1]
  Assert TrySource() =~# '^exrc.vim:'
  unlet! g:exrc#names

echomsg 'Should not throw when g:exrc#names is a string'
  let g:exrc#names = 'exrc.vim'
  Assert TrySource() ==# ''
  unlet! g:exrc#names

echomsg 'Should not throw when g:exrc#names is a list with one string'
  let g:exrc#names = ['exrc.vim']
  Assert TrySource() ==# ''
  unlet! g:exrc#names

echomsg 'Should not throw when g:exrc#names is a list with multiple strings'
  let g:exrc#names = ['exrc1.vim', 'exrc2.vim', 'exrc3.vim']
  Assert TrySource() ==# ''
  unlet! g:exrc#names

echomsg 'Should throw when &exrc option is set'
  set exrc
  let g:exrc#names = '.exrc'
  Assert TrySource() =~# '^exrc.vim:'
  unlet! g:exrc#names
  set noexrc

echomsg 'Should not throw when &exrc option is not set'
  let g:exrc#names = '.exrc'
  Assert TrySource() ==# ''
  unlet! g:exrc#names

echomsg 'Should throw when g:exrc#hash_func is not a function'
  let g:exrc#hash_func = 1
  Assert TrySource() =~# '^exrc.vim:'
  unlet! g:exrc#hash_func
