if exists("current_compiler")
  finish
endif

let current_compiler = "nimrod"

if exists(":CompilerSet") != 2 " older Vim always used :setlocal
  command -nargs=* CompilerSet setlocal <args>
endif

let s:cpo_save = &cpo
set cpo-=C

CompilerSet makeprg=nimrod\ c\ $*

CompilerSet errorformat=
  \%-GHint:\ %m,
  \%E%f(%l\\,\ %c)\ Error:\ %m,
  \%W%f(%l\\,\ %c)\ Hint:\ %m

" Syntastic syntax checking
function! SyntaxCheckers_nimrod_GetLocList()
  let makeprg = 'nimrod check %'
  let errorformat = &errorformat
  
  return SyntasticMake({ 'makeprg': makeprg, 'errorformat': errorformat })
endfunction

let &cpo = s:cpo_save
unlet s:cpo_save

