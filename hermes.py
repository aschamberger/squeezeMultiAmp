#!/usr/bin/python

# https://docs.snips.ai/reference/hermes#playing-a-wav-sound

import argparse
import time
import paho.mqtt.client as mqtt
import sounddevice
import soundfile
from LMSTools import LMSDiscovery, LMSServer, LMSPlayer
import io
import RPi.GPIO as GPIO

GPIO.setmode(GPIO.BOARD)

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('mqtt', help='mqtt hostname:port')
parser.add_argument('lms', help='lms hostname:port')
parser.add_argument('siteId', help='hermes siteId')
parser.add_argument('outputDevice', help='also output device')
parser.add_argument('macAddress', help='mac address')
parser.add_argument('gpio', help='gpio pin config')
args = parser.parse_args()

lmsHost = args.lms.split(':')
if len(lmsHost) == 1:
    lmsHost.append(9000)
mqttHost = args.mqtt.split(':')
if len(mqttHost) == 1:
    mqttHost.append(1883)

gpioConfig = args.split(';')
gpioMute = gpioConfig[0] if gpioConfig[0] else None
gpioRelay = gpioConfig[1] if gpioConfig[1] else None
gpioAllMute = gpioConfig[2].split(':') if gpioConfig[2] else None

volumeWeight=0.1

_RUNNING = True

def initGpio()
    if gpioRelay is not None and GPIO.gpio_function(gpioRelay) != GPIO.OUT:
        GPIO.setup(gpioRelay, GPIO.OUT)
        GPIO.output(gpioRelay, 0)
    if GPIO.gpio_function(gpioMute) != GPIO.OUT:
        GPIO.setup(gpioMute, GPIO.OUT)
        GPIO.output(gpioMute, 1)

def powerAmp()
    if gpioRelay is not None and not GPIO.input(gpioRelay):
        GPIO.output(gpioRelay, 1)
    GPIO.output(gpioMute, 1)

def unpowerAmp()
    GPIO.output(gpioMute, 0)
    if gpioRelay is not None:
        allMute = True
        for gpio in gpioAllMute:
            if gpio and GPIO.input(gpio):
               allMute = False
               break
        if allMute:
            GPIO.output(gpioRelay, 0)

def onConnect(client, userdata, flags, rc):
    print("Connected to mqtt server with result code " + str(rc))

    client.subscribe("hermes/audioServer/{}/playBytes/#".format(args.siteId))
#  client.subscribe("hermes/audioServer/{}/playFinished/#".format(args.siteId))

def playBytes(client, userdata, msg):
    print(msg.topic)

    _unpause = False
    _unpower = False
    if lmsPlayer.power and not lmsPlayer.muted and lmsPlayer.mode == 'play':
        print("LMS player pause")
        lmsPlayer.pause()
        _unpause = True
    elif not lmsPlayer.power:
        print("Power on amp via GPIO")
        powerAmp()
        _unpower = True

    print("Play sound")
    data, fs = soundfile.read(io.BytesIO(msg.payload), dtype='float32')
    sounddevice.play(data*volumeWeight, fs, device=args.outputDevice)
    status = sounddevice.wait()
    if status:
        print('Error during playback: ' + str(status))

    # hermes command could have unpaused the player, so check first
    if _unpause and lmsPlayer.mode == 'pause':
        print("LMS player unpause")
        lmsPlayer.unpause()

    # hermes command could have powered the player, so check first
    if _unpower and not lmsPlayer.power:
        print("Power off amp via GPIO")
        unpowerAmp()

#def playFinished(client, userdata, msg):
#    print(msg.topic)

def stop():
    global _RUNNING
    _RUNNING = False

if __name__ == '__main__':
    print('Starting hermes audio player')

    # init GPIO if not done yet
    initGpio()

    # load empty wave file to prevent lag on playing first message
    data, fs = soundfile.read('void.wav', dtype='float32')
    sounddevice.play(data, fs, device=args.outputDevice)
    status = sounddevice.wait()
    if status:
        print('Error during playback: ' + str(status))

    lmsServer = LMSServer(lmsHost[0], lmsHost[1])
    lmsPlayer = LMSPlayer(args.macAddress, lmsServer)

    mqttClient = mqtt.Client()
    mqttClient.on_connect = onConnect
    mqttClient.message_callback_add("hermes/audioServer/{}/playBytes/#".format(args.siteId), playBytes)
#    mqttClient.message_callback_add("hermes/audioServer/{}/playFinished/#".format(args.siteId), playFinished)
    mqttClient.connect(mqttHost[0], int(mqttHost[1]))
    mqttClient.loop_start()

    try:
        while _RUNNING:
            time.sleep(0.1)
        raise KeyboardInterrupt
    except KeyboardInterrupt:
        pass
    finally:
        mqttClient.loop_stop()