" File: eslint.vim
" Author: Shinya Ohyanagi <sohyanagi@gmail.com>
" WebPage: http://github.com/heavenshell/vim-eslint
" Description: Vim plugin for eslint
" License: BSD, see LICENSE for more details.
let s:save_cpo = &cpo
set cpo&vim

let g:eslint_path = get(g:, 'eslint_path', '')
let g:eslint_callbacks = get(g:, 'eslint_callbacks', {})
let g:eslint_ext = get(g:, 'eslint_ext', '.js,.jsx.ts,.tsx')
let g:eslint_verbose = get(g:, 'eslint_verbose', 0)
let g:eslint_enable_cache = get(g:, 'eslint_enable_cache', 0)
let g:eslint_rcfiles = get(g:, 'eslint_rcfiles', [
  \ '.eslintrc.js',
  \ '.eslintrc',
  \ '.eslintrc.json',
  \ '.eslintrc.yaml',
  \ '.eslintrc.yml',
  \ '.eslintrc.cjs',
  \ 'package.json',
  \])
let g:eslint_enable_eslint_d = get(g:, 'eslint_enable_eslint_d', 0)

let s:root_path = ''
let s:notify_callback = ''
let s:results = []
let s:current_path = ''

function! s:detect_root(srcpath)
  if s:root_path == ''
    for file in g:eslint_rcfiles
      let rc = fnamemodify(file, ':r')
      if stridx(rc, '.') == -1
        let path = finddir(rc, a:srcpath . ';')
        if path != ''
          let s:root_path = fnamemodify(path, ':p:h:h')
          break
        endif
      else
        let path = findfile(file, a:srcpath . ';')
        if path != ''
          let s:root_path = fnamemodify(path, ':p:h')
          break
        endif
      endif
    endfor
  endif
  return s:root_path
endfunction

function! s:detect_eslint_bin(srcpath)
  if g:eslint_path != ''
    return g:eslint_path
  endif
  if g:eslint_enable_eslint_d && executable('eslint_d')
    call s:detect_root(a:srcpath)
    let g:eslint_path = exepath('eslint_d')
    return g:eslint_path
  endif
  if executable('eslint') == 0
    let root_path = s:detect_root(a:srcpath)
    if root_path == ''
      return ''
    endif
    let root_path = fnamemodify(root_path, ':p')
    let g:eslint_path = exepath(root_path . 'node_modules/.bin/eslint')
  else
    let g:eslint_path = exepath('eslint')
  endif

  return g:eslint_path
endfunction

function s:show_verbose(msg)
  let length = len(a:msg)
  if &columns < 50
    echo printf('[ESlint] %s...', a:msg[0 : &columns - 14])
  else
    if length >= &columns - 50
      let verbose = a:msg[length - &columns + 50 :  length]
    else
      let verbose = a:msg
    endif
    echo printf('[ESlint] %s...%s', a:msg[0 : 36], verbose)
  endif
endfunction

function! s:parse(results)
  let qflist = []
  let outputs = []
  for k in a:results
    let messages = k['messages']
    let filename = k['filePath']
    for m in messages
      let line = m['line']
      let start = m['column']
      let text = m['message']

      call add(qflist, {
            \ 'filename': filename,
            \ 'lnum': line,
            \ 'col': start,
            \ 'vcol': 0,
            \ 'text': printf('[ESlint] %s (%s)', text, m['ruleId']),
            \ 'type': 'E'
            \})
    endfor

    if has_key(k, 'output')
      call add(outputs, k['output'])
    endif
  endfor

  return {'qflist': qflist, 'outputs': outputs }
endfunction

function! s:callback(ch, msg, mode) abort
  if g:eslint_verbose
    call s:show_verbose(a:msg)
  endif
  try
    let msg = json_decode(a:msg)
    let ret = s:parse(msg)
    if type(s:notify_callback) == 2
      let Callback = function(s:notify_callback)
      call Callback(ret['qflist'], a:msg)
    else
      call setqflist(ret['qflist'], a:mode)
    endif
  catch
  endtry
endfunction

function! s:callback_fix(ch, msg, mode, winsaveview)
  if g:eslint_enable_eslint_d && executable('eslint_d')
    call add(s:results, a:msg)
  else
    try
      let msg = json_decode(a:msg)
      let ret = s:parse(msg)
      let lines = split(ret['outputs'][0], "\n")
      call setqflist(ret['qflist'], a:mode)

      let view = winsaveview()
      silent execute '% delete'
      call setline(1, lines)
      call winrestview(view)
    catch
    endtry
  endif
endfunction

function! s:restore() abort
  set autochdir
  execute ':lcd ' . s:current_path
endfunction

function! s:exit_callback(ch, msg) abort
  if g:eslint_verbose
    echo ''
  endif
  if has_key(g:eslint_callbacks, 'after_run')
    call g:eslint_callbacks['after_run'](a:ch, a:msg)
  endif
  call s:restore()
endfunction

function! s:exit_fix_callback(ch, msg, winsaveview) abort
  if g:eslint_enable_eslint_d && executable('eslint_d')
    let view = winsaveview()
    silent execute '% delete'
    call setline(1, s:results)
    call winrestview(view)
    let s:results = []
  endif
  if has_key(g:eslint_callbacks, 'after_run')
    call g:eslint_callbacks['after_run'](a:ch, a:msg)
  endif
  call s:restore()
endfunction

function! s:send(cmd, mode, autofix, winsaveview) abort
  if exists('+autochdir') && &autochdir
    let s:current_path = getcwd()
    set noautochdir
    execute ':lcd ' . s:root_path
  endif

  let bufnum = bufnr('%')
  let input = join(getbufline(bufnum, 1, '$'), "\n") . "\n"
  if a:autofix == 0
    let s:job = job_start(a:cmd, {
          \ 'callback': {c, m -> s:callback(c, m, a:mode)},
          \ 'exit_cb': {c, m -> s:exit_callback(c, m)},
          \ 'in_mode': 'nl',
          \ })
  else
    let s:job = job_start(a:cmd, {
          \ 'callback': {c, m -> s:callback_fix(c, m, a:mode, a:winsaveview)},
          \ 'exit_cb': {c, m -> s:exit_fix_callback(c, m, a:winsaveview)},
          \ 'in_mode': 'nl',
          \ })
  endif

  let channel = job_getchannel(s:job)
  if ch_status(channel) ==# 'open'
    call ch_sendraw(channel, input)
    call ch_close_in(channel)
  endif
endfunction

function! eslint#register_notify(callback) abort
  let s:notify_callback = a:callback
endfunction

function! eslint#run(...) abort
  if exists('s:job') && job_status(s:job) != 'stop'
    call job_stop(s:job)
  endif

  let mode = a:0 > 0 ? a:1 : 'r'
  let file = expand('%:p')
  let bin = s:detect_eslint_bin(file)
  let enable_cache = g:eslint_enable_cache == 1 ? '--cache' : ''
  if g:eslint_verbose
    let cmd = printf(
      \ '%s %s --debug --stdin --stdin-filename %s --format json --ext %s',
      \ bin,
      \ enable_cache,
      \ file,
      \ g:eslint_ext
      \ )
  else
    let cmd = printf(
      \ '%s %s --stdin --stdin-filename %s --format json --ext %s',
      \ bin,
      \ enable_cache,
      \ file,
      \ g:eslint_ext
      \ )
  endif

  call s:send(cmd, mode, 0, {})
endfunction

function! eslint#fix(...) abort
 if exists('s:job') && job_status(s:job) != 'stop'
    call job_stop(s:job)
  endif
  let mode = a:0 > 0 ? a:1 : 'r'

  let winsaveview = winsaveview()
  let file = expand('%:p')
  let bin = s:detect_eslint_bin(file)
  if g:eslint_enable_eslint_d && executable('eslint_d')
    let cmd = printf(
      \ '%s --stdin-filename %s --stdin --fix-to-stdout --format json --ext %s ',
      \ bin,
      \ file,
      \ g:eslint_ext
      \ )
  else
    let cmd = printf(
      \ '%s --stdin --stdin-filename %s --format json --ext %s --fix-dry-run',
      \ bin,
      \ file,
      \ g:eslint_ext
      \ )
  endif
  call s:send(cmd, mode, 1, winsaveview)
endfunction

function! eslint#all(...) abort
  if exists('s:job') && job_status(s:job) != 'stop'
    call job_stop(s:job)
  endif

  let mode = a:0 > 0 ? a:1 : 'r'
  let file = expand('%:p')

  let root_path = fnamemodify(trim(s:detect_root(file), '/'), ':p:h')
  let bin = printf('/%s/node_modules/.bin/eslint', root_path)

  let enable_cache = g:eslint_enable_cache == 1 ? '--cache' : ''
  if g:eslint_verbose
    let cmd = printf(
      \ '%s %s --cache-location /%s/.eslintcache --debug --format json --quiet --ext %s "/%s/**/*.ts{,x}"',
      \ bin,
      \ enable_cache,
      \ root_path,
      \ g:eslint_ext,
      \ root_path
      \ )
  else
    let cmd = printf(
      \ '%s %s --cache-location /%s/.eslintcache --format json --quiet --ext %s "/%s/**/*.ts{,x}"',
      \ bin,
      \ enable_cache,
      \ root_path,
      \ g:eslint_ext,
      \ root_path
      \ )
  endif

  call s:send(cmd, mode, 0, {})
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
