# hermesAudioPlayer Docker

Audio playback docker to run on Raspberry Pi for the [https://github.com/snipsco/hermes-protocol](hermes-protocol) used by e.g. [Rhasspy Voice Assistant](https://rhasspy.readthedocs.io/en/latest/). 

Features:
* play audio coming from MQTT via [paho-mqtt](https://pypi.org/project/paho-mqtt/) & [sounddevice](https://python-sounddevice.readthedocs.io)
* un-/mute amp and power supply via [RPi.GPIO](https://pypi.org/project/RPi.GPIO/)
* un-/mute Logitech Media Server players via [LMStools](https://github.com/aschamberger/LMSTools)
* based on Alpine Linux
* Container init via [Tini](https://github.com/krallin/tini)
* rootless via [su-exec](https://github.com/ncopa/su-exec)

## Docker build

```
sudo docker build -t hermes .
```

## Docker run

Custom config via env:
```
sudo docker run -d --network host --device /dev/gpiomem --device /dev/snd --ipc="host" --mount type=bind,source=/etc/asound.conf,target=/etc/asound.conf,readonly --env MQTT=localhost:1883 --env LMS=tower:9000 --env SITE_ID=default --env OUTPUT_DEVICE=default --env MAC_ADDRESS=02:00:00:00:00:00 --env GPIO="15;7;15:18:22:31:32:36:35:40" hermes
```
Env variables:
* MQTT: MQTT broker of e.g. Rhasspy talking the hermes protocol 
* LMS: Logitech Media Server
* SITE_ID: hermes site id
* OUTPUT_DEVICE: ALSA output device
* MAC_ADDRESS: mac of LMS player instance
* GPIO: config for muting amp and power supply (see next section)

Requires access to /dev/gpiomem and /dev/snd devices. The IPC setting is for ALSA dmix to work across containers. The hosts asound.conf is mounted into the container.

## Power mute feature / GPIO config:

A power mute feature can mute/power down the connected amp via a GPIO (first parameter). The second parameter allows to power down the power supply if all connected amps (listed in third parameter) are off. The optional speaker switcher GPIO is used to trigger an external 5V relais changing speakers between sqeezeMultiAmp and another amp in the room.

Pi GPIO config is done using board GPIO numbers (not BCM oder WiringPi numbering scheme) - `<current amp GPIO>;<power relay GPIO>;<all up to 8 amp GPIOs>`(;<speaker switcher GPIO>):
```
15;7;15:18:22:31:32:36:35:40;11
```

## Docker dev

Run and login to shell:
```
sudo docker run -it --network host --device /dev/gpiomem --device /dev/snd hermes /bin/sh
```
Login to running container:
```
sudo docker exec -it <name> /bin/sh
```

## Development

1. List available sound devices:  
```
python3 -m sounddevice
```
	
1. Play example file on device:
```
wget http://www.kozco.com/tech/piano2.wav
wget https://google.github.io/tacotron/publications/tacotron2/demos/fox_period.wav
aplay -D fronta piano2.wav 
wget https://python-sounddevice.readthedocs.io/en/0.3.13/_downloads/play_file.py
wget https://python-sounddevice.readthedocs.io/en/0.3.13/_downloads/play_long_file.py
chmod +x *.py
python3 play_file.py -d fronta piano2.wav
```
	
1. Play example file via MQTT on a specific site id (here `default`):
```
mosquitto_pub -h <HOSTNAME> -t 'hermes/audioServer/default/playBytes/8ewnjksdf093jb42' -f sound.wav    
```

Links:
* Tutorial for multi stage python package builds: https://morioh.com/p/d777482dea93
* Hermes playBytes: https://docs.snips.ai/reference/hermes#playing-a-wav-sound
* RPI.GPIO docs/examples: https://sourceforge.net/p/raspberry-gpio-python/wiki/BasicUsage/
* Source of [void.wav](http://www.wc3c.net/attachment.php?s=21454f5b8be64c07fdfb9b06530e6aa7&attachmentid=39290&d=1230381401): http://www.wc3c.net/showthread.php?t=103828
