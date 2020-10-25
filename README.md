# vim-eslint

![build](https://github.com/heavenshell/vim-eslint/workflows/build/badge.svg)

An asynchronous Eslint(@typescript-eslint) for Vim.

Can use with TypeScript + Eslint + Prettier.

![Realtime style check](./assets/vim-eslint.gif)

## Invoke manually

Open TypeScript file and just execute `:Eslint`.

## Automatically lint on save

```viml
autocmd BufWritePost *.ts,*.tsx call eslint#run('a', win_getid())
```

## Autofix

Execute `:EslintFix` and automatically fix.

## Integrate with Tsuquyomi

You can use Tsuquyomi's `TsuAsyncGeterr` and vim-eslint.
Set followings to your vimrc.

```viml
augroup typescript
  function! s:typescript_after(ch, msg)
    let cnt = len(getqflist())
    if cnt > 0
      echomsg printf('[TypeScript] %s errors', cnt)
    endif
  endfunction

  function! s:eslint_callback(qflist, mode)
    let list = getqflist() + a:qflist
    call setqflist(list, 'r')
  endfunction

  let g:eslint_callbacks = {
    \ 'after_run': function('s:typescript_after')
    \ }

  let g:tsuquyomi_disable_quickfix = 1

  function! s:ts_callback(qflist) abort
    call setqflist(a:qflist)
    let list = a:qflist + getqflist()
    call setqflist(list, 'r')
  endfunction

  function! s:check()
    let winid = win_getid()
    call setqflist([], 'r')
    call tsuquyomi#registerNotify(function('s:ts_callback'), 'diagnostics')
    call tsuquyomi#asyncCreateFixlist()

    call eslint#register_notify(function('s:eslint_callback'))
    call eslint#run('a', winid)
  endfunction

  autocmd InsertLeave,BufWritePost *.ts,*.tsx silent! call s:check()
augroup END
```

## License

New BSD License
