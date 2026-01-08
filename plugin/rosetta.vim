command! RosettaTranslateComment call rosetta#translate_comment()
nnoremap <silent> <plug>(rosetta-translate-comment) :<C-u>call rosetta#translate_comment()<cr>
if !hasmapto('<plug>(rosetta-translate-comment)')
  nmap <Leader>tc <plug>(rosetta-translate-comment)
endif

command! RosettaTranslateAt call rosetta#translate_at(0)
nnoremap <silent> <plug>(rosetta-translate-at) :<C-u>call rosetta#translate_at(0)<cr>
xnoremap <silent> <plug>(rosetta-translate-at) :<C-u>call rosetta#translate_at(1)<cr>
if !hasmapto('<plug>(rosetta-translate-at)')
  nmap <Leader>tt <plug>(rosetta-translate-at)
  xmap <Leader>tt <plug>(rosetta-translate-at)
endif

command! -range=% RosettaTranslateBuffer <line1>,<line2>call rosetta#translate_buffer()

if get(g:, 'rosetta_translate_comment_auto', 0)
  augroup RosettaTranslateComment
    autocmd!
    autocmd CursorHold,CursorHoldI * call rosetta#translate_comment_auto()
  augroup END
endif

inoremap <silent> <plug>(rosetta-complete-name) <c-r>=rosetta#complete_name()<cr>
if !hasmapto('<plug>(rosetta-complete-name)')
  imap <c-x><c-t> <plug>(rosetta-complete-name)
endif
