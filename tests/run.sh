#!/bin/sh
: "${VIM_EXE:=vim}"

# download test dependency if needed
if [[ ! -d "./vader.vim" ]]; then
  git clone https://github.com/junegunn/vader.vim.git vader.vim
fi

# Open vim with readonly mode just to execute all *.vader tests.
$VIM_EXE -Nu vimrc -c 'Vader! *.vader'
