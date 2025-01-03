#!/bin/sh

# Update squeezeMultiAmp files from github
cd /usr/local/src/sma
rm -r ./*
wget https://github.com/aschamberger/squeezeMultiAmp/archive/main.zip
unzip main.zip
rm main.zip
mv squeezeMultiAmp-main/* .
rm -r squeezeMultiAmp-main
# Download supervisor
wget https://github.com/aschamberger/sma-supervisor/archive/main.zip
unzip main.zip
rm main.zip
mv sma-supervisor-main supervisor
# Download squeezelite
wget https://github.com/aschamberger/sma-squeezelite/archive/main.zip
unzip main.zip
rm main.zip
mv sma-squeezelite-main squeezelite