function! s:nr2hex(nr) abort
  let l:n = a:nr
  let l:r = ''
  while l:n
    let l:r = '0123456789ABCDEF'[l:n % 16] . l:r
    let l:n = l:n / 16
  endwhile
  return l:r
endfunction

function! s:urlencode(text) abort
  let l:ret = ''
  let l:text = iconv(a:text, &enc, 'utf-8')
  let l:len = strlen(l:text)
  let l:i = 0
  while l:i < l:len
    let l:ch = l:text[i]
    if l:ch =~# '[0-9A-Za-z-._~]'
      let l:ret .= l:ch
    else
      let l:ret .= '%' . substitute('0' . s:nr2hex(char2nr(l:ch)), '^.*\(..\)$', '\1', '')
    endif
    let l:i = l:i + 1
  endwhile
  return l:ret
endfunction

" Get comment text at cursor position
function! s:get_comment_at_cursor() abort
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
    let l:start_col = l:i == l:line ? l:col : 1
    let l:end_col = l:i == l:line ? l:col : len(l:text)

    while l:start_col > 1
      let l:synid = synID(l:i, l:start_col - 1, 1)
      let l:synname = synIDattr(l:synid, 'name')
      if l:synname !~? 'comment'
        break
      endif
      let l:start_col -= 1
    endwhile

    while l:end_col < len(l:text)
      let l:synid = synID(l:i, l:end_col + 1, 1)
      let l:synname = synIDattr(l:synid, 'name')
      if l:synname !~? 'comment'
        break
      endif
      let l:end_col += 1
    endwhile

    if l:start_col <= l:end_col
      call add(l:lines, strpart(l:text, l:start_col - 1, l:end_col - l:start_col + 1))
    endif
  endfor

  let l:comment = join(l:lines, "\n")
  let l:comment = trim(l:comment)

  " Detect comment type and strip markers
  if l:comment =~# '^/\*'
    " Block comment /* ... */
    let l:comment = substitute(l:comment, '^/\*\+\s*', '', '')
    let l:comment = substitute(l:comment, '\s*\*\+/$', '', '')
    if get(g:, 'rosetta_strip_c_style', 0)
      " Strip leading * from each line
      let l:comment = substitute(l:comment, '\n\s*\*\+\s*', '\n', 'g')
    endif
  elseif l:comment =~# '^//'
    " Line comment //
    let l:comment = substitute(l:comment, '^\(//\+\s*\)\|\n//\+\s*', '\n', 'g')
    let l:comment = substitute(l:comment, '^\n', '', '')
  elseif l:comment =~# '^#'
    " Line comment #
    let l:comment = substitute(l:comment, '^\(#\+\s*\)\|\n#\+\s*', '\n', 'g')
    let l:comment = substitute(l:comment, '^\n', '', '')
  elseif l:comment =~# '^"'
    " Line comment "
    let l:comment = substitute(l:comment, '^\("\s*\)\|\n"\s*', '\n', 'g')
    let l:comment = substitute(l:comment, '^\n', '', '')
  endif

  if get(g:, 'rosetta_trim_spaces', 1)
    let l:comment = substitute(l:comment, '\s\+', ' ', 'g')
  endif
  let l:comment = trim(l:comment)

  return l:comment
endfunction

function! s:translate_api(source_lang, target_lang, text, callback) abort
  if empty(a:text)
    call a:callback([])
    return
  endif
  let l:encoded_text = s:urlencode(a:text)
  let l:url = 'https://translate.googleapis.com/translate_a/single?client=gtx&sl=' . a:source_lang . '&tl=' . a:target_lang . '&dt=t&q=' . l:encoded_text

  let l:out = []
  let l:job = job_start(['curl', '-s', l:url], {
        \ 'out_cb': {ch, msg -> add(l:out, msg)},
        \ 'close_cb': {ch -> a:callback(l:out)},
        \ })
endfunction

function! s:translate_text(text, callback, ...) abort
  let l:source_lang = 'auto'
  let l:target_lang = a:0 > 0 ? a:1 : get(g:, 'rosetta_target_lang', 'ja')

  call s:translate_api(l:source_lang, l:target_lang, a:text, {out -> s:parse_translation(out, a:callback)})
endfunction

function! s:parse_translation(out, callback) abort
  try
    let l:response = join(a:out, '')
    let l:items = json_decode(l:response)
    if type(l:items) != v:t_list || empty(l:items) || type(l:items[0]) != v:t_list
      call a:callback('Translation failed')
      return
    endif

    let l:result = ''
    for l:item in l:items[0]
      if type(l:item) == v:t_list && len(l:item) > 0 && type(l:item[0]) == v:t_string
        let l:result .= l:item[0]
      endif
    endfor

    call a:callback(empty(l:result) ? 'Translation failed' : l:result)
  catch
    call a:callback('Translation parse error')
  endtry
endfunction

function! s:show_translation_popup(text) abort
  if exists('s:popup_id') && popup_getpos(s:popup_id) != {}
    call popup_close(s:popup_id)
  endif

  let l:max_width = get(g:, 'rosetta_popup_max_width', 80)
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

" ============================================================================
" Comment Translation Feature
" ============================================================================
function! rosetta#translate_at(select) abort
  if a:select
    let l:saved_reg = @"
    silent! normal! gv""y
    let l:word = @"
    let @" = l:saved_reg
  else
    let l:word = expand('<cword>')
  endif
  call s:translate_text(l:word, {translation -> s:show_translation_popup(translation)})
endfunction

" Main function: translate comment at cursor
function! rosetta#translate_comment() abort
  let l:comment = s:get_comment_at_cursor()

  if empty(l:comment)
    echo 'No comment under cursor'
    return
  endif

  call s:translate_text(l:comment, {translation -> s:show_translation_popup(translation)})
endfunction

" Auto-translate comment on cursor hold
let s:translate_comment_last = ''

function! rosetta#translate_comment_auto() abort
  let l:comment = s:get_comment_at_cursor()
  if empty(l:comment)
    if exists('s:popup_id') && popup_getpos(s:popup_id) != {}
      call popup_close(s:popup_id)
    endif
    let s:translate_comment_last = ''
    return
  endif
  if l:comment ==# s:translate_comment_last
    return
  endif
  let s:translate_comment_last = l:comment
  call s:translate_text(l:comment, {translation -> s:show_translation_popup(translation)})
endfunction

" ============================================================================
" Name Completion Feature
" ============================================================================

function! s:to_snake_case(text) abort
  let l:text = tolower(a:text)
  let l:text = substitute(l:text, '[^a-z0-9]\+', '_', 'g')
  let l:text = substitute(l:text, '^_\+\|_\+$', '', 'g')
  return l:text
endfunction

function! s:to_camel_case(text, lower_first) abort
  let l:words = split(a:text, '[-_ ]\+')
  let l:camel = []
  for l:i in range(len(l:words))
    let l:word = l:words[l:i]
    if l:i == 0 && !a:lower_first
      call add(l:camel, tolower(l:word))
    else
      call add(l:camel, toupper(l:word[0]) . tolower(l:word[1:]))
    endif
  endfor
  return join(l:camel, '')
endfunction

function! rosetta#complete_name() abort
  let l:line = getline('.')
  let l:start = col('.') - 1
  while l:start > 0 && l:line[l:start - 1] =~# '\S'
    let l:start -= 1
  endwhile
  let l:base = strpart(l:line, l:start, col('.') - 1 - l:start)

  let l:source_lang = get(g:, 'rosetta_target_lang', 'ja')
  let l:target_lang = 'auto'

  call s:translate_api(l:source_lang, l:target_lang, l:base, {out -> s:complete_name_callback(out, l:start)})
  return ''
endfunction

function! s:complete_name_callback(out, start) abort
  try
    let l:response = join(a:out, '')
    let l:items = json_decode(l:response)
    if type(l:items) != v:t_list || empty(l:items) || type(l:items[0]) != v:t_list
      return
    endif

    let l:completions = []
    for l:item in l:items[0]
      if type(l:item) == v:t_list && len(l:item) > 0 && type(l:item[0]) == v:t_string
        let l:translation = l:item[0]
        if empty(l:translation)
          continue
        endif
        let l:snake = s:to_snake_case(l:translation)
        call add(l:completions, l:snake)
        call add(l:completions, toupper(l:snake))
        call add(l:completions, s:to_camel_case(l:translation, 0))
        call add(l:completions, s:to_camel_case(l:translation, 1))
      endif
    endfor
    call complete(a:start + 1, uniq(l:completions))
  catch
  endtry
endfunction
