# Fugitive Delta
* [vim-fugitive](https://github.com/tpope/vim-fugitive) integration with [delta](https://github.com/dandavison/delta).

## Requirement
* neovim
* vim-fugitive
* delta or diff-highlight

## Installation
* Get delta installation file from its [release page](https://github.com/dandavison/delta/releases).
    * Alternatively, you can use `diff-highlight`, which is distributed with Git. See [setup diff-highlight](#setup-diff-highlight) for more information.
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


## Setup diff-highlight
* Alternatively, if you do not want to install git-delta, you can use diff-highlight, which is distributed with Git.
* Distributions like Ubuntu, for example, require you to take extra steps to make diff-highlight available in your path.
* You need to run the following commands to make it available:
```bash
cd /usr/share/doc/git/contrib/diff-highlight/
sudo make
sudo ln -s /usr/share/doc/git/contrib/diff-highlight/diff-highlight /usr/local/bin/diff-highlight
sudo chmod +x /usr/share/doc/git/contrib/diff-highlight/diff-highlight
```

* If you have both git-delta and diff-highlight available, you might need to force it to use diff-highlight by adding the following line to your Vim configuration:
```vim
let g:exe_fugitive_delta=2
```
* You can switch between the two in the current session by setting it to 1 for git-delta. You might want to do this to compare the two, as they have different highlighting behaviors.
