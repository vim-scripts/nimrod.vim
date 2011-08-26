if exists("current_compiler")
  finish
endif

let current_compiler = "nimrod"

if exists(":CompilerSet") != 2 " older Vim always used :setlocal
  command -nargs=* CompilerSet setlocal <args>
endif

CompilerSet makeprg=nimrod\ c\ $*

CompilerSet errorformat=
    \%f(%l,\ %c)\ Error:\ %m,
    \%f(%l,\ %c)\ Hint:\ %m,
    \%f(%l,\ %c)\ Warning:\ %m

