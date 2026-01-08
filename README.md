# vim-rosetta

A Vim plugin that provides translation features for code comments and variable naming using Google Translate API.

## Features

- **Comment Translation**: Translate code comments under the cursor to any language
- **Auto Translation**: Automatically translate comments on cursor hold
- **Variable Name Completion**: Japanese to English translation for variable naming (snake_case, UPPER_CASE, camelCase)
- Supports multi-line comments
- Works with various comment styles (`//`, `/* */`, `#`, `"`)

## Installation

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'mattn/vim-rosetta'
```

### Using [dein.vim](https://github.com/Shougo/dein.vim)

```vim
call dein#add('mattn/vim-rosetta')
```

### Using Vim 8+ native package manager

```bash
mkdir -p ~/.vim/pack/plugins/start
cd ~/.vim/pack/plugins/start
git clone https://github.com/mattn/vim-rosetta.git
```

## Requirements

- Vim 8.1+ with `+popup` feature
- `curl` command

## Usage

### Comment Translation

Place your cursor on a comment and run:

```vim
:RosettaTranslateComment
```

Or use the default mapping:

```vim
<Leader>rt
```

### Auto Translation

Enable automatic translation when cursor stops on a comment:

```vim
let g:rosetta_translate_comment_auto = 1
```

## Configuration

### Comment Translation Settings

#### Target Language

Set the target language for translation (default: `ja` for Japanese):

```vim
let g:rosetta_target_lang = 'en'
```

Supported language codes: `en`, `ja`, `zh-CN`, `ko`, `es`, `fr`, `de`, etc.

#### Popup Window Width

Customize the maximum width of the popup window (default: 80):

```vim
let g:rosetta_popup_max_width = 100
```

#### Trim Spaces

Control whether to collapse multiple spaces into single space (default: 1):

```vim
let g:rosetta_trim_spaces = 0  " Keep original spacing
```

#### Strip C-Style Comment Asterisks

Remove leading `*` from each line in C-style block comments (default: 0):

```vim
let g:rosetta_strip_c_style = 1
```

Example:
```c
/*
 * hogehoge
 * hogehoge
 */
```
Will be extracted as:
```
hogehoge
hogehoge
```

#### Custom Key Mapping

Disable the default mapping and set your own:

```vim
nmap <C-t> <Plug>(rosetta-translate-comment)
```

### Variable Name Completion

Type Japanese text and press `<C-x><C-t>` to complete with English translation in multiple formats.

Example:
- Type: `こんにちは世界`
- Press: `<C-x><C-t>`
- Completion options:
  - `hello_world` (snake_case)
  - `HELLO_WORLD` (UPPER_CASE)
  - `helloWorld` (camelCase)

## How It Works

https://github.com/user-attachments/assets/5573ea0c-9e63-4fc5-9127-55de81b48861

### Comment Translation
1. Detects if the cursor is on a comment using Vim's syntax highlighting
2. Extracts the comment text (supports multi-line comments)
3. Sends the text to Google Translate API via `curl`
4. Displays the translation in a popup window

### Variable Name Completion
1. Extracts Japanese text before cursor
2. Translates to English using Google Translate API
3. Converts to multiple naming formats (snake_case, UPPER_CASE, camelCase)
4. Provides as completion candidates

## License

MIT

## Author

Yasuhiro Matsumoto (a.k.a. mattn)
