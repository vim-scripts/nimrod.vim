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
setlocal suffixesadd=.nim 

if executable('nimrod')
  let nimrod_paths = split(system('nimrod dump'),'\n')
  let &l:path = &g:path

  for path in nimrod_paths
    if finddir(path) == path
      let &l:path = path . "," . &l:path
    endif
  endfor
endif

compiler nimrod

let &cpo = s:cpo_save
unlet s:cpo_save

