# Dotfiles

Zsh, Neovim and tmux for Ubuntu/Debian and WSL. Supports x86_64 and ARM64.

## Install

```sh
sudo apt-get update
sudo apt-get install --yes git ca-certificates
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
