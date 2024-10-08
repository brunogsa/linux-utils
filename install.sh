#!/bin/bash

sudo apt update
sudo apt-get install -y git meld tree htop ripgrep kazam tldr
git config --global user.email "brunogsa.92@gmail.com"
git config --global user.name "Bruno G. Salomao Agostini"
git config --global core.editor "vi"

# copyq
sudo add-apt-repository ppa:hluk/copyq
sudo apt update
sudo apt install -y copyq

# ngrok
# Docs: https://ngrok.com/docs
wget https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip
unzip ngrok-stable-linux-amd64.zip
sudo mv ngrok /usr/bin/
rm *zip

# peek
sudo add-apt-repository ppa:peek-developers/stable
sudo apt update
sudo apt install -y peek

# espanso
sudo snap install espanso --classic
ln -sf ~/linux-utils/configs/espanso/default.yml ~/.config/espanso/config/default.yml
ln -sf ~/linux-utils/configs/espanso/default.yml ~/.config/espanso/match/base.yml
espanso restart

# docker
sudo apt-get remove docker docker-engine docker.io containerd runc
sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker

# docker-compose
sudo curl -L https://github.com/docker/compose/releases/download/1.21.2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# aws cli
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -fr awscliv2.zip aws

# terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install -y terraform

# xubuntu hotkeys
ln -sf ./configs/xubuntu/xfce4-keyboard-shortcuts.xml ~/.config/xfce4/xfconf/xfce-perchannel-xml/
