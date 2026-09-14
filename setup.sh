#!/usr/bin/env bash

set -Eeuo pipefail

readonly COMMAND="${1:-install}"
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES
readonly LOCAL_PREFIX="${HOME}/.local"
readonly LOCAL_BIN="${LOCAL_PREFIX}/bin"
readonly LOCAL_OPT="${LOCAL_PREFIX}/opt"
readonly STATE_DIR="${XDG_STATE_HOME:-${HOME}/.local/state}/yanis-config"
readonly STATE_FILE="${STATE_DIR}/managed-tools"
readonly BACKUP_ROOT="${HOME}/.config-backups/yanis-config"

readonly STOW_VERSION="2.4.1"
readonly NEOVIM_VERSION="0.12.5"
readonly ZOXIDE_VERSION="0.10.0"
readonly FZF_VERSION="0.74.3"
readonly ATUIN_VERSION="18.20.1"
readonly RIPGREP_VERSION="15.2.0"
readonly FD_VERSION="10.5.0"
readonly TMUX_VERSION="3.7c"
readonly NODE_MIN_VERSION="20"
readonly NODE_VERSION="24.18.0"
readonly NORMINETTE_VERSION="3.3.60"

readonly OH_MY_ZSH_COMMIT="4b657407c98bbc8830ae66c2ac7ff3d737c55a83"
readonly POWERLEVEL10K_COMMIT="3308262dfbd743b6e1d3956a2b5572f7a049d692"
readonly POWERLEVEL10K_MEDIA_COMMIT="145eb9fbc2f42ee408dacd9b22d8e6e0e553f83d"

readonly STOW_SHA256="2a671e75fc207303bfe86a9a7223169c7669df0a8108ebdf1a7fe8cd2b88780b"
readonly NEOVIM_SHA256_X86_64="bce0f56eda1f1b1db6eee8f4133d7a38813ea07933837dd1777411ca384c6875"
readonly NEOVIM_SHA256_AARCH64="1aa5ca085249580ae0f91eb14f27ec0919773ff2d99a163d03f3d6c21ac29725"
readonly ZOXIDE_SHA256_X86_64="2d93385b99f3e82cf2701609a1bffcad863fbeb75aa3fe7eb6be4d29be68b1ae"
readonly ZOXIDE_SHA256_AARCH64="f1f16c5d6298d63dee467eedea1cdcd8490e43e493bea43acd416dc9033ef641"
readonly FZF_SHA256_X86_64="3501a595e4b5c40a6b047340a0e8f805c46fd4e61ef95ef8a136ba8c61cf6f22"
readonly FZF_SHA256_AARCH64="4a17a17b46bd0c4873e995533de508995c11572c0be0664a5dbcf13f60463046"
readonly ATUIN_SHA256_X86_64="1ad3e8162b4570118a3e05ae6b9ca0575aad0bb018a83001805c4f52d4fe9c8f"
readonly ATUIN_SHA256_AARCH64="59781e7fdafe20bdb523af25062af45bcf87ee4100eaa8d04c8e5baa90de13f0"
readonly RIPGREP_SHA256_X86_64="33e15bcf1624b25cdd2a55813a47a2f95dbe126268203e76aa6a585d1e7b149c"
readonly RIPGREP_SHA256_AARCH64="800b1e7206afe799dfb5a6901f23147cfaabe0e52210538100f61e86e1740915"
readonly FD_SHA256_X86_64="761c72dc8e120d85b22292063be8a796e2eeb20eb3e4f38b8fa2343ccf3514a7"
readonly FD_SHA256_AARCH64="d76c4317f7d5dba69f8a2a15856c90c777e7f0dd4e85f0de8c76de6992c374d4"
readonly TMUX_SHA256_X86_64="cc56bd1cc873eb6089c615f0496b072385bda8a6d944069f38564a5d49c128aa"
readonly TMUX_SHA256_AARCH64="29dcb978da2a4b0cf6790f9e004865dac239a3ba03bbf776dddacce23d03831b"
readonly NODE_SHA256_X86_64="783130984963db7ba9cbd01089eaf2c2efb055c7c1693c943174b967b3050cb8"
readonly NODE_SHA256_AARCH64="6b4484c2190274175df9aa8f28e2d758a819cb1c1fe6ab481e2f95b463ab8508"

readonly FONT_SHA256_REGULAR="d97946186e97f8d7c0139e8983abf40a1d2d086924f2c5dbf1c29bd8f2c6e57d"
readonly FONT_SHA256_BOLD="b6c0199cf7c7483c8343ea020658925e6de0aeb318b89908152fcb4d19226003"
readonly FONT_SHA256_ITALIC="6f357bcbe2597704e157a915625928bca38364a89c22a4ac36e7a116dcd392ef"
readonly FONT_SHA256_BOLD_ITALIC="56b4131adecec052c4b324efb818dd326d586dbc316fc68f98f1cae2eb8d1220"

readonly -a PACKAGES=(zsh tmux nvim)
readonly -a SYSTEM_COMMANDS=(git zsh curl tar find sha256sum sort awk realpath make cc c++ perl unzip xz python3)
readonly -a APT_PACKAGES=(bash ca-certificates coreutils curl findutils g++ gcc git gawk make perl python3 python3-venv tar unzip xz-utils zsh)
readonly -a DNF_PACKAGES=(bash ca-certificates coreutils curl findutils gcc gcc-c++ git gawk make perl python3 python3-pip tar unzip xz zsh)
readonly -a PACMAN_PACKAGES=(bash ca-certificates coreutils curl findutils gcc git gawk make perl python python-pip tar unzip xz zsh)
readonly -a ZYPPER_PACKAGES=(bash ca-certificates coreutils curl findutils gcc gcc-c++ git gawk make perl python3 python3-pip tar unzip xz zsh)
readonly -a APK_PACKAGES=(bash build-base ca-certificates coreutils curl findutils git gawk make perl py3-pip python3 tar unzip xz zsh)
ARCH=""
WORK_DIR=""
LAST_BACKUP=""

usage() {
    cat <<'EOF'
Usage: ./setup.sh [command]

Commands:
  bootstrap     Install missing system prerequisites with sudo, then install
  install       Install pinned tools and deploy the dotfiles (default)
  update        Reconcile managed tools, pinned repositories and dotfiles
  doctor        Run read-only diagnostics
  reset         Remove only the symlinks managed by this repository
  restore [dir] Restore dotfiles from a backup (latest by default)
  --help        Show this help

Backups are kept in ~/.config-backups/yanis-config/<timestamp>/.
Supports Linux/WSL on x86_64 and aarch64. bootstrap detects apt, dnf, pacman,
zypper or apk. Only bootstrap uses sudo.
Run as your normal user, not root. The login shell is not changed automatically.
EOF
}

die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

info() { printf '[+] %s\n' "$*"; }
ok() { printf '[OK] %s\n' "$*"; }
warn() { printf '[!] %s\n' "$*" >&2; }

cleanup() {
    if [[ -n "$WORK_DIR" && "$WORK_DIR" == /tmp/* && -d "$WORK_DIR" ]]; then
        find "$WORK_DIR" -depth -delete 2>/dev/null || true
    fi
}

trap cleanup EXIT

new_temp_dir() {
    mktemp -d "$WORK_DIR/task.XXXXXX"
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || die "'$1' is required."
}

activate_node_if_needed() {
    if command -v node >/dev/null 2>&1; then
        return
    fi
    if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
        set +u
        # shellcheck source=/dev/null
        source "$HOME/.nvm/nvm.sh"
        set -u
    fi
}

node_is_compatible() {
    local version
    local major
    command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1 || return 1
    version="$(node --version 2>/dev/null)" || return 1
    major="${version#v}"
    major="${major%%.*}"
    [[ "$major" =~ ^[0-9]+$ ]] && (( major >= NODE_MIN_VERSION ))
}

detect_package_manager() {
    if command -v apt-get >/dev/null 2>&1 && command -v dpkg-query >/dev/null 2>&1; then
        printf 'apt\n'
    elif command -v dnf >/dev/null 2>&1 || command -v dnf5 >/dev/null 2>&1; then
        command -v rpm >/dev/null 2>&1 || die 'dnf was found, but rpm is missing.'
        printf 'dnf\n'
    elif command -v pacman >/dev/null 2>&1; then
        printf 'pacman\n'
    elif command -v zypper >/dev/null 2>&1; then
        command -v rpm >/dev/null 2>&1 || die 'zypper was found, but rpm is missing.'
        printf 'zypper\n'
    elif command -v apk >/dev/null 2>&1; then
        printf 'apk\n'
    else
        die 'no supported package manager found; bootstrap supports apt, dnf, pacman, zypper and apk.'
    fi
}

package_is_installed() {
    local manager="$1"
    local package="$2"
    case "$manager" in
        apt) [[ "$(dpkg-query -W -f='${db:Status-Status}' "$package" 2>/dev/null || true)" == installed ]] ;;
        dnf|zypper) rpm -q "$package" >/dev/null 2>&1 ;;
        pacman) pacman -Qq "$package" >/dev/null 2>&1 ;;
        apk) apk info -e "$package" >/dev/null 2>&1 ;;
        *) return 1 ;;
    esac
}

install_system_prerequisites() {
    local manager="$1"
    local package
    local dnf_command
    local -a packages=()
    local -a missing=()
    case "$manager" in
        apt)
            packages=("${APT_PACKAGES[@]}")
            ;;
        dnf)
            packages=("${DNF_PACKAGES[@]}")
            ;;
        pacman)
            packages=("${PACMAN_PACKAGES[@]}")
            ;;
        zypper)
            packages=("${ZYPPER_PACKAGES[@]}")
            ;;
        apk)
            packages=("${APK_PACKAGES[@]}")
            ;;
        *)
            die "unsupported package manager: ${manager}."
            ;;
    esac
    if [[ "$ARCH" == aarch64 ]]; then
        case "$manager" in
            apt) packages+=(clangd) ;;
            dnf) packages+=(clang-tools-extra) ;;
            pacman) packages+=(clang) ;;
            zypper) packages+=(clang-tools) ;;
            apk) packages+=(clang-extra-tools) ;;
        esac
    fi
    for package in "${packages[@]}"; do
        package_is_installed "$manager" "$package" || missing+=("$package")
    done
    if (( ${#missing[@]} == 0 )); then
        ok "system prerequisites are already installed (${manager})"
        return
    fi
    require_command sudo
    info "Installing system prerequisites with ${manager}: ${missing[*]}"
    case "$manager" in
        apt)
            sudo apt-get update
            sudo apt-get install --yes --no-install-recommends "${missing[@]}"
            ;;
        dnf)
            if command -v dnf >/dev/null 2>&1; then
                dnf_command=dnf
            else
                dnf_command=dnf5
            fi
            sudo "$dnf_command" install --assumeyes "${missing[@]}"
            ;;
        pacman)
            sudo pacman --noconfirm --needed -S "${missing[@]}"
            ;;
        zypper)
            sudo zypper --non-interactive install --no-recommends "${missing[@]}"
            ;;
        apk)
            sudo apk add --no-cache "${missing[@]}"
            ;;
    esac
}

bootstrap() {
    local manager
    ARCH="$(normalize_architecture)"
    manager="$(detect_package_manager)"
    (( EUID != 0 )) || die 'run bootstrap as your normal user; it invokes sudo only for system packages.'
    install_system_prerequisites "$manager"
    install_all
}

is_wsl() {
    [[ -n "${WSL_DISTRO_NAME:-}" ]] || grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null
}

normalize_architecture() {
    [[ "$(uname -s)" == Linux ]] || die 'automatic installation supports Linux and WSL only.'
    case "$(uname -m)" in
        x86_64|amd64) printf 'x86_64\n' ;;
        aarch64|arm64) printf 'aarch64\n' ;;
        *) die "unsupported architecture: $(uname -m)" ;;
    esac
}

version_ge() {
    local current="$1"
    local required="$2"
    [[ "$(printf '%s\n%s\n' "$required" "$current" | sort -V | head -n 1)" == "$required" ]]
}

download_file() {
    local url="$1"
    local output="$2"
    if command -v curl >/dev/null 2>&1; then
        curl -fL --retry 3 --retry-delay 1 "$url" -o "$output"
    else
        wget -qO "$output" "$url"
    fi
}

download_verified() {
    local url="$1"
    local expected_sha256="$2"
    local output="$3"
    download_file "$url" "$output"
    printf '%s  %s\n' "$expected_sha256" "$output" | sha256sum --check --status ||
        die "SHA-256 verification failed for ${url##*/}."
}

managed_version() {
    if [[ -f "$STATE_FILE" ]]; then
        awk -F= -v name="$1" '$1 == name { value=$2 } END { print value }' "$STATE_FILE"
    fi
}

is_managed() {
    [[ -n "$(managed_version "$1")" ]]
}

record_managed() {
    local name="$1"
    local version="$2"
    local temporary="${STATE_FILE}.tmp.$$"
    mkdir -p "$STATE_DIR"
    if [[ -f "$STATE_FILE" ]]; then
        awk -F= -v name="$name" '$1 != name' "$STATE_FILE" >"$temporary"
    else
        : >"$temporary"
    fi
    printf '%s=%s\n' "$name" "$version" >>"$temporary"
    mv -f "$temporary" "$STATE_FILE"
}

backup_unmanaged_binary() {
    local path="$1"
    local name="$2"
    local destination
    if [[ ! -e "$path" && ! -L "$path" ]] || is_managed "$name"; then
        return
    fi
    destination="${STATE_DIR}/replaced-binaries/$(date +%Y%m%d-%H%M%S)-${name}"
    mkdir -p "$(dirname "$destination")"
    cp -a "$path" "$destination"
    warn "saved the previous ${path} as ${destination}."
}

preflight() {
    local package
    local -a missing=()
    local -a commands=("${SYSTEM_COMMANDS[@]}")
    ARCH="$(normalize_architecture)"
    [[ "$ARCH" != aarch64 ]] || commands+=(clangd)
    for package in "${PACKAGES[@]}"; do
        [[ -d "$DOTFILES/$package" ]] || die "missing Stow package: ${package}."
    done
    for package in "${commands[@]}"; do
        command -v "$package" >/dev/null 2>&1 || missing+=("$package")
    done
    if (( ${#missing[@]} > 0 )); then
        die "missing prerequisites: ${missing[*]}. Run './setup.sh bootstrap' as your normal user, or install them with your distribution's package manager."
    fi
    activate_node_if_needed
    if ! node_is_compatible; then
        info "Node.js ${NODE_MIN_VERSION}+ and npm are missing or outdated; install will add Node.js ${NODE_VERSION} in ~/.local."
    fi
    report_deployment_conflicts
}

report_deployment_conflicts() {
    local package
    local source
    local relative
    local target
    local resolved
    local conflicts=0
    for package in "${PACKAGES[@]}"; do
        while IFS= read -r -d '' source; do
            relative="${source#"$DOTFILES/$package/"}"
            target="$HOME/$relative"
            if [[ -L "$target" ]]; then
                resolved="$(canonical_link_target "$target")"
                [[ "$resolved" == "$source" || "$resolved" == "$DOTFILES/nvim"/* ]] || (( conflicts += 1 ))
            elif [[ -e "$target" && ! -d "$target" ]]; then
                (( conflicts += 1 ))
            fi
        done < <(find "$DOTFILES/$package" -mindepth 1 -type d -print0)

        while IFS= read -r -d '' source; do
            relative="${source#"$DOTFILES/$package/"}"
            target="$HOME/$relative"
            if [[ -L "$target" ]]; then
                resolved="$(canonical_link_target "$target")"
                if [[ "$resolved" == "$source" || "$resolved" == "$DOTFILES/nvim"/* ]]; then
                    continue
                fi
            fi
            if [[ -e "$target" || -L "$target" ]]; then
                (( conflicts += 1 ))
            fi
        done < <(find "$DOTFILES/$package" \( -type f -o -type l \) -print0)
    done
    if (( conflicts > 0 )); then
        info "Preflight: ${conflicts} existing dotfile target(s) will be backed up."
    else
        ok 'Preflight: no unmanaged dotfile conflict'
    fi
}

binary_sha256() {
    case "$1:$ARCH" in
        neovim:x86_64) printf '%s\n' "$NEOVIM_SHA256_X86_64" ;;
        neovim:aarch64) printf '%s\n' "$NEOVIM_SHA256_AARCH64" ;;
        zoxide:x86_64) printf '%s\n' "$ZOXIDE_SHA256_X86_64" ;;
        zoxide:aarch64) printf '%s\n' "$ZOXIDE_SHA256_AARCH64" ;;
        fzf:x86_64) printf '%s\n' "$FZF_SHA256_X86_64" ;;
        fzf:aarch64) printf '%s\n' "$FZF_SHA256_AARCH64" ;;
        atuin:x86_64) printf '%s\n' "$ATUIN_SHA256_X86_64" ;;
        atuin:aarch64) printf '%s\n' "$ATUIN_SHA256_AARCH64" ;;
        ripgrep:x86_64) printf '%s\n' "$RIPGREP_SHA256_X86_64" ;;
        ripgrep:aarch64) printf '%s\n' "$RIPGREP_SHA256_AARCH64" ;;
        fd:x86_64) printf '%s\n' "$FD_SHA256_X86_64" ;;
        fd:aarch64) printf '%s\n' "$FD_SHA256_AARCH64" ;;
        tmux:x86_64) printf '%s\n' "$TMUX_SHA256_X86_64" ;;
        tmux:aarch64) printf '%s\n' "$TMUX_SHA256_AARCH64" ;;
        node:x86_64) printf '%s\n' "$NODE_SHA256_X86_64" ;;
        node:aarch64) printf '%s\n' "$NODE_SHA256_AARCH64" ;;
        *) die "no checksum for $1 on $ARCH." ;;
    esac
}

install_node() {
    local temporary
    local node_arch
    local install_directory
    local executable
    if node_is_compatible; then
        ok "Node.js $(node --version) and npm (existing runtime kept)"
        return
    fi
    node_arch=x64
    [[ "$ARCH" != aarch64 ]] || node_arch=arm64
    info "Installing Node.js ${NODE_VERSION} for ${node_arch}..."
    temporary="$(new_temp_dir)"
    download_verified \
        "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${node_arch}.tar.gz" \
        "$(binary_sha256 node)" "$temporary/node.tar.gz"
    tar -xzf "$temporary/node.tar.gz" -C "$temporary"
    install_directory="${LOCAL_OPT}/node-${NODE_VERSION}"
    if [[ -d "$install_directory" ]]; then
        find "$install_directory" -depth -delete
    fi
    mv "$temporary/node-v${NODE_VERSION}-linux-${node_arch}" "$install_directory"
    for executable in node npm npx; do
        backup_unmanaged_binary "$LOCAL_BIN/$executable" node
        ln -sfn "$install_directory/bin/$executable" "$LOCAL_BIN/$executable"
    done
    record_managed node "$NODE_VERSION"
    export PATH="$LOCAL_BIN:$PATH"
    hash -r
    node_is_compatible || die 'the installed Node.js runtime could not be started.'
    ok "Node.js ${NODE_VERSION} installed"
}

install_stow() {
    local current=""
    local temporary
    local install_directory
    local stage_root
    local staged_directory
    if command -v stow >/dev/null 2>&1; then
        current="$(stow --version | head -n 1 | awk '{print $NF}')"
    fi
    if [[ "$current" == "$STOW_VERSION" ]]; then
        ok "GNU Stow ${STOW_VERSION}"
        return
    fi
    require_command make
    require_command perl
    info "Installing GNU Stow ${STOW_VERSION}..."
    temporary="$(new_temp_dir)"
    download_verified "https://ftp.gnu.org/gnu/stow/stow-${STOW_VERSION}.tar.gz" \
        "$STOW_SHA256" "$temporary/stow.tar.gz"
    tar -xzf "$temporary/stow.tar.gz" -C "$temporary"
    install_directory="${LOCAL_OPT}/stow-${STOW_VERSION}"
    stage_root="$temporary/stage"
    staged_directory="${stage_root}${install_directory}"
    mkdir -p "$LOCAL_OPT"
    (
        cd "$temporary/stow-${STOW_VERSION}"
        ./configure --prefix="$install_directory"
        make --quiet
        make --quiet install DESTDIR="$stage_root"
    )
    if [[ -d "$install_directory" ]]; then
        find "$install_directory" -depth -delete
    fi
    mv "$staged_directory" "$install_directory"
    mkdir -p "$LOCAL_BIN"
    backup_unmanaged_binary "$LOCAL_BIN/stow" stow
    ln -sfn "$install_directory/bin/stow" "$LOCAL_BIN/stow"
    record_managed stow "$STOW_VERSION"
    hash -r
    ok "GNU Stow ${STOW_VERSION} installed"
}

install_norminette() {
    local current=""
    local environment="${LOCAL_OPT}/norminette"
    local executable="${environment}/bin/norminette"
    local requirements="${DOTFILES}/tools/norminette/requirements.txt"
    if [[ -x "$executable" ]]; then
        current=$("$executable" --version | cut -d" " -f2)
    fi
    if [[ "$current" != "$NORMINETTE_VERSION" ]]; then
        info "Installing Norminette ${NORMINETTE_VERSION}..."
        if [[ ! -x "${environment}/bin/python" ]]; then
            python3 -m venv "$environment"
        fi
        "$environment/bin/python" -m pip install --disable-pip-version-check \
            --upgrade --requirement "$requirements"
    fi
    mkdir -p "$LOCAL_BIN"
    backup_unmanaged_binary "$LOCAL_BIN/norminette" norminette
    ln -sfn "$executable" "$LOCAL_BIN/norminette"
    record_managed norminette "$NORMINETTE_VERSION"
    hash -r
    ok "Norminette ${NORMINETTE_VERSION} installed"
}

archive_url() {
    case "$1:$ARCH" in
        zoxide:x86_64) printf 'https://github.com/ajeetdsouza/zoxide/releases/download/v%s/zoxide-%s-x86_64-unknown-linux-musl.tar.gz\n' "$ZOXIDE_VERSION" "$ZOXIDE_VERSION" ;;
        zoxide:aarch64) printf 'https://github.com/ajeetdsouza/zoxide/releases/download/v%s/zoxide-%s-aarch64-unknown-linux-musl.tar.gz\n' "$ZOXIDE_VERSION" "$ZOXIDE_VERSION" ;;
        fzf:x86_64) printf 'https://github.com/junegunn/fzf/releases/download/v%s/fzf-%s-linux_amd64.tar.gz\n' "$FZF_VERSION" "$FZF_VERSION" ;;
        fzf:aarch64) printf 'https://github.com/junegunn/fzf/releases/download/v%s/fzf-%s-linux_arm64.tar.gz\n' "$FZF_VERSION" "$FZF_VERSION" ;;
        atuin:*) printf 'https://github.com/atuinsh/atuin/releases/download/v%s/atuin-%s-unknown-linux-musl.tar.gz\n' "$ATUIN_VERSION" "$ARCH" ;;
        ripgrep:*) printf 'https://github.com/BurntSushi/ripgrep/releases/download/%s/ripgrep-%s-%s-unknown-linux-musl.tar.gz\n' "$RIPGREP_VERSION" "$RIPGREP_VERSION" "$ARCH" ;;
        fd:*) printf 'https://github.com/sharkdp/fd/releases/download/v%s/fd-v%s-%s-unknown-linux-musl.tar.gz\n' "$FD_VERSION" "$FD_VERSION" "$ARCH" ;;
        tmux:x86_64) printf 'https://github.com/tmux/tmux-builds/releases/download/v%s/tmux-%s-linux-x86_64.tar.gz\n' "$TMUX_VERSION" "$TMUX_VERSION" ;;
        tmux:aarch64) printf 'https://github.com/tmux/tmux-builds/releases/download/v%s/tmux-%s-linux-arm64.tar.gz\n' "$TMUX_VERSION" "$TMUX_VERSION" ;;
        *) die "no artifact URL for $1 on $ARCH." ;;
    esac
}

install_archive_binary() {
    local name="$1"
    local executable="$2"
    local desired_version="$3"
    local current_version="$4"
    local temporary
    local found_binary
    local staged_binary
    if [[ "$current_version" == "$desired_version" ]]; then
        ok "${name} ${desired_version}"
        return
    fi
    info "Installing ${name} ${desired_version}..."
    temporary="$(new_temp_dir)"
    download_verified "$(archive_url "$name")" "$(binary_sha256 "$name")" "$temporary/archive.tar.gz"
    tar -xzf "$temporary/archive.tar.gz" -C "$temporary"
    found_binary="$(find "$temporary" -type f -name "$executable" -perm -u+x -print -quit)"
    [[ -n "$found_binary" ]] || die "${executable} was not found in the ${name} archive."
    mkdir -p "$LOCAL_BIN"
    backup_unmanaged_binary "$LOCAL_BIN/$executable" "$name"
    staged_binary="${LOCAL_BIN}/.${executable}.new.$$"
    install -m 0755 "$found_binary" "$staged_binary"
    mv -f "$staged_binary" "$LOCAL_BIN/$executable"
    record_managed "$name" "$desired_version"
    hash -r
    ok "${name} ${desired_version} installed"
}

install_neovim() {
    local current_version=""
    local temporary
    local archive_arch
    local extracted
    local install_directory
    local staged_directory
    if command -v nvim >/dev/null 2>&1; then
        current_version="$(nvim --version | head -n 1 | sed -E 's/^NVIM v([^ ]+).*/\1/')"
    fi
    if [[ -n "$current_version" ]] && version_ge "$current_version" '0.11.0'; then
        ok "Neovim ${current_version} (minimum 0.11 satisfied)"
        return
    fi
    info "Installing Neovim ${NEOVIM_VERSION}..."
    temporary="$(new_temp_dir)"
    archive_arch="$ARCH"
    [[ "$ARCH" == aarch64 ]] && archive_arch='arm64'
    download_verified \
        "https://github.com/neovim/neovim/releases/download/v${NEOVIM_VERSION}/nvim-linux-${archive_arch}.tar.gz" \
        "$(binary_sha256 neovim)" "$temporary/nvim.tar.gz"
    tar -xzf "$temporary/nvim.tar.gz" -C "$temporary"
    extracted="$temporary/nvim-linux-${archive_arch}"
    [[ -x "$extracted/bin/nvim" ]] || die 'Neovim archive layout is invalid.'
    mkdir -p "$LOCAL_OPT" "$LOCAL_BIN"
    install_directory="${LOCAL_OPT}/nvim-${NEOVIM_VERSION}"
    staged_directory="${LOCAL_OPT}/.nvim-${NEOVIM_VERSION}.$$"
    mv "$extracted" "$staged_directory"
    if [[ -d "$install_directory" ]]; then
        find "$install_directory" -depth -delete
    fi
    mv "$staged_directory" "$install_directory"
    backup_unmanaged_binary "$LOCAL_BIN/nvim" neovim
    ln -sfn "$install_directory/bin/nvim" "$LOCAL_BIN/nvim"
    record_managed neovim "$NEOVIM_VERSION"
    hash -r
    ok "Neovim ${NEOVIM_VERSION} installed"
}

repository_head() {
    git -C "$1" rev-parse HEAD 2>/dev/null || true
}

install_pinned_repository() {
    local name="$1"
    local url="$2"
    local commit="$3"
    local destination="$4"
    local current
    local temporary
    local checkout
    if [[ -d "$destination/.git" ]]; then
        current="$(repository_head "$destination")"
        if [[ "$current" == "$commit" ]]; then
            ok "${name} pinned at ${commit:0:12}"
            return
        fi
        if [[ -n "$(git -C "$destination" status --porcelain 2>/dev/null)" ]]; then
            warn "${name} has local changes; leaving it at ${current:0:12}."
            return
        fi
        if [[ "$(git -C "$destination" remote get-url origin 2>/dev/null || true)" != "$url" ]] &&
           ! is_managed "$name"; then
            warn "${destination} is not the expected ${name} repository; leaving it untouched."
            return
        fi
        info "Pinning ${name} to ${commit:0:12}..."
        git -C "$destination" fetch --quiet --depth 1 origin "$commit"
        git -C "$destination" checkout --quiet --detach "$commit"
        record_managed "$name" "$commit"
        ok "${name} pinned at ${commit:0:12}"
        return
    fi
    [[ ! -e "$destination" ]] || die "${destination} exists but is not a Git repository."
    info "Installing ${name} at ${commit:0:12}..."
    temporary="$(new_temp_dir)"
    checkout="$temporary/checkout"
    git init --quiet "$checkout"
    git -C "$checkout" remote add origin "$url"
    git -C "$checkout" fetch --quiet --depth 1 origin "$commit"
    git -C "$checkout" checkout --quiet --detach "$commit"
    mkdir -p "$(dirname "$destination")"
    mv "$checkout" "$destination"
    record_managed "$name" "$commit"
    ok "${name} installed"
}

font_sha256() {
    case "$1" in
        'MesloLGS NF Regular.ttf') printf '%s\n' "$FONT_SHA256_REGULAR" ;;
        'MesloLGS NF Bold.ttf') printf '%s\n' "$FONT_SHA256_BOLD" ;;
        'MesloLGS NF Italic.ttf') printf '%s\n' "$FONT_SHA256_ITALIC" ;;
        'MesloLGS NF Bold Italic.ttf') printf '%s\n' "$FONT_SHA256_BOLD_ITALIC" ;;
        *) die "no checksum for font $1." ;;
    esac
}

download_fonts() {
    local destination="$1"
    local font
    local encoded_font
    mkdir -p "$destination"
    for font in \
        'MesloLGS NF Regular.ttf' \
        'MesloLGS NF Bold.ttf' \
        'MesloLGS NF Italic.ttf' \
        'MesloLGS NF Bold Italic.ttf'; do
        encoded_font="${font// /%20}"
        download_verified \
            "https://raw.githubusercontent.com/romkatv/powerlevel10k-media/${POWERLEVEL10K_MEDIA_COMMIT}/${encoded_font}" \
            "$(font_sha256 "$font")" "$destination/$font"
    done
}

fonts_present() {
    local directory="$1"
    local font
    for font in \
        'MesloLGS NF Regular.ttf' \
        'MesloLGS NF Bold.ttf' \
        'MesloLGS NF Italic.ttf' \
        'MesloLGS NF Bold Italic.ttf'; do
        [[ -f "$directory/$font" ]] || return 1
    done
}

install_fonts() {
    local font_directory
    local temporary
    local windows_script
    if [[ -n "${SSH_CONNECTION:-}${SSH_TTY:-}" ]]; then
        info 'SSH session: select MesloLGS NF in the terminal on your client; no server fonts are needed.'
        return
    fi
    if is_wsl && command -v powershell.exe >/dev/null 2>&1 && command -v wslpath >/dev/null 2>&1; then
        windows_script="$(wslpath -w "$DOTFILES/scripts/install-meslolgs-fonts.ps1")"
        if powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass \
            -File "$windows_script" -Check >/dev/null 2>&1; then
            ok 'MesloLGS NF is installed in Windows'
            powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass \
                -File "$windows_script" -ConfigureTerminal
            return
        fi
        info 'Installing MesloLGS NF in Windows...'
        temporary="$(new_temp_dir)"
        download_fonts "$temporary/fonts"
        powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass \
            -File "$windows_script" -SourceDirectory "$(wslpath -w "$temporary/fonts")"
        ok 'MesloLGS NF installed; restart Windows Terminal'
        return
    fi
    font_directory="${XDG_DATA_HOME:-$HOME/.local/share}/fonts"
    if fonts_present "$font_directory"; then
        ok 'MesloLGS NF is installed'
        return
    fi
    info 'Installing MesloLGS NF...'
    temporary="$(new_temp_dir)"
    download_fonts "$temporary/fonts"
    mkdir -p "$font_directory"
    local font
    for font in \
        'MesloLGS NF Regular.ttf' \
        'MesloLGS NF Bold.ttf' \
        'MesloLGS NF Italic.ttf' \
        'MesloLGS NF Bold Italic.ttf'; do
        install -m 0644 "$temporary/fonts/$font" "$font_directory/.${font}.new.$$"
        mv -f "$font_directory/.${font}.new.$$" "$font_directory/$font"
    done
    command -v fc-cache >/dev/null 2>&1 && fc-cache -f "$font_directory" >/dev/null
    ok 'MesloLGS NF installed'
    if is_wsl; then
        warn 'PowerShell was unavailable; Windows applications may not see the Linux font files.'
    else
        warn "select 'MesloLGS NF' in your terminal profile if necessary."
    fi
}

canonical_link_target() {
    local link="$1"
    local value
    value="$(readlink "$link")"
    realpath -m "$(dirname "$link")/$value"
}

remove_legacy_links() {
    local path
    local resolved
    for path in \
        "$HOME/.config/nvim/init.lua" \
        "$HOME/.config/nvim/lazy-lock.json" \
        "$HOME/.config/nvim/.stylua.toml" \
        "$HOME/.config/nvim/lua" \
        "$HOME/.config/nvim"; do
        [[ -L "$path" ]] || continue
        resolved="$(canonical_link_target "$path")"
        case "$resolved" in
            "$DOTFILES/nvim"|"$DOTFILES/nvim/"*) unlink "$path" ;;
        esac
    done
}

ensure_backup_directory() {
    local timestamp
    if [[ -n "$LAST_BACKUP" ]]; then
        return
    fi
    timestamp="$(date +%Y%m%d-%H%M%S)"
    LAST_BACKUP="$BACKUP_ROOT/$timestamp"
    while [[ -e "$LAST_BACKUP" ]]; do
        LAST_BACKUP="${BACKUP_ROOT}/${timestamp}-$RANDOM"
    done
    mkdir -p "$LAST_BACKUP/home"
    : >"$LAST_BACKUP/manifest.tsv"
}

backup_target() {
    local target="$1"
    local relative
    local destination
    ensure_backup_directory
    relative="${target#"$HOME"/}"
    destination="$LAST_BACKUP/home/$relative"
    mkdir -p "$(dirname "$destination")"
    mv "$target" "$destination"
    printf '%s\t%s\n' "$target" "home/$relative" >>"$LAST_BACKUP/manifest.tsv"
    warn "backed up ${target}."
}

backup_conflicts() {
    local package
    local source
    local relative
    local target
    local resolved
    remove_legacy_links
    for package in "${PACKAGES[@]}"; do
        while IFS= read -r -d '' source; do
            relative="${source#"$DOTFILES/$package/"}"
            target="$HOME/$relative"
            if [[ -L "$target" ]]; then
                resolved="$(canonical_link_target "$target")"
                if [[ "$resolved" == "$source" ]]; then
                    continue
                fi
                backup_target "$target"
            elif [[ -e "$target" && ! -d "$target" ]]; then
                backup_target "$target"
            fi
        done < <(find "$DOTFILES/$package" -mindepth 1 -type d -print0)

        while IFS= read -r -d '' source; do
            relative="${source#"$DOTFILES/$package/"}"
            target="$HOME/$relative"
            if [[ -L "$target" ]]; then
                resolved="$(canonical_link_target "$target")"
                if [[ "$resolved" == "$source" ]]; then
                    continue
                fi
            fi
            if [[ -e "$target" || -L "$target" ]]; then
                backup_target "$target"
            fi
        done < <(find "$DOTFILES/$package" \( -type f -o -type l \) -print0)
    done
}

restore_backup_files() {
    local backup="$1"
    local target
    local stored
    local resolved
    [[ -f "$backup/manifest.tsv" ]] || die "invalid backup: ${backup}."
    while IFS=$'\t' read -r target stored; do
        [[ -n "$target" && -n "$stored" ]] || continue
        [[ "$target" == "$HOME/"* ]] || die "unsafe target in backup manifest: ${target}."
        [[ -e "$backup/$stored" || -L "$backup/$stored" ]] || die "missing backup entry: ${stored}."
        if [[ -L "$target" ]]; then
            resolved="$(canonical_link_target "$target")"
            case "$resolved" in
                "$DOTFILES"/*) unlink "$target" ;;
                *) warn "skipping ${target}: it is now linked outside this repository."; continue ;;
            esac
        elif [[ -d "$target" ]]; then
            if [[ -z "$(find "$target" -mindepth 1 -print -quit)" ]]; then
                rmdir "$target"
            else
                warn "skipping ${target}: a non-empty directory now exists there."
                continue
            fi
        elif [[ -e "$target" ]]; then
            warn "skipping ${target}: a non-managed file now exists there."
            continue
        fi
        mkdir -p "$(dirname "$target")"
        cp -a "$backup/$stored" "$target"
        ok "restored ${target}"
    done <"$backup/manifest.tsv"
}

prune_empty_managed_directories() {
    local package="$1"
    local source
    local relative
    local target
    while IFS= read -r -d '' source; do
        relative="${source#"$DOTFILES/$package/"}"
        target="$HOME/$relative"
        if [[ -d "$target" && ! -L "$target" ]]; then
            rmdir "$target" 2>/dev/null || true
        fi
    done < <(find "$DOTFILES/$package" -mindepth 1 -depth -type d -print0)
}

deploy_dotfiles() {
    local package
    local cleanup_package
    info 'Checking dotfile conflicts...'
    backup_conflicts
    mkdir -p "$HOME/.config"
    for package in "${PACKAGES[@]}"; do
        if ! stow --no-folding --simulate --restow -d "$DOTFILES" --target "$HOME" "$package"; then
            [[ -z "$LAST_BACKUP" ]] || restore_backup_files "$LAST_BACKUP"
            die "Stow simulation failed for ${package}."
        fi
    done
    info 'Deploying dotfiles...'
    for package in "${PACKAGES[@]}"; do
        if ! stow --no-folding --restow -d "$DOTFILES" --target "$HOME" "$package"; then
            for cleanup_package in "${PACKAGES[@]}"; do
                stow --no-folding --delete -d "$DOTFILES" --target "$HOME" "$cleanup_package" 2>/dev/null || true
                prune_empty_managed_directories "$cleanup_package"
            done
            [[ -z "$LAST_BACKUP" ]] || restore_backup_files "$LAST_BACKUP"
            die 'Stow failed; the new links were removed and the backup was restored.'
        fi
    done
    ok 'dotfiles deployed'
    [[ -z "$LAST_BACKUP" ]] || printf 'Backup: %s\n' "$LAST_BACKUP"
}

reset_dotfiles() {
    local package
    command -v stow >/dev/null 2>&1 || die 'Stow is required to remove the links.'
    remove_legacy_links
    for package in "${PACKAGES[@]}"; do
        stow --no-folding --delete -d "$DOTFILES" --target "$HOME" "$package"
        prune_empty_managed_directories "$package"
    done
    ok 'managed dotfile links removed; backups and tools were kept'
}

latest_backup() {
    [[ -d "$BACKUP_ROOT" ]] || return 0
    find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null |
        sort -r | head -n 1
}

restore_dotfiles() {
    local requested="${1:-}"
    local backup
    local package
    if [[ -n "$requested" ]]; then
        if [[ "$requested" == /* ]]; then
            backup="$(realpath -m "$requested")"
        else
            backup="$(realpath -m "$BACKUP_ROOT/$requested")"
        fi
    else
        requested="$(latest_backup)"
        [[ -n "$requested" ]] || die "no backup found in ${BACKUP_ROOT}."
        backup="$BACKUP_ROOT/$requested"
    fi
    case "$backup" in
        "$BACKUP_ROOT"/*) ;;
        *) die "backup must be inside ${BACKUP_ROOT}." ;;
    esac
    [[ -f "$backup/manifest.tsv" ]] || die "invalid backup: ${backup}."
    if command -v stow >/dev/null 2>&1; then
        remove_legacy_links
        for package in "${PACKAGES[@]}"; do
            stow --no-folding --delete -d "$DOTFILES" --target "$HOME" "$package" 2>/dev/null || true
            prune_empty_managed_directories "$package"
        done
    fi
    restore_backup_files "$backup"
    ok "backup restored from ${backup}"
    warn 'Windows Terminal settings are intentionally not changed by restore.'
}

doctor_item() {
    printf '[%s] %-22s %s\n' "$2" "$1" "$3"
}

doctor() {
    local failures=0
    local warnings=0
    local version
    local node_major
    local target
    local source
    local package
    local relative
    local -a commands=("${SYSTEM_COMMANDS[@]}" node npm)
    if [[ "$(uname -s)" == Linux ]] && normalize_architecture >/dev/null 2>&1; then
        doctor_item platform OK "Linux/$(normalize_architecture)"
        [[ "$(normalize_architecture)" != aarch64 ]] || commands+=(clangd)
    else
        doctor_item platform FAIL 'Linux x86_64 or aarch64 is required'
        (( failures += 1 ))
    fi
    for target in "${commands[@]}"; do
        if command -v "$target" >/dev/null 2>&1; then
            doctor_item "$target" OK "$(command -v "$target")"
        else
            doctor_item "$target" FAIL 'missing; run ./setup.sh bootstrap or install it with your package manager'
            (( failures += 1 ))
        fi
    done
    if command -v node >/dev/null 2>&1; then
        version="$(node --version)"
        node_major="${version#v}"
        node_major="${node_major%%.*}"
        if (( node_major >= NODE_MIN_VERSION )); then
            doctor_item 'Node.js version' OK "$version"
        else
            doctor_item 'Node.js version' FAIL "$version; ${NODE_MIN_VERSION}+ required"
            (( failures += 1 ))
        fi
    fi
    if command -v nvim >/dev/null 2>&1; then
        version="$(nvim --version | head -n 1 | sed -E 's/^NVIM v([^ ]+).*/\1/')"
        if version_ge "$version" '0.11.0'; then
            doctor_item Neovim OK "$version"
        else
            doctor_item Neovim FAIL "$version; 0.11+ required"
            (( failures += 1 ))
        fi
    else
        doctor_item Neovim FAIL 'missing; install will add 0.12.5'
        (( failures += 1 ))
    fi
    for target in norminette stow zoxide fzf atuin rg fd tmux; do
        if command -v "$target" >/dev/null 2>&1; then
            doctor_item "$target" OK "$(command -v "$target")"
        else
            doctor_item "$target" WARN 'missing; install will add it'
            (( warnings += 1 ))
        fi
    done
    if command -v codex >/dev/null 2>&1; then
        doctor_item Codex OK "$(codex --version 2>/dev/null | head -n 1)"
    else
        doctor_item Codex INFO 'optional; not installed'
    fi
    for package in "${PACKAGES[@]}"; do
        while IFS= read -r -d '' source; do
            relative="${source#"$DOTFILES/$package/"}"
            target="$HOME/$relative"
            if [[ ! -L "$target" ]] || [[ "$(canonical_link_target "$target")" != "$source" ]]; then
                doctor_item "dotfile $relative" WARN 'not deployed from this repository'
                (( warnings += 1 ))
            fi
        done < <(find "$DOTFILES/$package" \( -type f -o -type l \) -print0)
    done
    printf '\nDoctor: %d failure(s), %d warning(s).\n' "$failures" "$warnings"
    (( failures == 0 ))
}

install_all() {
    local zoxide_current=""
    local fzf_current=""
    local atuin_current=""
    local rg_current=""
    local fd_current=""
    local tmux_current=""
    local zsh_custom
    (( EUID != 0 )) || die 'run install as your normal user, not root.'
    preflight
    WORK_DIR="$(mktemp -d)"
    mkdir -p "$LOCAL_BIN" "$LOCAL_OPT" "$STATE_DIR"
    if [[ "${DOTFILES_TEST_MODE:-0}" == 1 ]]; then
        require_command stow
        deploy_dotfiles
        return
    fi
    install_node
    install_stow
    install_norminette
    install_neovim
    command -v zoxide >/dev/null 2>&1 && zoxide_current="$(zoxide --version | awk '{print $2}')"
    command -v fzf >/dev/null 2>&1 && fzf_current="$(fzf --version | awk '{print $1}')"
    command -v atuin >/dev/null 2>&1 && atuin_current="$(atuin --version | awk '{print $2}')"
    command -v rg >/dev/null 2>&1 && rg_current="$(rg --version | head -n 1 | awk '{print $2}')"
    if [[ "$(command -v rg 2>/dev/null || true)" == "$HOME/.nvm/"* ]]; then
        rg_current=""
    fi
    command -v fd >/dev/null 2>&1 && fd_current="$(fd --version | awk '{print $2}')"
    command -v tmux >/dev/null 2>&1 && tmux_current="$(tmux -V | awk '{print $2}')"
    install_archive_binary zoxide zoxide "$ZOXIDE_VERSION" "$zoxide_current"
    install_archive_binary fzf fzf "$FZF_VERSION" "$fzf_current"
    install_archive_binary atuin atuin "$ATUIN_VERSION" "$atuin_current"
    install_archive_binary ripgrep rg "$RIPGREP_VERSION" "$rg_current"
    install_archive_binary fd fd "$FD_VERSION" "$fd_current"
    install_archive_binary tmux tmux "$TMUX_VERSION" "$tmux_current"
    install_pinned_repository oh-my-zsh https://github.com/ohmyzsh/ohmyzsh.git \
        "$OH_MY_ZSH_COMMIT" "$HOME/.oh-my-zsh"
    zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    install_pinned_repository powerlevel10k https://github.com/romkatv/powerlevel10k.git \
        "$POWERLEVEL10K_COMMIT" "$zsh_custom/themes/powerlevel10k"
    install_fonts
    deploy_dotfiles
    if [[ "${SHELL:-}" != */zsh ]]; then
        warn "your login shell is ${SHELL:-unknown}; run 'zsh' or change it manually if desired."
    fi
    printf '\nReady. Run: exec zsh\n'
    printf 'Health check: %s doctor\n' "$0"
}

export PATH="$LOCAL_BIN:$PATH"

case "$COMMAND" in
    bootstrap)
        (( $# <= 1 )) || die 'bootstrap takes no argument.'
        bootstrap
        ;;
    install)
        (( $# <= 1 )) || die 'install takes no argument.'
        install_all
        ;;
    update)
        (( $# <= 1 )) || die 'update takes no argument.'
        install_all
        ;;
    doctor)
        (( $# <= 1 )) || die 'doctor takes no argument.'
        activate_node_if_needed
        doctor
        ;;
    reset)
        (( $# <= 1 )) || die 'reset takes no argument.'
        reset_dotfiles
        ;;
    restore)
        (( $# <= 2 )) || die 'restore accepts at most one backup path or name.'
        restore_dotfiles "${2:-}"
        ;;
    --help|-h|help)
        usage
        ;;
    *)
        usage >&2
        die "unknown command: ${COMMAND}."
        ;;
esac
