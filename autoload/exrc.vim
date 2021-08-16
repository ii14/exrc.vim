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
  if type(name) != v:t_string || name ==# ''
    throw 'g:exrc#names should only contain non-empty strings'
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
  " check for '!' is redundant, but it's better to be explicit that '!' is reserved
  if len(hash) < 1 || len(hash[0]) < 16 || hash[0] ==# '!'
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
  let [hash, file] = s:Checksum(a:fname)
  for [h, f] in s:Parse(s:Read())
    if f ==# file
      if h ==# '!'
        return -1
      elseif h ==# hash
        return 1
      endif
    endif
  endfor
  return 0
endfun

" Remove file from hash list. Also cleans up files that no longer exist
fun! s:Remove(list, fname) abort
  return filter(a:list, '(v:val[0] ==# "!" || filereadable(v:val[1])) && v:val[1] !=# a:fname')
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
fun! exrc#trust(fname, force) abort
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
  let hashes = s:Parse(s:Read())
  if !a:force
    for item in hashes
      if item[1] ==# full && item[0] ==# '!'
        call s:Error(
          \ 'File "%s" is blacklisted. Use :ExrcTrust! to force.',
          \ item[1])
        return
      endif
    endfor
  endif

  let hash = s:Checksum(full)
  call s:Remove(hashes, hash[1])
  call add(hashes, hash)
  call writefile(s:Serialize(hashes), s:cache_file)

  " source the config if in current working directory
  if fnamemodify(full, ':h') ==# getcwd()
    call exrc#source()
  endif
endfun

" Blacklist file
fun! exrc#blacklist(fname) abort
  let full = fnamemodify(a:fname, ':p')
  let hash = s:Checksum(full)
  let hashes = s:Parse(s:Read())
  call s:Remove(hashes, hash[1])
  call add(hashes, ['!', full])
  call writefile(s:Serialize(hashes), s:cache_file)
endfun

" Find and source local config file. Returns a candidate or ''
fun! exrc#source() abort
  let candidate = ''
  for name in s:names
    if filereadable(name)
      let c = s:Check(name)
      if c == 1
        execute (match(name, '\c\V.lua\$') == -1 ? 'source ' : 'luafile ').fnameescape(name)
        return ''
      elseif c == 0 && candidate ==# ''
        let candidate = name
      endif
    endif
  endfor
  return candidate
endfun

" vim: et sw=2 sts=2
