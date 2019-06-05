#!/bin/bash

sudo apt update
sudo apt install -y software-properties-common
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt-get install -y python-dev python-pip python3-pip python3.7
sudo pip3 install --upgrade pip
sudo pip3 install --upgrade pip

sudo cp /usr/bin/python .
sudo cp -f /usr/bin/python2.7 /usr/bin/python
sudo apt-get install -y python-support python-xlib

wget https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/key-mon/keymon_1.17-1_all.deb
sudo dpkg -i keymon_1.17-1_all.deb
