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
function! mold#load(file, do_confirm) abort
  let tmpl = mold#search(s:get_filetype(), expand('%:p'), a:file)

  if tmpl == ''
    return
  endif

  if a:do_confirm && confirm('[Mold] Load "' . tmpl . '"', '', 0) == 0
    return
  endif

  doautocmd User MoldTemplateLoadPre

  let empty_buffer = line('$') == 1 && strlen(getline(1)) == 0

  silent keepalt :.-1 read `=tmpl`

  if empty_buffer
    silent $ delete _
  endif

  doautocmd User MoldTemplateLoadPost
endfunction


"=== Search
"==============================================================================================
function! mold#search(ft, current, file) abort
  if a:current != '' && a:file == ''
    return mold#search_by_intelligent(a:ft, a:current)
  elseif a:file != ''
    return mold#search_by_filetype(a:ft, a:file)
  else
    return ''
  endif
endfunction

function! mold#search_by_filetype(ft, file) abort
  let matched = ['', '']  " ['ft', 'file']

  for ft in [a:ft, '_']
    let files = s:get_candidate(ft, a:file)

    if !empty(files)
      let matched = [ft, files[0]]
      break
    endif
  endfor

  return s:get_template_file(matched[0], matched[1])
endfunction

function! mold#search_by_intelligent(ft, path) abort
  let matched = ['', '', 0]  " ['ft', 'file', length]

  for ft in [a:ft, '_']
    let files = s:get_candidate(ft, '')

    for file in files
      let pattern = s:to_search_pattern(file)
      let len = len(file)

      if match(a:path, pattern, 0, 1) != -1 && matched[2] < len
        let matched = [ft, file, len]
      endif
    endfor
  endfor

  return s:get_template_file(matched[0], matched[1])
endfunction


"=== Misc
"==============================================================================================
"  Filetype
"-----------------------------------------------
function! s:get_filetype()
  if &ft == ''
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
  if a:file == ''
    return ''
  else
    return s:regulate_path(join([g:mold_dir, a:ft, a:file], '/'))
  endif
endfunction


let &cpo = s:save_cpo
