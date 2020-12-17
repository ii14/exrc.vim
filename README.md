# exrc.vim

Secure local config files.

Vim provides a feature called `exrc`, which allows to use config files that are local to
the current working directory. However, unconditionally sourcing whatever files we might
have in our current working directory can be potentially dangerous. Because of that, vim
introduced another option, `secure`, which disables autocmd, shell and write commands in
such files. As this solution is far from perfect, the `exrc.vim` plugin tries to solve
this issue by keeping track of file hashes and allowing only trusted files to be sourced.

## Usage

To mark file as trusted, open the config file with `:edit .exrc.local` or `:ExrcEdit` and
run command:

```vim
:ExrcTrust
```

The file has to be marked as trusted each time its contents or path changes.

## Configuration

Mark file as trusted on save:

```vim
autocmd BufWritePost .exrc.local nested ExrcTrust
```

Change filename of local config files:

```vim
let g:exrc#names = ['.exrc.local']
```

Cache file location:

```vim
let g:exrc#cache_file = $XDG_CACHE_HOME.'/exrc_cache'
```

Custom hashing function:

```vim
fun! HashFile(fname)
  return system('sha512sum '.shellescape(a:fname))
endfun

let g:exrc#hash_func = 'HashFile'
```

Add syntax highlighting to your local config files:

```vim
autocmd BufRead,BufNewFile .exrc.local setfiletype vim
```
