# exrc.vim

Secure local config files.

Vim provides a feature called `exrc`, which allows to use config files that are local to
the current working directory. However, unconditionally sourcing whatever files we might
have in our current working directory can be potentially dangerous. Because of that, vim
introduced another option, `secure`, which disables autocmd, shell and write commands in
such files. As this solution is far from perfect, the `exrc.vim` plugin tries to solve
this issue by keeping track of file hashes and allowing only trusted files to be sourced.

## Usage

When exrc.vim detects a new config file, it will ask what do you want to do with it:

```
exrc.vim: Unknown config found: /path/to/.exrc
[i]gnore, (e)dit, (b)lacklist, (t)rust:
```

You can either `i`gnore this file for now, `e`dit it to see if it doesn't contain anything
malicious, `b`lacklist the file so `exrc.vim` won't ask you about it again, or `t`rust and
source it right away.

To manually mark file as trusted, open the config file with `:edit .exrc` or `:ExrcEdit`
and run command `:ExrcTrust`. Files that were once blacklisted can be trusted with
`:ExrcTrust!`. File has to be marked as trusted each time its contents or path
changes.

## Configuration

Mark file as trusted on save:
```vim
autocmd BufWritePost .exrc nested silent ExrcTrust
```

Change filename of local config files:
```vim
let g:exrc#names = ['.exrc.local']

" add syntax highlighting:
autocmd BufRead,BufNewFile .exrc.local setfiletype vim
```

Lua support:
```vim
let g:exrc#names = ['.exrc', '.exrc.lua']
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

## Looking up config files recursively

This plugin just reimplements the `exrc` option in a secure manner, it does not look up
files recursively (at least for now), meaning that it will only detect config files in the
current working directory. If you want this behavior, check out
[jenterkin/vim-autosource](https://github.com/jenterkin/vim-autosource) plugin. It's the
same concept, but searches for config files recursively.
