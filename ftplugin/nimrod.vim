if exists("b:nimrod_loaded")
  finish
endif

let b:nimrod_loaded = 1

let s:cpo_save = &cpo
set cpo&vim

if executable('nimrod')
  let nimrod_paths = split(system('nimrod dump'),'\n')
  let &l:tags = &g:tags

  for path in nimrod_paths
    if finddir(path) == path
      let &l:tags = path . "/tags," . &l:tags
    endif
  endfor
endif

fun! CurrentNimrodFile()
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
  return l:to_check
endf

fun! NimComplete(findstart, base)
  if a:findstart
    if synIDattr(synIDtrans(synID(line("."),col("."),1)), "name") == 'Comment'
      return -1
    endif
    return col('.')
  else
    let result = []
    let cmd = printf("nimrod idetools --suggest --track:\"%s,%d,%d\" \"%s\"",
                   \ expand('%:p'), line('.'), col('.'), CurrentNimrodFile())

    let sugOut = system(cmd)
    for line in split(sugOut, '\n')
      let lineData = split(line, '\t')
      if lineData[0] == "sug"
        let c = { 'word': lineData[2], 'info': lineData[3] }
        call add(result, c)
      endif
    endfor
    return result
  endif
endf

if !exists("g:neocomplcache_omni_patterns")
  let g:neocomplcache_omni_patterns = {}
endif

let g:neocomplcache_omni_patterns['nimrod'] = '[^. *\t]\.\w*\'

fun! GotoDefinition_nimrod()
  let cmd = printf("nimrod idetools --def --track:\"%s,%d,%d\" \"%s\"",
                   \ expand('%:p'), line('.'), col('.'), CurrentNimrodFile())

  let defOut = system(cmd)
  if v:shell_error
    echoerr "error executing nimrod. exit code: " . v:shell_error
    echoerr defOut
    return 0
  endif
  
  let rawDef = matchstr(defOut, 'def\t\([^\n]*\)')
  if rawDef == ""
    echo "nimrod was unable to locate the definition"
    return 0
  endif
  
  let defBits = split(rawDef, '\t')
  let file = defBits[4]
  let line = defBits[5]
  exe printf("e +%d %s", line, file)
  return 1
endf

" Syntastic syntax checking
fun! SyntaxCheckers_nimrod_GetLocList()
  let makeprg = 'nimrod check ' . CurrentNimrodFile()
  let errorformat = &errorformat
  
  return SyntasticMake({ 'makeprg': makeprg, 'errorformat': errorformat })
endf

setlocal formatoptions-=t formatoptions+=croql
setlocal comments=:#
setlocal commentstring=#\ %s
setlocal omnifunc=NimComplete
compiler nimrod

let &cpo = s:cpo_save
unlet s:cpo_save

