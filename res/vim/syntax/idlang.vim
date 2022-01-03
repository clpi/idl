" Vim syntax file
" Language: dlang
" Maintainer: Chris Pecunies
" Latest Revision: 19 December 2021

if exists("b:current_syntax")
  finish
endif

sy match dlIdent "\<[_a-z]\(\w\|\'\)*\>"
sy match dlNum "0[xX][0-9a-fA-F]\+\|0[oO][0-7]\|[0-9]\+"
sy match dlFloat "[0-9]\+\.[0-9]\+\([eE][-+]\=[0-9]\+\)\="
sy match dlDelim "[,;|.()[\]{}]"
sy keyword dlTodo contained TODO FIXME XXX NOTE
sy region dlBlock start="{" end="}" fold transparent
sy region dlComment start="\/\*" end="\*\/"  contains=dlTodo
sy region dlCommentLn start="//" end="$" contains=dlTodo
sy region dlStr start=/"/ skip=/\\"/ end=/"/
sy region dlList start=/\[/ end=/\]/ contains=ALL
sy match dlComment "#.*$" contains=dlTodo

sy match dlKey   "/^[^=]\+/"
sy match dlVal "/[^=]\+$/"

sy match dlClass "\k\+" nextgroup=dlImplements
sy match dlValue ".*" contained
sy match  dlArrow        contained "->" nextgroup=textfsmAction,textfsmNext skipwhite
syntax match dlProp /\<.\l\+\>/
syntax match dlIdent /\<\l\+\>/

syntax match dlHas /^has.*/ 
syntax match dlDoes /^does.*/ 
syntax match dlIs /^is.*/ 
syntax cluster dlDefClass contains=dlHas,dlDoes,dlIs

syn keyword dlBoolean true false
syn keyword dlBuiltinTypes str int
syn keyword dlSpecialTypes none my
syn keyword dlInstructions while for as
syn keyword dlConditions if else then
syn keyword dlFunction do new
syn keyword dlDefineFunction to as 
syn keyword dlImplements has is does
syn keyword dlAttr will have
syn match dlVar "[a-zA-Z]+" contained
syn match dlClassData "[a-zA-Z]+ (has|does|is)" contained
 
" syn match dlAttrIdent  "^\S*" nextGroup = dlAttribute
syn keyword dlBasic print put to
sy match  dlDefine       contained "\v<((has|is|does),?)+>" skipwhite
" sy match  dlClass contained "\v\S+" nextgroup=dlDefine skipwhite

let b:current_syntax = "dlang"

" hi def link dlClass        Identifier
hi def link dlIdent        Tag
hi def link dlBoolean      Boolean
hi def link dlComment      Comment
hi def link dlBasic        Keyword
hi def link dlValue        Vale
hi def link dlBuiltinTypes Type
hi def link dlSpecialTypes Constant
hi def link dlStr          String
hi def link dlNum          Constant
hi def link dlFloat        Float
hi def link dlConditions   Conditional
hi def link dlDelim        Delimiter
hi def link dlAttribute    Constant
hi def link dlImplements      Statement
hi def link dlClass        Struct
hi def link dlValue        Value
hi def link dlFunction     Function
hi def link dlDefClass Function
hi def link dlProp TSStrong
hi def link dlTodo  Todo

