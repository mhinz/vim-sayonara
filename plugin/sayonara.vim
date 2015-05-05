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
    call self.preserve_window()
    if has_key(self, 'scratch_buffer_number')
          \ && bufexists(self.target_buffer_number)
          \ && self.target_buffer_number != self.scratch_buffer_number
      execute 'silent bdelete!' self.target_buffer_number
    endif
  else
    execute 'silent bdelete!' self.target_buffer_number
  endif
endfunction

" s:prototype.handle_modified_buffer() {{{1
function! s:prototype.handle_modified_buffer()
  if getbufvar(self.target_buffer_number, '&modified')
    call inputsave()
    let answer = input('No changes since last write. Really delete it? [y/n]: ')
    call inputrestore()
    if answer != 'y'
      return 'return'
    endif
  endif
  return ''
endfunction

" s:prototype.handle_usecases() {{{1
function! s:prototype.handle_usecases()
  let buftype   = getbufvar(self.target_buffer_number, '&buftype')
  let filetype  = getbufvar(self.target_buffer_number, '&filetype')
  let buflisted = getbufvar(self.target_buffer_number, '&buflisted')
  let nlisted   = len(filter(range(1, bufnr('$')), 'buflisted(v:val)'))

  if (buftype == 'nofile') && (filetype == 'vim')  " cmdline window
    quit
  elseif buftype == 'quickfix'                     " quickfix window
    cclose
  elseif ((buftype =~ 'nofile') && (nlisted > 0))
        \ || !buflisted                            " probably a plugin buffer
    call self.delete_buffer()
  elseif nlisted > 1                               " multiple buffers
    call self.delete_buffer()
  elseif self.do_preserve                          " 0 or 1 buffer + preserve
    call self.delete_buffer()
  else                                             " 0 or 1 buffer
    quit!
  endif
endfunction

" s:prototype.preserve_window() {{{1
function! s:prototype.preserve_window()
  let win = bufwinnr(self.target_buffer_number)
  if win == -1
    return
  endif

  let self.original_window = winnr()
  execute win .'wincmd w'

  let altbufnr        = bufnr('#')
  let visible_buffers = filter(tabpagebuflist(), 'v:val != '. win)
  let valid_buffers   = filter(range(1, bufnr('$')),
        \ 'index(visible_buffers, v:val) == -1 && buflisted(v:val) && v:val != self.target_buffer_number')

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
    buffer #
  endif

  execute self.original_window .'wincmd w'
endfunction

" s:extract_buffer_number() {{{1
function! s:extract_buffer_number(buffer)
  " NOTE: 'buffer' is of type string.
  let bufnr = str2nr(a:buffer)
  " Priorize buffer 5 over a buffer named '5'. If you want the latter,
  " use :Sayonara '5' (the single quotes are important here).
  return bufnr(bufnr ? bufnr : a:buffer)
endfunction

" s:sayonara() {{{1
function! s:sayonara(do_preserve, buffer)
  let bufnr = s:extract_buffer_number(a:buffer)
  if bufnr == -1
    echohl ErrorMsg
    echomsg 'No such buffer: '. a:buffer
    echohl NONE
    return
  endif
  let instance = extend(s:prototype, {
        \ 'target_buffer_number': bufnr,
        \ 'do_preserve': a:do_preserve,
        \ })
  execute instance.handle_modified_buffer()
  call instance.handle_usecases()
endfunction
" }}}

command! -nargs=? -complete=buffer -bang -bar Sayonara
      \ call s:sayonara(<bang>0, <q-args>)
