let s:save_cpo = &cpo
set cpo&vim


"=== Completion
"==============================================================================================
function! mold#complete(lead, cmdline, curpos) abort
  return s:get_candidate(s:get_filetype(), a:lead)
endfunction

function! s:get_candidate(ft, lead)
  let base_path = s:regulate_path(join([g:mold_dir, a:ft, ''], '/'))

  let candidates = split(globpath(base_path, a:lead . '**'), "\n")
  let candidates = filter(candidates, '!isdirectory(v:val)')
  let candidates = map(candidates, 'v:val[' . len(base_path) . ':]')

  return candidates
endfunction


"=== Load
"==============================================================================================
function! mold#load(file, lnum) abort
  let tmpl = mold#search(s:get_filetype(), a:file, expand('%:p'))

  if empty(tmpl)
    return
  endif

  let empty_buffer = line('$') == 1 && strlen(getline(1)) == 0

  call cursor(a:lnum, 1)
  silent keepalt :.-1 read `=tmpl`

  if empty_buffer
    silent $ delete _
  endif

  doautocmd User MoldLoad
endfunction


"=== Search
"==============================================================================================
function! mold#search(ft, file, current) abort
  let no_ft = empty(a:ft)
  let no_file = empty(a:file)
  let no_current = empty(a:current)

  if no_file && no_current && no_ft
    return ''
  endif

  let file = no_file && !no_current ?
    \ mold#search_by_intelligent(a:ft, a:current)
    \ : mold#search_by_filetype(a:ft, a:file)

  return file
endfunction

function! mold#search_by_filetype(ft, file) abort
  let found = ['', '']  " ['ft', 'file']

  for ft in [a:ft, '_']
    let files = s:get_candidate(ft, a:file)

    if !empty(files)
      let found = [a:ft, files[0]]
      break
    endif
  endfor

  return s:get_template_file(a:ft, files[0])
endfunction

function! mold#search_by_intelligent(ft, path) abort
  let found = [0, '', '']  " [length, 'ft', 'file']

  for ft in [a:ft, '_']
    let files = s:get_candidate(ft, '')

    for file in files
      let pattern = s:to_search_pattern(file)
      let len = len(file)

      if match(a:path, pattern, 0, 1) != -1 && found[0] < len
        let found = [len, ft, file]
      endif
    endfor
  endfor

  return s:get_template_file(found[1], found[2])
endfunction


"=== Misc
"==============================================================================================
"  Filetype
"-----------------------------------------------
function! s:get_filetype()
  if empty(&ft)
    let parts = split(expand('%:t'), '\.')
    return tolower(get(parts, len(parts) - 1, ''))
  else
    return &ft
  endif
endfunction


"  Regulate path
"-----------------------------------------------
function! s:regulate_path(path)
  let path = a:path

  if has('win16') || has('win32') || has('win64')
    let path = substitute(path, '\\', '/', 'g')
  endif

  let path = substitute(path, '/\+', '/', 'g')

  return path
endfunction


"  Path to search pattern
"-----------------------------------------------
function! s:to_search_pattern(path)
  let pattern = escape(a:path, '\\.*$^~')
  let pattern = substitute(pattern, '/', '/\\([^/]\\+/\\)*', 'g')
  let pattern = substitute(pattern, 'template', '[^/]*', 'g')

  return pattern . '$'
endfunction


"  Get template file
"-----------------------------------------------
function! s:get_template_file(ft, file)
  if empty(a:file)
    return ''
  else
    return s:regulate_path(join([g:mold_dir, a:ft, a:file], '/'))
  endif
endfunction


let &cpo = s:save_cpo
