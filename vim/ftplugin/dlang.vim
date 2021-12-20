if exists('b:did_ftplugin')
    finish
endif
let b:did_ftplugin = 1

setlocal comments=:#
setlocal commentstring=#\ %s
setlocal suffixesadd=.dl

setlocal errorformat =
    \%ESyntax\ error\ in\ line\ %l:\ %m,
    \%ESyntax\ error\ in\ %f:%l:\ %m,
    \%C%p^,
    \%-C%.%#

let g:dl_compiler_command = get(g:, 'dl_compiler_command', 'dlang')
let g:dl_auto_format = get(g:, 'dl_auto_format', 0)

