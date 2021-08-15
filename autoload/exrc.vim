" exrc.vim - Secure exrc reimplementation
" License: UNLICENSE <https://www.unlicense.org>
" Website: https://github.com/ii14/exrc.vim

fun! s:HashFunc(fname)
  return sha256(join(readfile(a:fname, 'b'), "\n"))
endfun

let s:names       = get(g:, 'exrc#names', ['.exrc', '.exrc.local', '.vimrc.local'])
let s:hash_func   = get(g:, 'exrc#hash_func', 's:HashFunc')
let s:cache_file  = get(g:, 'exrc#cache_file',
                  \ (exists('*stdpath') ? stdpath('cache') : $HOME) . '/.exrc_cache')

if type(s:names) == v:t_string
  let s:names = [s:names]
elseif type(s:names) != v:t_list
  throw 'g:exrc#names is not a list'
elseif len(s:names) < 1
  throw 'g:exrc#names should contain at least one element'
endif

for name in s:names
  if type(name) != v:t_string
    throw 'g:exrc#names should only contain strings'
  endif
endfor

if &exrc
  for pat in ['.vimrc', '.exrc', '.gvimrc']
    if index(s:names, pat) != -1
      throw "Collision with native 'exrc' option. " .
        \ "Set 'noexrc' or set a custom filename in g:exrc#names"
    endif
  endfor
endif

try
  call function(s:hash_func)
catch /E700/
  throw 'g:exrc#hash_func is not a function'
endtry

fun! s:Error(...)
  echohl ErrorMsg
  echomsg 'exrc.vim: '.(a:0 == 1 ? a:1 : call('printf', a:000))
  echohl None
endfun

fun! s:Warn(...)
  echohl WarningMsg
  echomsg 'exrc.vim: '.(a:0 == 1 ? a:1 : call('printf', a:000))
  echohl None
endfun

" Generate checksum for file
fun! s:Checksum(fname) abort
  let path = fnamemodify(a:fname, ':p')
  let hash = split(call(function(s:hash_func), [path]), '\s')
  if len(hash) < 1 || len(hash[0]) < 16
    throw 'Invalid hash'
  endif
  return [hash[0], path]
endfun

" Convert list of lines to a list of [hash, path]
fun! s:Parse(lines) abort
  let res = []
  for line in a:lines
    let idx = match(line, ' ')
    if idx > 0 && idx + 1 < len(line)
      call add(res, [line[:idx-1], line[idx+1:]])
    endif
  endfor
  return res
endfun

" Convert list of [hash, path] to a list of lines
fun! s:Serialize(list) abort
  return map(a:list, 'v:val[0] . " " . v:val[1]')
endfun

" Read lines from the cache file
fun! s:Read() abort
  return filereadable(s:cache_file) ? readfile(s:cache_file) : []
endfun

" Check if file is on the trusted files list
fun! s:Check(fname) abort
  let hash = s:Checksum(a:fname)
  return index(s:Read(), hash[0] . ' ' . hash[1]) != -1
endfun

" Clean list from files that no longer exist or match the function arguments
fun! s:Clean(list, ...) abort
  return filter(a:list, 'filereadable(v:val[1]) && index(a:000, v:val[1]) == -1')
endfun

" Edit local config file
fun! exrc#edit() abort
  for name in s:names
    if filereadable(name)
      execute 'edit ' . fnameescape(name)
      return
    endif
  endfor
  execute 'edit ' . fnameescape(s:names[0])
endfun

" Add file to trusted files
fun! exrc#trust(fname) abort
  if !filereadable(a:fname)
    call s:Error(
      \ 'File does not exist')
    return
  endif

  " validate filename
  let tail = fnamemodify(a:fname, ':t')
  if index(s:names, tail) == -1
    call s:Error(
      \ 'Invalid filename "%s". Run :ExrcEdit to edit the config or add the filename to g:exrc#names',
      \ tail)
    return
  endif

  " add the config file to trusted files
  let full = fnamemodify(a:fname, ':p')
  let hash = s:Checksum(full)
  let hashes = s:Parse(s:Read())
  call s:Clean(hashes, hash[1])
  call add(hashes, hash)
  call writefile(s:Serialize(hashes), s:cache_file)

  " source the config if in current working directory
  if fnamemodify(full, ':h') ==# getcwd()
    call exrc#source()
  endif
endfun

" Find and source local config file
fun! exrc#source() abort
  let found = v:false
  for name in s:names
    if filereadable(name)
      if s:Check(name)
        execute (match(name, '\c\V.lua\$') == -1 ? 'source ' : 'luafile ').fnameescape(name)
        return
      endif
      let found = v:true
    endif
  endfor
  if found
    call s:Warn('Unknown config found. Run :ExrcEdit and :ExrcTrust to add config to the trusted files')
  endif
endfun

" vim: et sw=2 sts=2
