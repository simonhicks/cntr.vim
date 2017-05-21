
nnoremap <buffer> <silent> cp :call cntr#table_preview()<CR>
nnoremap <buffer> <silent> cP :call cntr#raw_preview()<CR>
nnoremap <buffer> <silent> c<CR> :call cntr#auto_run()<CR>
nnoremap <buffer> <silent> K :echo system(expand("<cword>") . " -h")<CR>
nnoremap <buffer> <silent> [[ :call cntr#back()<CR>
nnoremap <buffer> <silent> ]] :call cntr#forward()<CR>
