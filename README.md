# dotfiles

Repository to save my dotfiles.

I use [mise](https://mise.jdx.dev/) to manage them:

```bash
curl https://mise.run | sh
mkdir ~/dev && git clone git@github.com:QuiiBz/dotfiles.git ~/dev/dotfiles
cd ~/dev/dotfiles
mise trust
mise bootstrap --yes --force-dotfiles
mise run init
mise run sync
```
