if (exists("b:did_ftplugin"))
  finish
endif

let b:did_ftplugin = 1

let s:cpo_save = &cpo
set cpo&vim

setlocal formatoptions-=t formatoptions+=croql
setlocal comments=:#
setlocal commentstring=#\ %s

compiler nimrod

if executable('nimrod')
  let nimrod_paths = split(system('nimrod dump'),'\n')
  let &l:tags = &g:tags

  for path in nimrod_paths
    if finddir(path) == path
      let &l:tags = path . "/tags," . &l:tags
    endif
  endfor
endif

let &cpo = s:cpo_save
unlet s:cpo_save

