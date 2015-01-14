if exists('g:loaded_mold') || v:version < 702
  finish
endif
let g:loaded_mold = 1

let s:save_cpo = &cpo
set cpo&vim


let g:mold_dir = expand(get(g:, 'mold_dir', '~/.vim/template'))

command! -nargs=? -bar -complete=customlist,mold#complete
  \ Template call mold#load(<q-args>, 0)

augroup plugin_mold_cmd
  autocmd!
  autocmd User MoldTemplateLoadPre :
  autocmd User MoldTemplateLoadPost :
augroup END


let &cpo = s:save_cpo
unlet s:save_cpo
