if exists("g:did_cntr_autoload")
  finish
endif
let g:did_cntr_autoload = 1

if !exists("*sha256")
  echoerr "WARNING: +cryptv feature not found. cntr.vim will not work without this feature"
endif

if !exists("g:cntr_home")
  " TODO bundle the scripts and make this a more sensible default based on vim plugin location
  let g:cntr_home = $HOME."/src/csv-utils/bin"
  let g:cntr_buffer_name = "*** CNTR RESULTS ***"
endif

" trims leading and trailing whitespace from a str
" @param str  the string to trim
" @return     that string with leading and trailing whitespace removed
function! s:trim(str)
  return substitute(a:str, "^[[:space:]]*\\|[[:space:]]*$", "", "g")
endfunction

" block type enum values
let s:definition = 'definition'
let s:initializer = 'initializer'

" returns the type of the block (s:definition or s:initializer)
" @param  block  a list of strings, representing one block from a .cntr file
" @return        an enum string representing the type of the block
function! s:block_type(block)
  if a:block[0][0] == '='
    return s:definition
  else
    return s:initializer
  endif
endfunction

" returns true if the given line is a variable declaration
" @arg  line  the to be checked
" @return     true or false
function! s:is_variable(line)
  return match(a:line, "[A-Za-z0-9_][A-Za-z0-9_]*=.*") != -1
endfunction

" Runs one variable declaration line of a block
" @param line  a variable declaration line like "FOO='BAR'"
function! s:define_variable(line)
  let eq_index = match(a:line, '=')
  let key = a:line[0 : eq_index-1]
  let value = a:line[eq_index+1 : ]
  try
    execute "let $".key."=".value
  catch
    if value[0] != "'"
      throw "Unquoted environment variable " . a:line
    else
      throw "Failed to set environment variable: " . a:line
    endif
  endtry
endfunction

" Run an initializer block line by line.
" @arg  block  the initializer block to run
function! s:handle_initializer(block)
  for line in a:block
    if s:is_variable(line)
      call s:define_variable(line)
    else
      call system(line)
    endif
  endfor
endfunction

" Extract all the dependencies from a line.
" @arg  line  the line to extract dependencies from
" @return     a list of all the definition this line depends on
function! s:line_dependencies(line)
  let words = split(a:line, ' ')
  let deps = []
  for word in words
    if match(word, '^%[^[:space:]]*') != -1
      call add(deps, word[1 : ])
    endif
  endfor
  return deps
endfunction

" Extract all the dependencies from a definition block.
" @arg  block  a list of lines representing a definition block
" @return      a list of all the blocks this definition depends on
function! s:dependencies(block)
  let deps = []
  for line in a:block[1 : ]
    let deps = deps + s:line_dependencies(line)
  endfor
  return deps
endfunction

" store the enriched definition object for a block in the buffer definitions
" map
" @arg  block  a list of lines representing a definition block
" @return      a map representing a definition block
function! s:handle_definition(block)
  let l:file = substitute(a:block[0], '^[[:space:]]*=', '', '')
  let l:lines = a:block[1 : ]
  let l:deps = s:dependencies(a:block)
  let b:cntr_definitions[l:file] = {'file': l:file, 'lines': l:lines, 'dependencies': l:deps}
endfunction

" handle a single block from a cntr file... either by running it (for
" initializers) or by storing it in the definitions map.
" @arg  block  a list of lines representing a definition block
function! s:handle_block(block)
  let l:type = s:block_type(a:block)
  if l:type == 'definition'
    call s:handle_definition(a:block)
  elseif l:type == 'initializer'
    call s:handle_initializer(a:block)
  endif
endfunction

function! s:calculate_definition_hash(definition)
  let dependency_hashes = ''
  for dependency in a:definition.dependencies
    let dependency_hashes = dependency_hashes . s:calculate_definition_hash(b:cntr_definitions[dependency])
  endfor
  return sha256(join(a:definition.lines, "\n") . dependency_hashes)
endfunction

function! s:get_definition_hash(def_name)
  let def = b:cntr_definitions[a:def_name]
  if !has_key(b:cntr_definitions, 'hash')
    let def['hash'] = s:calculate_definition_hash(def)
  endif
  return def['hash']
endfunction

function! s:calculate_definition_hashes()
  for def_name in keys(b:cntr_definitions)
    call s:get_definition_hash(def_name)
  endfor
endfunction

" parse the entire file, storing definitions, building up the dependency tree
" and running all the initializer blocks.
function! s:parse()
  call s:initialize_buffer()
  let b:cntr_definitions = {}
  let lnum = 1
  let current_block = []
  while lnum <= line("$")
    let l = getline(lnum)
    if strlen(s:trim(l)) > 0
      call add(current_block, l)
    elseif len(current_block) > 0
      call s:handle_block(current_block)
      let current_block = []
    endif
    let lnum = lnum + 1
  endwhile
  if len(current_block) > 0
    call s:handle_block(current_block)
  endif
  call s:calculate_definition_hashes()
endfunction

function! s:do_initialize_buffer()
  let b:cntr_directory = tempname() . "/" . substitute(expand("%:p")[1 : ], "/", ".", "g") . '/'
  call mkdir(b:cntr_directory, "p")
  let $PATH=g:cntr_home.":".$PATH
  let b:cntr_cache = {}
  let b:cntr_done_init_buffer = 1
endfunction

function! s:initialize_buffer()
  if !exists("b:cntr_done_init_buffer")
    call s:do_initialize_buffer()
  endif
endfunction

function! s:replace_dependencies(cmd)
  return substitute(a:cmd, "\\(^\\|[[:space:]]\\)\\zs%\\ze[^[:space:]]", b:cntr_directory, 'g')
endfunction

function! s:run_pipe(cmds)
  let output = ""
  for cmd in a:cmds
    let cmd = s:trim(s:replace_dependencies(cmd))
    if cmd[0] == "#"
      " noop
    elseif output == ""
      let output = system(cmd)
    else
      let output = system(cmd, output)
    endif
  endfor
  return output
endfunction

function! s:is_cached(definition)
  let def_name = a:definition.file
  return has_key(b:cntr_cache, def_name) && b:cntr_cache[def_name] == a:definition.hash
endfunction

function! s:add_to_cache(definition)
  let b:cntr_cache[a:definition.file] = a:definition.hash
endfunction

function! s:run_dependencies(definition)
  for dependency in a:definition.dependencies
    let dependency_definition = b:cntr_definitions[dependency]
    if s:is_cached(dependency_definition)
      return
    end
    call s:run_definition(dependency)
  endfor
endfunction

function! s:make_output_dir(output_file)
  let output_dir = fnamemodify(a:output_file, ":p:h") 
  if !isdirectory(output_dir)
    call mkdir(output_dir, "p")
  endif
endfunction

function! s:file_path(definition_name)
  return b:cntr_directory . a:definition_name
endfunction

function! s:run_definition(name)
  let definition = b:cntr_definitions[a:name]
  call s:run_dependencies(definition)
  let output_file = s:file_path(definition.file)
  call s:make_output_dir(output_file)
  call system("cat > " . output_file, s:run_pipe(definition.lines))
  call s:add_to_cache(definition)
  return output_file
endfunction

" Preview the results of a definition.
" @arg  name           the name of the definition to execute
" @arg  limit          the number of rows to display
" @arg  execute_until  stop execution after this number of cmds
" @return              the output of the definition as a string
function! s:preview_definition(name, limit, execute_until)
  let definition = b:cntr_definitions[a:name]
  let lines = definition.lines
  if a:execute_until != 0
    let lines = lines[0 : a:execute_until - 1]
  endif
  call s:run_dependencies(definition)
  return system("head -n ".a:limit, s:run_pipe(lines))
endfunction

function! s:raw_run(name)
  call s:parse()
  call s:run_definition(a:name)
  call show#show(g:cntr_buffer_name, readfile(s:file_path(a:name)))
endfunction

function! s:table_run(name)
  call s:parse()
  call s:run_definition(a:name)
  let result = system("cat " . s:file_path(a:name) . " | table")
  call show#show(g:cntr_buffer_name, split(result, "\n"))
endfunction

function! s:is_definition(lnum)
  return getline(a:lnum)[0] == '='
endfunction

function! s:is_start_of_block(lnum)
  let lnum = a:lnum ==# '.' ? line(a:lnum) : a:lnum
  let line = getline(lnum - 1)
  return (lnum == 0) || (s:trim(line) == '')
endfunction

" Returns the name of the definition, and the cmd number under the cursor. Returns {} if the
" cursor isn't on a definition.
"
" @return  an object with two keys, 'name' (for the name of the definition)
"          and 'cmd_num' (for the cmd number under the cursor)
function! s:cursor_location()
  let lnum = line('.')
  let n = 0
  while !s:is_definition(lnum)
    if s:is_start_of_block(lnum) == 1
      return {}
    end
    let lnum = lnum - 1
    let n = n + 1
  endwhile
  return {'name': getline(lnum)[1 : ], 'cmd_num': n}
endfunction

function! s:validate_is_definition(location)
  if !has_key(a:location, 'name')
    throw "No pipeline to execute"
  endif
endfunction

function! cntr#auto_run()
  let location = s:cursor_location()
  call s:validate_is_definition(location)
  let name = location.name
  if name[-4 : -1] == ".csv"
    call s:table_run(name)
  else
    call s:raw_run(name)
  endif
endfunction

function! cntr#raw_preview()
  let location = s:cursor_location()
  call s:validate_is_definition(location)
  call s:parse()
  let name = location.name
  let cmd_num = location.cmd_num
  echo s:preview_definition(name, 11, cmd_num)
endfunction

function! cntr#table_preview()
  let location = s:cursor_location()
  call s:validate_is_definition(location)
  call s:parse()
  let name = location.name
  let cmd_num = location.cmd_num
  echo system("table", s:preview_definition(name, 11, cmd_num))
endfunction

function! cntr#back()
  norm! k0
  while !s:is_start_of_block('.')
    norm! k0
  endwhile
endfunction

function! cntr#forward()
  norm! j0
  while (!s:is_start_of_block('.')) && (line('.') != line('$'))
    norm! j0
  endwhile
endfunction

function! cntr#export(output)
  echo system("cd ". b:cntr_directory . " && zip -r " . fnamemodify(a:output, ":p") . ".zip .")
endfunction
