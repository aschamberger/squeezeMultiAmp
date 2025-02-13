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
DOCKER_COMPOSE_VERSION="2.32.1"
# For 64-bit OS use:
DOCKER_COMPOSE_ARCH="aarch64"
# For 32-bit OS use:
#DOCKER_COMPOSE_ARCH="armv7"
COMPOSE_PATH="/usr/libexec/docker/cli-plugins/docker-compose"
sudo mkdir -p /usr/libexec/docker/cli-plugins
sudo curl -L "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-linux-${DOCKER_COMPOSE_ARCH}" -o "${COMPOSE_PATH}"
sudo chmod +x "${COMPOSE_PATH}"

# Install `alsaequal` on host
sudo apt-get install -y libasound2-plugin-equal

# Download squeezeMultiAmp files from github
sudo mkdir -p /usr/local/src/sma
sudo chmod ugo+rw /usr/local/src/sma
cd /usr/local/src/sma
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

# Create name files and make sure they are writeable by the containers
sudo mkdir -p /etc/opt/squeezelite
sudo cp /usr/local/src/sma/squeezenames/* /etc/opt/squeezelite
sudo chmod -R ugo+rwx /etc/opt/squeezelite
sudo chown -R root:audio /etc/opt/squeezelite

# Prepare .env file
sudo mkdir -p /etc/opt/compose
sudo cp /usr/local/src/sma/default.env /etc/opt/compose/.env
sudo chmod -R ugo+rwx /etc/opt/compose
sudo chown -R root:audio /etc/opt/compose
sudo chmod g+s /etc/opt/compose

# Custom asound.conf + ALSA output level
sudo cp /usr/local/src/sma/two_4ch.asound.conf /etc/asound.conf

# Default equalizer config with proper permissions created that squeezelite dockers can run rootless.
sudo mkdir -p /etc/opt/eq
sudo chmod 0777 /etc/opt/eq
sudo chown -R root:audio /etc/opt/eq
sudo chmod g+s /etc/opt/eq

# Set permissions to be able to store from container
sudo chmod 0777 /var/lib/alsa
sudo chown -R root:audio /var/lib/alsa
sudo chmod -R g+w /var/lib/alsa

# Create own run folder for line in
sudo mkdir -p /run/line_in
sudo chmod 0777 /run/line_in
sudo chown -R root:audio /run/line_in

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
sudo cp /usr/local/src/sma/00-reboot-shutdown.rules /etc/polkit-1/rules.d/00-reboot-shutdown.rules
# old polkit version in pi os does not support new config format
#sudo cp /usr/local/src/sma/00-reboot-shutdown.pkla /etc/polkit-1/localauthority/50-local.d/00-reboot-shutdown.pkla
