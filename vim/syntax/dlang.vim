" Vim syntax file
" Language: dlang
" Maintainer: Chris Pecunies
" Latest Revision: 19 December 2021

if exists("b:current_syntax")
  finish
endif

syn match dlangIdent "\<[_a-z]\(\w\|\'\)*\>"
syn match dlangNum "0[xX][0-9a-fA-F]\+\|0[oO][0-7]\|[0-9]\+"
syn match dlangFloat "[0-9]\+\.[0-9]\+\([eE][-+]\=[0-9]\+\)\="
syn match dlangDelim "[,;|.()[\]{}]"

syn keyword dlangBoolean true false

" Keywords
syn keyword syntaxElementKeyword keyword1 keyword2 nextgroup=syntaxElement2

" Matches
syn match syntaxElementMatch 'regexp' contains=syntaxElement1 nextgroup=syntaxElement2 skipwhite

" Regions
syn region syntaxElementRegion start='x' end='y'
