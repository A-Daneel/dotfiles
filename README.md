# dotfiles

Personal dotfiles, managed with [GNU stow](https://www.gnu.org/software/stow/).

## Usage

```sh
make check    # dry-run the stow symlinks
make install  # create the symlinks
make delete   # remove the symlinks
```

## Neovim

The Neovim config tracks the `main` branch of
[`nvim-treesitter`](https://github.com/nvim-treesitter/nvim-treesitter), which
requires **Neovim 0.12+** and compiles parsers using the external
[`tree-sitter` CLI](https://github.com/tree-sitter/tree-sitter).

The config self-provisions the CLI through [mason](https://github.com/mason-org/mason.nvim)
on first launch. If that fails (or you prefer to manage it yourself), install it
via your package manager and run `:TSUpdate`, for example:

```sh
# any one of the following
cargo install tree-sitter-cli
brew install tree-sitter
pacman -S tree-sitter-cli
```

> Note: install the CLI via a package manager or cargo, **not** npm.
