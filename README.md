# dotfiles

Repository to save my dotfiles.

I use [mise](https://mise.jdx.dev/) to manage them:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install mise
mkdir ~/dev && git clone git@github.com:QuiiBz/dotfiles.git ~/dev/dotfiles
cd ~/dev/dotfiles
mise trust
mise bootstrap --yes --force-dotfiles
mise run init
mise run sync
```
