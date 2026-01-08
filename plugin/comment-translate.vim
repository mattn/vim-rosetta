command! CommentTranslate call comment_translate#translate()
nnoremap <silent> <Plug>(comment-translate) :<C-u>call comment_translate#translate()<CR>
if !hasmapto('<Plug>(comment-translate)')
  nmap <Leader>ct <Plug>(comment-translate)
endif

if get(g:, 'comment_translate_auto', 0)
  augroup CommentTranslate
    autocmd!
    autocmd CursorHold,CursorHoldI * call comment_translate#auto_translate()
  augroup END
endif
