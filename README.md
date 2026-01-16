# dotfiles

![mit license](https://img.shields.io/github/license/RyosukeDTomita/chezmoi)

## INDEX

- [ABOUT](#about)
- [ENVIRONMENT](#environment)
- [PREPARING](#preparing)
- [HOW TO USE](#how-to-use)

---

## ABOUT

My dotfiles managed by [chezmoi](https://www.chezmoi.io/).

---

## ENVIRONMENT

- OS: Ubuntu 22.04 LTS
- Shell: zsh
- dotfiles manager: [chezmoi](https://www.chezmoi.io/)
- neovim

---

## PREPARING

1. Install chezmoi by following the instructions on the [official website](https://www.chezmoi.io/install/).

```shell
# example for Ubuntu
dpkg --print-architecture
amd64
wget https://github.com/twpayne/chezmoi/releases/download/v2.69.3/chezmoi_2.69.3_linux_amd64.deb
sudo apt install ./chezmoi_2.69.3_linux_amd64.deb
````

---

## HOW TO USE

### update dotfiles

```shell
chezmoi edit <your dotfile name>
chizmoi apply # deploy changes
```

> [!NOTE]
> If you update dotfiles directly, use `chezmoi apply` to deploy changes.

###

---
