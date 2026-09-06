# Dotfiles

[![CI](https://github.com/yanis9zz/config/actions/workflows/ci.yml/badge.svg)](https://github.com/yanis9zz/config/actions/workflows/ci.yml)

Setup personnel pour obtenir rapidement un environnement Linux ou WSL prêt à utiliser.

## Installation

Sur une machine Ubuntu/Debian neuve (y compris WSL et les serveurs ARM Oracle),
installe Git si nécessaire, puis lance la préparation depuis ton compte habituel :

```sh
sudo apt-get update
sudo apt-get install --yes git ca-certificates
git clone https://github.com/yanis9zz/config.git ~/dotfiles
cd ~/dotfiles
./setup.sh bootstrap
exec zsh
```

Si le dépôt est déjà cloné, commence par `cd ~/dotfiles`, puis `./setup.sh bootstrap`.
Le dossier peut aussi s'appeler `~/config` : les scripts retrouvent son emplacement.

`bootstrap` installe uniquement les paquets système manquants avec `sudo` : Zsh,
Git, curl, certificats, compilateur C/C++, make, Perl, unzip, xz et Python avec venv.
Sur ARM64, il installe aussi `clangd` depuis la distribution, car Mason ne fournit
pas de binaire Linux ARM64 pour ce serveur de langage C/C++.
Les outils suivants sont installés dans ton compte, sans lancer le setup avec `sudo`.
Un Node.js 20+ accompagné de npm est conservé ; sinon Node.js 24 LTS est installé
dans `~/.local`, avec vérification SHA-256 et sélection automatique x86_64/ARM64.

Pour utiliser Zsh à chaque connexion, change ton shell une fois, puis reconnecte-toi :

```sh
sudo chsh -s "$(command -v zsh)" "$USER"
```

Le premier lancement de Neovim peut prendre un moment pendant l'installation des plugins,
des analyseurs de syntaxe et des serveurs de langage. Garde Neovim ouvert jusqu'à leur
installation ; `:Lazy`, `:Mason` et `:checkhealth kickstart` permettent de la vérifier.

### Machine déjà préparée ou autre distribution Linux

`./setup.sh install` installe les outils et applique les configurations sans `sudo`.
Les prérequis système sont Bash, Git, Zsh, curl, les certificats TLS, tar/gzip,
find, sha256sum, sort, awk, realpath, make, un compilateur C/C++, Perl, unzip, xz
et Python 3 avec venv (`clangd` est également requis sur ARM64).
En cas de manque, le script donne la liste avant de modifier
les configurations. Node.js et npm sont installés automatiquement si nécessaire.

### Connexion SSH

Choisis la police **MesloLGS NF** dans le terminal de ton PC. L'installer sur un
serveur distant ne change pas l'affichage de ton terminal ; le setup ignore donc
l'installation des polices lorsqu'il est lancé par SSH.

## Ce qui est inclus

- Neovim avec plugins, LSP, complétion et outils de recherche ;
- Zsh avec Oh My Zsh, Powerlevel10k et quelques outils modernes ;
- tmux avec une configuration prête à l'emploi ;
- les utilitaires nécessaires au setup ;
- la police MesloLGS NF pour Powerlevel10k ;
- une intégration du Codex CLI lorsqu'il est déjà installé.

Les anciennes configurations sont sauvegardées automatiquement. Dans le script, seule
la préparation des paquets système avec `bootstrap` utilise `sudo` ; le shell de connexion n'est pas
modifié automatiquement. Le setup ne crée pas de compte et n'installe pas le Codex CLI.

## Commandes utiles

```sh
./setup.sh bootstrap # préparer Ubuntu/Debian et installer la configuration
./setup.sh install   # installer et appliquer la configuration
./setup.sh update    # mettre à jour les outils et les liens
./setup.sh doctor    # vérifier l'installation sans rien modifier
./setup.sh reset     # retirer les liens de configuration
./setup.sh restore   # restaurer la dernière sauvegarde
./setup.sh --help    # afficher l'aide
```

## Mettre la configuration à jour

```sh
cd ~/dotfiles
git pull --ff-only
./setup.sh update
```

Les sauvegardes sont conservées dans `~/.config-backups/yanis-config/`.
