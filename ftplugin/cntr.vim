
nnoremap <buffer> <silent> cp :call cntr#table_preview()<CR>
nnoremap <buffer> <silent> cP :call cntr#raw_preview()<CR>
nnoremap <buffer> <silent> c<CR> :call cntr#auto_run()<CR>
nnoremap <buffer> <silent> K :echo cntr#help(expand("<cword>"))<CR>
nnoremap <buffer> <silent> [[ :call cntr#back()<CR>
nnoremap <buffer> <silent> ]] :call cntr#forward()<CR>

command! -nargs=1 ExportZip call cntr#export(<f-args>)

setlocal commentstring=#\ %s

" Break folds on blank lines
setlocal foldmethod=expr
setlocal foldexpr=getline(v:lnum)=~'^\\s*$'?0:1

call cntr#initialize_buffer()
