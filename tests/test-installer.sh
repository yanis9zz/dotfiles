#!/usr/bin/env bash

set -euo pipefail

REPOSITORY="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPOSITORY
TEST_ROOT="$(mktemp -d)"
readonly TEST_ROOT
readonly TEST_HOME="$TEST_ROOT/home"

cleanup() {
    if [[ "$TEST_ROOT" == /tmp/* && -d "$TEST_ROOT" ]]; then
        find "$TEST_ROOT" -depth -delete
    fi
}
trap cleanup EXIT

mkdir -p "$TEST_HOME/.config/nvim"
printf 'original zsh\n' >"$TEST_HOME/.zshrc"
printf 'original tmux\n' >"$TEST_HOME/.tmux.conf"
printf 'original nvim\n' >"$TEST_HOME/.config/nvim/init.lua"
printf 'blocking parent\n' >"$TEST_HOME/.config/nvim/lua"

# A fresh machine should receive one actionable prerequisite report before any deployment.
mkdir -p "$TEST_ROOT/minimal-bin"
for tool in bash dirname uname; do
    ln -s "$(command -v "$tool")" "$TEST_ROOT/minimal-bin/$tool"
done
if HOME="$TEST_HOME" PATH="$TEST_ROOT/minimal-bin" "$REPOSITORY/setup.sh" install >"$TEST_ROOT/preflight.log" 2>&1; then
    printf 'install unexpectedly accepted missing system prerequisites\n' >&2
    exit 1
fi
grep -Fq 'missing prerequisites: git zsh curl' "$TEST_ROOT/preflight.log"
grep -Fq './setup.sh bootstrap' "$TEST_ROOT/preflight.log"
[[ ! -e "$TEST_HOME/.config-backups" ]]
grep -Fqx 'original zsh' "$TEST_HOME/.zshrc"

if HOME="$TEST_HOME" PATH="$TEST_ROOT/minimal-bin" "$REPOSITORY/setup.sh" bootstrap >"$TEST_ROOT/bootstrap.log" 2>&1; then
    printf 'bootstrap unexpectedly accepted a system without apt\n' >&2
    exit 1
fi
grep -Fq 'bootstrap supports Debian/Ubuntu' "$TEST_ROOT/bootstrap.log"

HOME="$TEST_HOME" DOTFILES_TEST_MODE=1 "$REPOSITORY/setup.sh" install

[[ -L "$TEST_HOME/.zshrc" ]]
[[ -L "$TEST_HOME/.tmux.conf" ]]
[[ -L "$TEST_HOME/.config/nvim/init.lua" ]]
[[ -d "$TEST_HOME/.config/nvim/lua" ]]
[[ "$(readlink -f "$TEST_HOME/.zshrc")" == "$REPOSITORY/zsh/.zshrc" ]]
[[ "$(find "$TEST_HOME/.config-backups/yanis-config" -name manifest.tsv | wc -l)" -eq 1 ]]

# A second installation must keep the original backup and reuse the deployed links.
HOME="$TEST_HOME" DOTFILES_TEST_MODE=1 "$REPOSITORY/setup.sh" install
[[ "$(find "$TEST_HOME/.config-backups/yanis-config" -name manifest.tsv | wc -l)" -eq 1 ]]

HOME="$TEST_HOME" "$REPOSITORY/setup.sh" restore

[[ ! -L "$TEST_HOME/.zshrc" ]]
[[ ! -L "$TEST_HOME/.tmux.conf" ]]
[[ ! -L "$TEST_HOME/.config/nvim/init.lua" ]]
[[ -f "$TEST_HOME/.config/nvim/lua" ]]
grep -Fqx 'original zsh' "$TEST_HOME/.zshrc"
grep -Fqx 'original tmux' "$TEST_HOME/.tmux.conf"
grep -Fqx 'original nvim' "$TEST_HOME/.config/nvim/init.lua"
grep -Fqx 'blocking parent' "$TEST_HOME/.config/nvim/lua"

# Diagnostics must find managed executables even before ~/.local/bin is in PATH.
mkdir -p "$TEST_ROOT/doctor-home/.local/bin"
for tool in node npm nvim; do
    ln -s "$(command -v "$tool")" "$TEST_ROOT/doctor-home/.local/bin/$tool"
done
HOME="$TEST_ROOT/doctor-home" PATH=/usr/bin:/bin "$REPOSITORY/setup.sh" doctor >"$TEST_ROOT/doctor.log"
grep -Fq '0 failure(s)' "$TEST_ROOT/doctor.log"

# Helpers must resolve the clone location instead of assuming ~/config.
mkdir -p "$TEST_ROOT/renamed-clone/zsh" "$TEST_ROOT/shell-home"
cp "$REPOSITORY/zsh/.zshrc" "$TEST_ROOT/renamed-clone/zsh/.zshrc"
ln -s "$TEST_ROOT/renamed-clone/zsh/.zshrc" "$TEST_ROOT/shell-home/.zshrc"
resolved_root="$(HOME="$TEST_ROOT/shell-home" PATH=/usr/bin:/bin zsh -fc 'source ~/.zshrc; print -r -- "$DOTFILES_ROOT"')"
[[ "$resolved_root" == "$TEST_ROOT/renamed-clone" ]]

printf 'installer preflight, idempotence, backup/restore and path tests passed\n'
