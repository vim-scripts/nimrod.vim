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
  let save_cur = getpos('.')
  call cursor(0, 0, 0)
  
  let PATTERN = "\\v^\\#\\s*included from \\zs.*\\ze"
  let l = search(PATTERN, "n")

  if l != 0
    let f = matchstr(getline(l), PATTERN)
    let l:to_check = expand('%:h') . "/" . f
  else
    let l:to_check = expand("%")
  endif

  call setpos('.', save_cur)

  let makeprg = 'nimrod check ' . l:to_check
  let errorformat = &errorformat
  
  return SyntasticMake({ 'makeprg': makeprg, 'errorformat': errorformat })
endfunction

let &cpo = s:cpo_save
unlet s:cpo_save

