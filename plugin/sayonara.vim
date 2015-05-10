" vim: et sw=2 sts=2

" Plugin:      https://github.com/mhinz/vim-sayonara
" Description: Sane window/buffer closing.
" Maintainer:  Marco Hinz <http://github.com/mhinz>

if exists('g:loaded_sayoara') || &compatible
  finish
endif
let g:loaded_sayoara = 1

let s:prototype = {}

" s:prototype.create_scratch_buffer() {{{1
function! s:prototype.create_scratch_buffer()
  enew!
  let self.scratch_buffer_number = bufnr('%')
  setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile
endfunction

" s:prototype.delete_buffer() {{{1
function! s:prototype.delete_buffer()
  if self.do_preserve
    call self.preserve_current_window()
  else
    if (tabpagenr('$') > 1) && (winnr('$') == 1)
      call self.preserve_current_window()
    else
      lclose
    endif
  endif
  " After preserve_current_window(), the target buffer might not exist anymore
  " (bufhidden=delete).
  if bufloaded(self.target_buffer_number)
    if has_key(self, 'scratch_buffer_number')
          \ && self.scratch_buffer_number == self.target_buffer_number
      return
    endif
    execute 'silent bdelete!' self.target_buffer_number
  endif
endfunction

" s:prototype.handle_modified_buffer() {{{1
function! s:prototype.handle_modified_buffer()
  if &modified
    echo 'There are unsaved changes. Delete anyway? [y/n]: '
    if nr2char(getchar()) != 'y'
      redraw!
      return 'return'
    endif
  endif
  return ''
endfunction

" s:prototype.handle_usecases() {{{1
function! s:prototype.handle_usecases()
  let nlisted = len(filter(range(1, bufnr('$')), 'buflisted(v:val)'))

  if (&buftype == 'nofile') && (&filetype == 'vim')
    quit                       " cmdline window
  elseif &buftype == 'quickfix'
    quit                       " qf or loc list
  elseif (!&buflisted || (&buftype == 'nofile')) && (nlisted > 0)
    call self.delete_buffer()  " probably a plugin buffer
  elseif nlisted > 1
    call self.delete_buffer()  " multiple buffers
  elseif self.do_preserve
    call self.delete_buffer()  " 0 or 1 buffer + preserve
  else
    quit!                      " 0 or 1 buffer
  endif
endfunction

" s:prototype.preserve_current_window() {{{1
function! s:prototype.preserve_current_window()
  let altbufnr = bufnr('#')
  let valid_buffers = filter(range(1, bufnr('$')),
        \ 'buflisted(v:val) && v:val != self.target_buffer_number')

  if empty(valid_buffers)
    call self.create_scratch_buffer()
  elseif index(valid_buffers, altbufnr) == -1
    " get previous valid buffer
    let bufs = []
    for buf in valid_buffers
      if buf < self.target_buffer_number
        call insert(bufs, buf, 0)
      else
        call add(bufs, buf)
      endif
    endfor
    execute 'buffer!' bufs[0]
  else
    buffer! #
  endif
endfunction

" s:prototype.preserve_all_but_current_windows() {{{1
function! s:prototype.preserve_all_but_current_windows()
  let lr = &lazyredraw
  set lazyredraw

  let source_window = [tabpagenr(), winnr()]

  for tabpage in range(1, tabpagenr('$'))
    execute 'tabnext' tabpage
    for window in range(1, winnr('$'))
      if winbufnr(window) == self.target_buffer_number
            \ && ((tabpage != source_window[0]) || (window != source_window[1]))
        execute window .'wincmd w'
        call self.preserve_current_window()
      endif
    endfor
  endfor

  execute 'tabnext' source_window[0]
  execute source_window[1] .'wincmd w'

  let &lazyredraw = lr
endfunction

" s:sayonara() {{{1
function! s:sayonara(do_preserve)
  let instance = extend(s:prototype, {
        \ 'do_preserve': a:do_preserve,
        \ 'target_buffer_number': bufnr('%'),
        \ })
  execute instance.handle_modified_buffer()
  call instance.preserve_all_but_current_windows()
  call instance.handle_usecases()
endfunction
" }}}

command! -nargs=0 -complete=buffer -bang -bar Sayonara call s:sayonara(<bang>0)
