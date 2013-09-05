" nextfile.vim - browse related files and open a file
" Maintainer:  Allen Kim <bighostkim@gmail.com>
" License:     MIT license
" Version:     0.1

" Do not load this plugin if is has already been loaded.
if exists("g:loadedNextFile")
  finish
endif
let g:loadedNextFile = 0.1  " version number

" TODO: this can be done by file types
if !exists("g:relatedFiles") " User can add more groups
  let g:relatedFiles = {
    \ "Ruby On Rails" : {
      \ "Controller" : { "expression" : "app/controllers/(.*)_controller.rb$", "transform" : "pluralize" },
      \ "Funtional Test" : { "expression" : "test/functional/(.*)_controller_test.rb$", "transform" : "pluralize" },
      \ "View" : { "expression" : "app/view/(.*)/", "transform" : "pluralize" },
      \ "Model" : { "expression" : "app/models/(.*).rb$", "transform" : "singularize" },
      \ "Unit Test" : { "expression" : "test/unit/(.*)_test.rb$", "transform" : "singularize" }
    \ }
  \ }
endif

let s:scriptDirectory = expand('<sfile>:p:h') " current script directory path

" Function : NextFile(PUBLIC)
" Purpose  : Lists the related file by checking the current file path 
" Args     : none
" Returns  : none
function! NextFile() 
  let currentFile = expand("%:p")
  let relatedFiles = s:GetRelatedFiles(currentFile)
  if empty(relatedFiles)
    call s:Warn("Could not find definition of matching related files. For details :echo relatedFiles")
    return
  else
    call s:OpenWindow(relatedFiles)
  endif
endfunction

" ------------------------------------------------------------------------------
" Function : Warn(PRIVATE)
" Purpose  : Show warning message
" Args     : message
" Returns  : none
function! s:Warn(msg)
  echohl WarningMsg
  echo "WARNING ".a:msg
  echohl None
endfunction

" ------------------------------------------------------------------------------
" Function : GetRelatedFiles (PRIVATE)
" Purpose  : To list related files from the current file path
" Args     : Current file path
" Returns  : list of files in dictionary
function! s:GetRelatedFiles(currentFilePath)
  let [groupName, expr] = s:GetFileGroup(a:currentFilePath)
  let expr = substitute(expr, '\v\$$', '', 'g') " remove traling dollar($) sign
  let relatedFiles = {}
  if groupName != ""
    let word = matchlist(a:currentFilePath, '\v'.expr)[1]
    let relativePath = substitute(expr, '(.*)', word, '') 
    let pos = match(a:currentFilePath, '\v'.relativePath) - 1
    let absoluteAffix = a:currentFilePath[:pos]
    for [key, dict] in items(g:relatedFiles[groupName])
      let replExpr = substitute(dict["expression"], '\v\$$', '', 'g')
      if dict["transform"] == "singularize"
        let relatedFiles[key] = absoluteAffix.substitute(replExpr, '(.*)', s:Singularize(word), '') 
      elseif dict["transform"] == "pluralize"
      echo ["12", s:Pluralize(word)]
        let relatedFiles[key] = absoluteAffix.substitute(replExpr, '(.*)', s:Pluralize(word), '') 
      else
        let relatedFiles[key] = absoluteAffix.substitute(replExpr, '(.*)', word, '') 
      end
    endfor
  endif
  return relatedFiles
endfunction

" ------------------------------------------------------------------------------
" Function : GetFileGroup (PRIVATE)
" Purpose  : To get the group name and expression of current file
" Args     : Current file path
" Returns  : group name, regular expression
function! s:GetFileGroup(currentFilePath)
  for [groupName, filesDict] in items(g:relatedFiles)
    for [key, dict] in items(filesDict)
      if a:currentFilePath =~? '\v'.dict["expression"]
        return [groupName, dict["expression"]]
      endif
    endfor
  endfor
  return ["", ""]
endfunction

" ------------------------------------------------------------------------------
" Function : Singularize (PRIVATE)
" Purpose  : To convert a word to a singular form
" Args     : string
" Returns  : singularized word
function! s:Singularize(word)
    if !exists("g:singularExpressions")
      let g:singularExpressions = []
      let list = readfile(s:scriptDirectory."/singular_expressions.txt")
      for line in list
        let strs = split(line)
        let findEx = strs[0]
        if len(strs) == 1
          let replEx = ""
        else
          let replEx = strs[1]
        endif
        call add(g:singularExpressions, [findEx, replEx])
      endfor
    endif
    for exp in g:singularExpressions
      let findEx = substitute(exp[0], '\v^\/?|\/?i?$', '', 'g')
      let replEx = exp[1]
      if a:word =~? '\v'.findEx
        return substitute(a:word,'\v'.findEx, replEx, '')
      endif
    endfor
    return a:word
endfunction

" ------------------------------------------------------------------------------
" Function : Pluralize (PRIVATE)
" Purpose  : To convert a word to a plural form
" Args     : string
" Returns  : pluralized word
function! s:Pluralize(word)
    if !exists("g:pluralExpressions")
      let g:pluralExpressions = []
      let list = readfile(s:scriptDirectory."/plural_expressions.txt")
      for line in list
        let strs = split(line)
        let findEx = strs[0]
        if len(strs) == 1
          let replEx = ""
        else
          let replEx = strs[1]
       endif
        call add(g:pluralExpressions, [findEx, replEx])
      endfor
    endif
    for exp in g:pluralExpressions
      let findEx = substitute(exp[0], '\v^\/?|\/?i?$', '', 'g')
      let replEx = exp[1]
      if a:word =~? '\v'.findEx
        return substitute(a:word, '\v'.findEx, replEx, '')
      endif
    endfor
    return a:word
endfunction

" ------------------------------------------------------------------------------
" Function : OpenWindow(PRIVATE)
" Purpose  : Display related files in a temporary window
" Args     : List of files as dictionary, i.e. {"Controller" : "/home/users/myproject/app/controllers/
" Returns  : None
"
" Thanks fot MRU, majority of the following code is copy/pasted from mru.vim
"
function! s:OpenWindow(dict)
    " Save the current buffer number. This is used later to open a file when a entry is selected from the temporary window.
    let s:lastBuffer = bufnr('%')

    let bname = '__next_files__'

    " If the window is already open, jump to it
    let winnum = bufwinnr(bname)
    if winnum != -1
      if winnr() != winnum  " If not already in the window, jump to it
        exe winnum . 'wincmd w'
      endif

      setlocal modifiable

      silent! %delete _ " Delete the contents of the buffer to the black-hole register
    else
      " Open a new window at the bottom && open a new buffer
      let bufnum = bufnr(bname)
      if bufnum == -1
        let wcmd = bname
      else
        let wcmd = '+buffer' . bufnum
      endif

      exe 'silent! botright 10split '.wcmd
    endif

    " Mark the buffer as scratch
    setlocal buftype=nofile
    setlocal bufhidden=delete
    setlocal noswapfile
    setlocal nowrap
    setlocal nobuflisted
    setlocal winfixheight

    " Setup the cpoptions properly for the maps to work
    let old_cpoptions = &cpoptions
    set cpoptions&vim

    " Create mappings to select and edit a file from the file list
    nnoremap <buffer> <silent> <CR> :call <SID>OpenFile('edit')<CR>
    vnoremap <buffer> <silent> <CR> :call <SID>OpenFile('edit')<CR>
    nnoremap <buffer> <silent> o :call <SID>OpenFile('split')<CR>
    vnoremap <buffer> <silent> o :call <SID>OpenFile('split')<CR>
    nnoremap <buffer> <silent> O :call <SID>OpenFile('vsplit')<CR>
    vnoremap <buffer> <silent> O :call <SID>OpenFile('vsplit')<CR>
    nnoremap <buffer> <silent> q :close<CR>

    " Restore the previous cpoptions settings
    let &cpoptions = old_cpoptions

    " Display the file list
    let files = []
    for [name, path] in items(a:dict)
      call add(files, name." (".path.")")
    endfor

    let m = copy(files)   " shallw copy of file list
    silent! 0put =m       " put the files from the top of the document
    $delete               " Delete the empty line at the end of the buffer
    normal! gg            " Move the cursor to the beginning of the file
    setlocal nomodifiable " not for edit
endfunction

" ------------------------------------------------------------------------------
" Function : OpenFile(PRIVATE)
" Purpose  : Open a file selected from the temporary window
" Args     : openType, how to open a file, split, vsplit, or edit
" Returns  : None
function! s:OpenFile(openType) range

  let lineStr = getline(".")                   " string of current line
  let fname = matchstr(lineStr, '(\zs.*\ze)')  " get file name between ( and )
  let escFname = escape(fname, ' *?[{`$%#"|!<>();&' . "'\t\n") " special character escaped file name

  " close this window since it is invoked by key map from the temporary window
  " this has to be done AFTER you get the contents of current line
  silent! close  

  if a:openType == 'split'    " Edit the file in a new horizontally split window above the previous window
    wincmd p
    exe 'belowright new ' . escFname
  elseif a:openType == 'vsplit' " Edit the file in a new vertically split window above the previous window
    wincmd p
    exe 'belowright vnew ' . escFname
  elseif a:openType == 'edit'
    let winnum = bufwinnr('^' . escFname . '$')
    if winnum != -1  " If the selected file is already open in one of the windows, jump to it
      exe winnum . 'wincmd w'
    else             " use the previous window
      wincmd p 

      let split_window = 0
      " open in a split window if;
      " . current buffer is modified or is the preview window
      " . current buffer is a special buffer (maybe used by a plugin)
      if &modified || &previewwindow 
        let split_window = 1 
      elseif &buftype != '' && bufnr('%') != bufnr('__next_files__') 
        let split_window = 1      
      endif

      if split_window
        exe 'split ' . escFname
      else
        exe 'edit ' . escFname
      endif
    endif
  endif
endfunction
