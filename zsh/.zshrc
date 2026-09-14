# Powerlevel10k instant prompt must stay close to the top of this file.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export PATH="$HOME/.local/bin:$PATH"
typeset -g DOTFILES_ROOT="${${(%):-%x}:A:h:h}"
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
zstyle ':omz:update' mode disabled
plugins=(git)

if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
fi

alias ls='ls --color=auto'
alias t='tmux new-session -A -s main'

# Machine-specific aliases, secrets and optional runtimes belong here.
_dotfiles_load_nvm() { return 0; }
[[ ! -r "$HOME/.zshrc.local" ]] || source "$HOME/.zshrc.local"

# Only initialize NVM when the executables needed by Mason are missing.
nvim() {
  if (( ! $+commands[node] || ! $+commands[npm] )); then
    _dotfiles_load_nvm
  fi

  if [[ "${DOTFILES_MAXIMIZE_WINDOWS_TERMINAL:-0}" == 1 &&
        -t 0 && -t 1 && -z "${NVIM:-}" &&
        -n "${WT_SESSION:-}" &&
        -x "$(command -v powershell.exe 2>/dev/null)" &&
        -r "$DOTFILES_ROOT/scripts/windows-terminal-maximize.ps1" ]]; then
    powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass \
      -File "$(wslpath -w "$DOTFILES_ROOT/scripts/windows-terminal-maximize.ps1")" >/dev/null 2>&1 &!
  fi

  command nvim "$@"
}

[[ ! -f "$HOME/.p10k.zsh" ]] || source "$HOME/.p10k.zsh"
[[ ! -f "$HOME/.fzf.zsh" ]] || source "$HOME/.fzf.zsh"

if command -v atuin >/dev/null 2>&1; then
  eval "$(atuin init zsh --disable-up-arrow)"
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh --cmd cd)"
fi
