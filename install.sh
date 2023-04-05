#!/bin/bash

# Install Brew for Mac
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew update

brew install jq
brew install git
brew install wget
brew install tree
brew install htop
brew install ripgrep
brew install meld
brew install tldr
brew install gimp

# CPU/RAM/Disc/Network monitor on tray
brew install stats

# No kazam for macOS, using an alternativa called OBS Studio
# brew install --cask obsbrew install kazam
# Install when necessary:
# brew install --cask obs

# copyq
# System Preferences -> Security & Privacy -> General (tab) -> You should see a warning that CopyQ was blocked, override it here and you should be good
brew install --cask copyq

# ngrok
# Docs: https://ngrok.com/docs
# Too dangerous, generally. Not installing but leaving here as documentation

# No peek for macOS, using an alternative called kap
brew install --cask kap

# espanso
brew tap espanso/espanso
brew install espanso
ln -sf ~/linux-utils/configs/espanso/default.yml ~/Library/Application\ Support/espanso/config/default.yml
ln -sf ~/linux-utils/configs/espanso/default.yml ~/Library/Application\ Support/espanso/match/base.yml
espanso restart

# docker and docker-compose
cd ~/Downloads
wget https://desktop.docker.com/mac/main/amd64/Docker.dmg
sudo hdiutil attach Docker.dmg
cd -
sudo /Volumes/Docker/Docker.app/Contents/MacOS/install --accept-license
sudo hdiutil detach /Volumes/Docker
echo "[WARN] docker and docker-compose installation will be finished after starting docker for the first time via Finder"

# aws cli
cd ~/Downloads
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
cd -

# terraform
# I probably won't need it, so commenting it out

# iterm2, instead of gnome-terminal
brew install iterm2

echo "Done!!"
