#!/bin/bash

# git
sudo apt-get install -y git

# copyq
sudo add-apt-repository ppa:hluk/copyq
sudo apt update
sudo apt install -y copyq

# peek
sudo add-apt-repository ppa:peek-developers/stable
sudo apt update
sudo apt install -y peek

# meld
sudo apt-get install -y meld

# tree
sudo apt-get install -y tree

# rg
# curl -LO https://github.com/BurntSushi/ripgrep/releases/download/11.0.1/ripgrep_11.0.1_amd64.deb
# sudo dpkg -i ripgrep_11.0.1_amd64.deb
sudo apt-get install -y ripgrep

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
