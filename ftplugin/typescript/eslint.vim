" File: eslint.vim
" Author: Shinya Ohyanagi <sohyanagi@gmail.com>
" WebPage: http://github.com/heavenshell/vim-eslint
" Description: Vim plugin for eslint
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
command! -buffer EslintAll :call eslint#all()
noremap <silent> <buffer> <Plug>(Eslint) :Eslint<CR>
noremap <silent> <buffer> <Plug>(EslintFix) :EslintFix<CR>
noremap <silent> <buffer> <Plug>(EslintAll) :EslintAll<CR>

let b:loaded_eslint = 1

let &cpo = s:save_cpo
unlet s:save_cpo

