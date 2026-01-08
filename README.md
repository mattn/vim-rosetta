# vim-comment-translate

A Vim plugin that translates code comments under the cursor using Google Translate API.

## Features

- Automatically detects comments at cursor position
- Supports multi-line comments
- Shows translation in a popup window
- Optional auto-translation on cursor hold
- Works with various comment styles (`//`, `/* */`, `#`, `"`)

## Installation

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'mattn/vim-comment-translate'
```

## Requirements

- Vim 8.1+ with `+popup` feature
- `curl` command

## Usage

### Manual Translation

Place your cursor on a comment and run:

```vim
:CommentTranslate
```

Or use the default mapping:

```vim
<Leader>ct
```

### Auto Translation

Enable automatic translation when cursor stops on a comment:

```vim
let g:comment_translate_auto = 1
```

## Configuration

### Target Language

Set the target language for translation (default: `ja` for Japanese):

```vim
let g:comment_translate_target_lang = 'en'
```

Supported language codes: `en`, `ja`, `zh-CN`, `ko`, `es`, `fr`, `de`, etc.

### Popup Window Width

Customize the maximum width of the popup window (default: 80):

```vim
let g:comment_translate_popup_max_width = 100
```

### Trim Spaces

Control whether to collapse multiple spaces into single space (default: 1):

```vim
let g:comment_translate_trim_spaces = 0  " Keep original spacing
```

### Custom Key Mapping

Disable the default mapping and set your own:

```vim
nmap <C-t> <Plug>(comment-translate)
```

## License

MIT

## Author

Yasuhiro Matsumoto (a.k.a. mattn)
