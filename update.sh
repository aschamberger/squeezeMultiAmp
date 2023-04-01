#!/bin/sh

sudo apt update
sudo apt upgrade

# Update squeezeMultiAmp files from github
cd /usr/local/src/sma
rm -r ./*
wget https://github.com/aschamberger/squeezeMultiAmp/archive/main.zip
unzip main.zip
rm main.zip
mv squeezeMultiAmp-main/* .
rm -r squeezeMultiAmp-main