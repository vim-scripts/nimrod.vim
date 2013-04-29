let g:nimrod_log = []
let s:plugin_path = escape(expand('<sfile>:p:h'), ' \')

exe 'pyfile ' . fnameescape(s:plugin_path) . '/nimrod_vim.py'

fun! nimrod#init()
  let b:nimrod_project_root = "/foo"
  let b:nimrod_caas_enabled = 0
endf

fun! s:UpdateNimLog()
  setlocal buftype=nofile
  setlocal bufhidden=hide
  setlocal noswapfile

  for entry in g:nimrod_log
    call append(line('$'), split(entry, "\n"))
  endfor

  let g:nimrod_log = []

  match Search /^nimrod\ idetools.*/
endf

augroup NimLog
  au!
  au BufEnter log://nimrod call s:UpdateNimLog()
augroup END

fun! s:CurrentNimrodFile()
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

let g:nimrod_symbol_types = {
  \ 'skParam': 'v',
  \ 'skVar': 'v',
  \ 'skLet': 'v',
  \ 'skTemp': 'v',
  \ 'skForVar': 'v',
  \ 'skConst': 'v',
  \ 'skResult': 'v',
  \ 'skGenericParam': 't',
  \ 'skType': 't',
  \ 'skField': 'm',
  \ 'skProc': 'f',
  \ 'skMethod': 'f',
  \ 'skIterator': 'f',
  \ 'skConverter': 'f',
  \ 'skMacro': 'f',
  \ 'skTemplate': 'f',
  \ 'skEnumField': 'v',
  \ }

fun! NimExec(op)
  let cmd = printf("idetools %s --track:\"%s,%d,%d\" \"%s\"",
              \ a:op, expand('%:p'), line('.'), col('.')-1, s:CurrentNimrodFile())

  if b:nimrod_caas_enabled
    exe printf("py execNimCmd('%s', '%s', False)", b:nimrod_project_root, cmd)
    let output = l:py_res
  else
    let syscmd = "nimrod " . cmd
    call add(g:nimrod_log, syscmd)
    let output = system(syscmd)
  endif

  call add(g:nimrod_log, output)
  return output
endf

fun! NimExecAsync(op, Handler)
  let result = NimExec(a:op)
  call a:Handler(result)
endf

fun! NimComplete(findstart, base)
  if a:findstart
    if synIDattr(synIDtrans(synID(line("."),col("."),1)), "name") == 'Comment'
      return -1
    endif
    return col('.')
  else
    let result = []
    let sugOut = NimExec("--suggest")
    for line in split(sugOut, '\n')
      let lineData = split(line, '\t')
      if lineData[0] == "sug"
        let kind = get(g:nimrod_symbol_types, lineData[1], '')
        let c = { 'word': lineData[2], 'kind': kind, 'menu': lineData[3], 'dup': 1 }
        call add(result, c)
      endif
    endfor
    return result
  endif
endf

if !exists("g:neocomplcache_omni_patterns")
  let g:neocomplcache_omni_patterns = {}
endif

" let g:neocomplcache_omni_patterns['nimrod'] = '[^. *\t]\.\w*'

fun! StartNimrodThread()
endf

let g:nimrod_completion_callbacks = {}

fun! NimrodAsyncCmdComplete(cmd, output)
  call add(g:nimrod_log, a:output)
  echom g:nimrod_completion_callbacks
  if has_key(g:nimrod_completion_callbacks, a:cmd)
    let Callback = get(g:nimrod_completion_callbacks, a:cmd)
    call Callback(a:output)
    " remove(g:nimrod_completion_callbacks, a:cmd)
  else
    echom "ERROR, Unknown Command: " . a:cmd
  endif
  return 1
endf

fun! GotoDefinition_nimrod_ready(def_output)
  if v:shell_error
    echo "nimrod was unable to locate the definition. exit code: " . v:shell_error
    " echoerr a:def_output
    return 0
  endif
  
  let rawDef = matchstr(a:def_output, 'def\t\([^\n]*\)')
  if rawDef == ""
    echo "the current cursor position does not match any definitions"
    return 0
  endif
  
  let defBits = split(rawDef, '\t')
  let file = defBits[4]
  let line = defBits[5]
  exe printf("e +%d %s", line, file)
  return 1
endf

fun! GotoDefinition_nimrod()
  call NimExecAsync("--def", function("GotoDefinition_nimrod_ready"))
endf

fun! FindReferences_nimrod()
  setloclist()
endf

" Syntastic syntax checking
fun! SyntaxCheckers_nimrod_GetLocList()
  let makeprg = 'nimrod check ' . s:CurrentNimrodFile()
  let errorformat = &errorformat
  
  return SyntasticMake({ 'makeprg': makeprg, 'errorformat': errorformat })
endf

