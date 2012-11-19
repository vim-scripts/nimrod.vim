if exists("b:nimrod_loaded")
  finish
endif

let b:nimrod_loaded = 1

let s:cpo_save = &cpo
set cpo&vim

call nimrod#init()

setlocal formatoptions-=t formatoptions+=croql
setlocal comments=:##,:#
setlocal commentstring=#\ %s
setlocal omnifunc=NimComplete
compiler nimrod

let &cpo = s:cpo_save
unlet s:cpo_save

