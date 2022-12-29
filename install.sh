#!/bin/sh

# Install some required packages first
sudo apt update
sudo apt install -y \
     apt-transport-https \
     ca-certificates \
     curl \
     gnupg2 \
     software-properties-common

# Get the Docker signing key for packages
curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | sudo apt-key add -

# Add the Docker official repos
echo "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
     $(lsb_release -cs) stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list

# Install Docker
sudo apt update
sudo apt install -y --no-install-recommends \
    docker-ce \
    cgroupfs-mount
sudo systemctl enable --now docker

# Replace with the latest version from https://github.com/docker/compose/releases/latest
DOCKER_COMPOSE_VERSION="2.14.2"
# For 64-bit OS use:
DOCKER_COMPOSE_ARCH="aarch64"
# For 32-bit OS use:
#DOCKER_COMPOSE_ARCH="armv7"

sudo curl -L "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-linux-${DOCKER_COMPOSE_ARCH}" -o /usr/bin/docker-compose
sudo chmod +x /usr/bin/docker-compose    

# Install `alsaequal` on host
sudo apt-get install -y libasound2-plugin-equal

# Download squeezeMultiAmp files from github
sudo mkdir -p /usr/local/src/sma
sudo chmod ugo+rw /usr/local/src/sma
cd /usr/local/src/sma
wget https://github.com/aschamberger/squeezeMultiAmp/archive/main.zip
unzip main.zip
mv squeezeMultiAmp-main/* .
rm -r squeezeMultiAmp-main

# Create name files and make sure they are writeable by the containers
sudo mkdir -p /etc/opt/squeezelite
sudo cp /usr/local/src/sma/squeezenames/* /etc/opt/squeezelite
sudo chmod ugo+rwx /etc/opt/squeezelite/*

# Prepare .env file
sudo mkdir -p /etc/opt/compose
sudo cp /usr/local/src/sma/default.env /etc/opt/compose/.env

# Custom asound.conf + ALSA output level
sudo cp /usr/local/src/sma/two_4ch+pi.asound.conf /etc/asound.conf

# Default equalizer config with proper permissions created that squeezelite dockers can run rootless.
sudo mkdir -p /etc/opt/eq
sudo chmod 777 /etc/opt/eq
sudo chown -R root:audio /etc/opt/eq
sudo chmod g+s /etc/opt/eq

# Changing ALSA card IDs with udev
sudo cp /usr/local/src/sma/85-my-usb-audio.rules /etc/udev/rules.d/85-my-usb-audio.rules

# Allow power cycling the USB hub from the supervisior
sudo cp /usr/local/src/sma/52-usb.rules /etc/udev/rules.d/52-usb.rules

# Reload and apply udev rules
sudo udevadm control --reload-rules
sudo udevadm trigger -c remove -s sound
sudo udevadm trigger -c add -s sound
sudo udevadm trigger --attr-match=subsystem=usb

# Allow passwordless reboot/shutdown from the supervisior
sudo mkdir -p /etc/polkit-1/rules.d/
sudo cp /usr/local/src/sma/00-reboot-shutdown.rules /etc/polkit-1/rules.d/00-reboot-shutdown.rules
