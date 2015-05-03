" vim: et sw=2 sts=2

" Plugin:      https://github.com/mhinz/vim-sayonara
" Description: Sane window/buffer closing.
" Maintainer:  Marco Hinz <http://github.com/mhinz>

if exists('g:loaded_sayoara') || &compatible
  finish
endif
let g:loaded_sayoara = 1

" s:delete_buffer() {{{1
function! s:delete_buffer(bufnr, preserve_window)
  if a:preserve_window
    let scratchnr = s:preserve_window(a:bufnr)
    if a:bufnr != scratchnr
      execute 'silent bdelete!' a:bufnr
    endif
  else
    execute 'silent bdelete!' a:bufnr
  endif
endfunction

" s:handle_modified_buffer() {{{1
function! s:handle_modified_buffer(bufnr)
  if getbufvar(a:bufnr, '&modified')
    call inputsave()
    let answer = input('No changes since last write. Really delete it? [y/n]: ')
    call inputrestore()
    if answer != 'y'
      return 'return'
    endif
  endif
  return ''
endfunction

" s:preserve_window() {{{1
function! s:preserve_window(bufnr)
  let win = bufwinnr(a:bufnr)
  if win == -1
    return
  endif

  let scratchnr = -1
  let origwin   = winnr()
  execute win .'wincmd w'

  let altbufnr        = bufnr('#')
  let visible_buffers = filter(tabpagebuflist(), 'v:val != '. win)
  let valid_buffers   = filter(range(1, bufnr('$')),
        \ 'index(visible_buffers, v:val) == -1 && buflisted(v:val) && v:val != a:bufnr')

  if empty(valid_buffers)
    let scratchnr = s:create_scratch_buffer()
  elseif index(valid_buffers, altbufnr) == -1
    " get previous valid buffer
    let bufs = []
    for buf in valid_buffers
      if buf < a:bufnr
        let bufs += [ buf ]
        call insert(bufs, buf, 0)
      else
        call add(bufs, buf)
      endif
    endfor
    execute 'buffer!' bufs[0]
  else
    buffer #
  endif

  execute origwin .'wincmd w'
  return scratchnr
endfunction

" s:create_scratch_buffer() {{{1
function! s:create_scratch_buffer()
  enew!
  setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile
  return bufnr('%')
endfunction

" s:extract_buffer_number() {{{1
function! s:extract_buffer_number(buffer)
  " NOTE: 'buffer' is of type string.
  let bufnr = str2nr(a:buffer)
  " Priorize buffer 5 over a buffer named '5'. If you want the latter,
  " use :Sayonara '5' (the single quotes are important here).
  return bufnr(bufnr ? bufnr : a:buffer)
endfunction

" s:bailout() {{{1
function! s:bailout(msg)
  echohl ErrorMsg
  echomsg a:msg
  echohl NONE
  return 'return'
endfunction

" s:handle_usecases() {{{1
function! s:handle_usecases(bufnr, preserve_window)
  let buftype  = getbufvar(a:bufnr, '&buftype')
  let filetype = getbufvar(a:bufnr, '&filetype')
  let nlisted  = len(filter(range(1, bufnr('$')), 'buflisted(v:val)'))

  if (buftype == 'nofile') && (filetype == 'vim')  " cmdline window
    quit
  elseif buftype == 'quickfix'                     " quickfix window
    cclose
  elseif (buftype == 'nofile') && (nlisted > 0)    " probably a plugin buffer
    call s:delete_buffer(a:bufnr, a:preserve_window)
  elseif nlisted > 1                               " multiple buffers
    call s:delete_buffer(a:bufnr, a:preserve_window)
  elseif a:preserve_window                         " 0 or 1 buffer + preserve
    call s:delete_buffer(a:bufnr, a:preserve_window)
  else                                             " 0 or 1 buffer
    quit!
  endif
endfunction

" s:sayonara() {{{1
function! s:sayonara(preserve_window, buffer)
  let bufnr = s:extract_buffer_number(a:buffer)
  if bufnr == -1
    execute s:bailout('No such buffer: '. a:buffer)
  endif
  execute s:handle_modified_buffer(bufnr)
  call s:handle_usecases(bufnr, a:preserve_window)
endfunction
" }}}

command! -nargs=? -complete=buffer -bang -bar Sayonara
      \ call s:sayonara(<bang>0, <q-args>)
