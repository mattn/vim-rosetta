function! s:comment_at_cursor() abort
  let l:line = line('.')
  let l:col = col('.')
  let l:synid = synID(l:line, l:col, 1)
  let l:synname = synIDattr(l:synid, 'name')

  if l:synname !~? 'comment'
    return ''
  endif

  let l:text = getline(l:line)
  let l:start_col = l:col
  let l:end_col = l:col

  while l:start_col > 1
    let l:synid = synID(l:line, l:start_col - 1, 1)
    let l:synname = synIDattr(l:synid, 'name')
    if l:synname !~? 'comment'
      break
    endif
    let l:start_col -= 1
  endwhile

  while l:end_col < len(l:text)
    let l:synid = synID(l:line, l:end_col + 1, 1)
    let l:synname = synIDattr(l:synid, 'name')
    if l:synname !~? 'comment'
      break
    endif
    let l:end_col += 1
  endwhile

  let l:comment = strpart(l:text, l:start_col - 1, l:end_col - l:start_col + 1)
  let l:comment = substitute(l:comment, '^\s*//\s*', '', '')
  let l:comment = substitute(l:comment, '^\s*#\s*', '', '')
  let l:comment = substitute(l:comment, '^\s*/\*\s*', '', '')
  let l:comment = substitute(l:comment, '\s*\*/\s*$', '', '')
  let l:comment = substitute(l:comment, '^\s*"\s*', '', '')
  let l:comment = substitute(l:comment, '^\s*', '', '')
  let l:comment = substitute(l:comment, '\s*$', '', '')

  return l:comment
endfunction

function! s:translate_text(text, ...) abort
  if empty(a:text)
    return ''
  endif
  let l:target_lang = a:0 > 0 ? a:1 : g:comment_translate_target_lang
  let l:source_lang = 'auto'
  let l:encoded_text = substitute(a:text, ' ', '%20', 'g')
  let l:encoded_text = substitute(l:encoded_text, '"', '%22', 'g')
  let l:encoded_text = substitute(l:encoded_text, "'", '%27', 'g')
  let l:encoded_text = substitute(l:encoded_text, '&', '%26', 'g')

  let l:url = 'https://translate.googleapis.com/translate_a/single?client=gtx&sl=' . l:source_lang . '&tl=' . l:target_lang . '&dt=t&q=' . l:encoded_text
  let l:response = system('curl -s "' . l:url . '"')
  if v:shell_error != 0
    return 'Translation error'
  endif
  let l:result = matchstr(l:response, '^\\[\\[\\["\zs[^"]*')
  return empty(l:result) ? 'Translation failed' : l:result
endfunction

function! s:show_translation_popup(text) abort
  if exists('s:popup_id') && popup_getpos(s:popup_id) != {}
    call popup_close(s:popup_id)
  endif

  let l:lines = split(a:text, '\n')
  let s:popup_id = popup_atcursor(l:lines, {
        \ 'moved': 'any',
        \ 'padding': [0, 1, 0, 1],
        \ 'border': [1, 1, 1, 1],
        \ 'close': 'click',
        \ })
endfunction

function! comment_translate#translate() abort
  let l:comment = s:comment_at_cursor()

  if empty(l:comment)
    echo 'No comment under cursor'
    return
  endif

  let l:translation = s:translate_text(l:comment)
  call s:show_translation_popup(l:translation)
endfunction

let s:last_comment = ''

function! comment_translate#auto_translate() abort
  let l:comment = s:comment_at_cursor()
  if empty(l:comment)
    if exists('s:popup_id') && popup_getpos(s:popup_id) != {}
      call popup_close(s:popup_id)
    endif
    let s:last_comment = ''
    return
  endif
  if l:comment ==# s:last_comment
    return
  endif
  let s:last_comment = l:comment
  let l:translation = s:translate_text(l:comment)
  call s:show_translation_popup(l:translation)
endfunction
