# Fugitive Delta
* [vim-fugitive](https://github.com/tpope/vim-fugitive) integration with [delta](https://github.com/dandavison/delta).

## Requirement
* neovim
* vim-fugitive
* delta

## Installation
* Get delta installation file from its [release page](https://github.com/dandavison/delta/releases).
* Installation using [Vundle.vim](https://github.com/VundleVim/Vundle.vim).
  ```vim
  Plugin 'tpope/vim-fugitive'
  Plugin 'farhanmustar/fugitive-delta.nvim'
  ```

* Installation using [vim-plug](https://github.com/junegunn/vim-plug).
  ```vim
  Plug 'tpope/vim-fugitive'
  Plug 'farhanmustar/fugitive-delta.nvim'
  ```

## Features
* fugitive-delta add extra highlight group to diff and git buffer.
* It use `FugitiveDeltaText` highlight group which is default to:
```vim
highlight link FugitiveDeltaText DiffText
```
* Demo below showing 'changed' is highlighted using `FugitiveDeltaText` highlight group.

[![Fugitive Delta Demo](https://github.com/farhanmustar/fugitive-delta.nvim/wiki/youtube.png)](https://www.youtube.com/watch?v=bLg0WqNUX5Y "Fugitive Delta Demo")
