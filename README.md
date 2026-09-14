# Dotfiles

Zsh, Neovim and tmux configuration for Linux.

## Install

```sh
git clone https://github.com/yanis9zz/config.git ~/dotfiles
cd ~/dotfiles
./setup.sh bootstrap
exec zsh
```

Installs missing dependencies and backs up existing configurations.

## Update

```sh
cd ~/dotfiles
git pull --ff-only
./setup.sh update
```

Check your setup with `./setup.sh doctor`. More commands: `./setup.sh --help`.
