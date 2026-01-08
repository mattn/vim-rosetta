function! s:nr2hex(nr) abort
  let n = a:nr
  let r = ''
  while n
    let r = '0123456789ABCDEF'[n % 16] . r
    let n = n / 16
  endwhile
  return r
endfunction

function! s:urlencode(items) abort
  let ret = ''
  let items = iconv(a:items, &enc, 'utf-8')
  let len = strlen(items)
  let i = 0
  while i < len
    let ch = items[i]
    if ch =~# '[0-9A-Za-z-._~]'
      let ret .= ch
    else
      let ret .= '%' . substitute('0' . s:nr2hex(char2nr(ch)), '^.*\(..\)$', '\1', '')
    endif
    let i = i + 1
  endwhile
  return ret
endfunction

function! s:comment_at_cursor() abort
  let l:line = line('.')
  let l:col = col('.')
  let l:synid = synID(l:line, l:col, 1)
  let l:synname = synIDattr(l:synid, 'name')

  if l:synname !~? 'comment'
    return ''
  endif

  let l:start_line = l:line
  let l:end_line = l:line

  while l:start_line > 1
    let l:prev_line = l:start_line - 1
    let l:prev_text = getline(l:prev_line)
    if empty(trim(l:prev_text))
      break
    endif
    let l:first_col = match(l:prev_text, '\S') + 1
    if l:first_col == 0
      break
    endif
    let l:synid = synID(l:prev_line, l:first_col, 1)
    let l:synname = synIDattr(l:synid, 'name')
    if l:synname !~? 'comment'
      break
    endif
    let l:start_line = l:prev_line
  endwhile

  while l:end_line < line('$')
    let l:next_line = l:end_line + 1
    let l:next_text = getline(l:next_line)
    if empty(trim(l:next_text))
      break
    endif
    let l:first_col = match(l:next_text, '\S') + 1
    if l:first_col == 0
      break
    endif
    let l:synid = synID(l:next_line, l:first_col, 1)
    let l:synname = synIDattr(l:synid, 'name')
    if l:synname !~? 'comment'
      break
    endif
    let l:end_line = l:next_line
  endwhile

  let l:lines = []
  for l:i in range(l:start_line, l:end_line)
    let l:text = getline(l:i)
    let l:start_col = 1
    let l:end_col = len(l:text)

    while l:start_col <= len(l:text)
      let l:synid = synID(l:i, l:start_col, 1)
      let l:synname = synIDattr(l:synid, 'name')
      if l:synname =~? 'comment'
        break
      endif
      let l:start_col += 1
    endwhile

    while l:end_col > 0
      let l:synid = synID(l:i, l:end_col, 1)
      let l:synname = synIDattr(l:synid, 'name')
      if l:synname =~? 'comment'
        break
      endif
      let l:end_col -= 1
    endwhile

    if l:start_col <= l:end_col
      call add(l:lines, strpart(l:text, l:start_col - 1, l:end_col - l:start_col + 1))
    endif
  endfor

  let l:comment = join(l:lines, ' ')
  let l:comment = substitute(l:comment, '^\s*/\*\+\s*', '', '')
  let l:comment = substitute(l:comment, '\s*\*\+/\s*$', '', '')
  let l:comment = substitute(l:comment, '^\s*\*\+\s*', '', '')
  let l:comment = substitute(l:comment, '\s*\*\+\s*', ' ', 'g')
  let l:comment = substitute(l:comment, '^\s*//\+\s*', '', '')
  let l:comment = substitute(l:comment, '\s*//\+\s*', ' ', 'g')
  let l:comment = substitute(l:comment, '^\s*#\+\s*', '', '')
  let l:comment = substitute(l:comment, '\s*#\+\s*', ' ', 'g')
  let l:comment = substitute(l:comment, '^\s*"\s*', '', '')
  let l:comment = substitute(l:comment, '\s\+', ' ', 'g')
  let l:comment = substitute(l:comment, '^\s*', '', '')
  let l:comment = substitute(l:comment, '\s*$', '', '')

  return l:comment
endfunction

function! s:translate_text(text, ...) abort
  if empty(a:text)
    return ''
  endif
  let l:target_lang = a:0 > 0 ? a:1 : get(g:, 'comment_translate_target_lang', 'ja')
  let l:source_lang = 'auto'
  let l:encoded_text = s:urlencode(a:text)

  let l:url = 'https://translate.googleapis.com/translate_a/single?client=gtx&sl=' . l:source_lang . '&tl=' . l:target_lang . '&dt=t&q=' . l:encoded_text
  let l:response = system('curl -s "' . l:url . '"')
  if v:shell_error != 0
    return 'Translation error'
  endif

  try
    let l:json = json_decode(l:response)
    if type(l:json) != v:t_list || empty(l:json) || type(l:json[0]) != v:t_list
      return 'Translation failed'
    endif

    let l:result = ''
    for l:item in l:json[0]
      if type(l:item) == v:t_list && len(l:item) > 0 && type(l:item[0]) == v:t_string
        let l:result .= l:item[0]
      endif
    endfor

    return empty(l:result) ? 'Translation failed' : l:result
  catch
    return 'Translation parse error'
  endtry
endfunction

function! s:show_translation_popup(text) abort
  if exists('s:popup_id') && popup_getpos(s:popup_id) != {}
    call popup_close(s:popup_id)
  endif

  let l:max_width = get(g:, 'comment_translate_popup_max_width', 80)
  let l:lines = split(a:text, '\n')
  let s:popup_id = popup_atcursor(l:lines, {
        \ 'moved': 'any',
        \ 'padding': [0, 1, 0, 1],
        \ 'border': [1, 1, 1, 1],
        \ 'close': 'click',
        \ 'wrap': 1,
        \ 'maxwidth': l:max_width,
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
