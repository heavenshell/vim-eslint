" File: eslint.vim
" Author: Shinya Ohyanagi <sohyanagi@gmail.com>
" WebPage: http://github.com/heavenshell/eim-tslint
" Description: Vim plugin for tslint
" License: BSD, see LICENSE for more details.
let s:save_cpo = &cpo
set cpo&vim

if get(b:, 'loaded_eslint')
  finish
endif

" version check
if !has('channel') || !has('job')
  echoerr '+channel and +job are required for eslint.vim'
  finish
endif

command! -buffer Eslint    :call eslint#run()
command! -buffer EslintFix :call eslint#fix()
noremap <silent> <buffer> <Plug>(Eslint) :Eslint<CR>
noremap <silent> <buffer> <Plug>(EslintFix) :EslintFix<CR>

let b:loaded_eslint = 1

let &cpo = s:save_cpo
unlet s:save_cpo

