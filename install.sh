#!/bin/bash

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
