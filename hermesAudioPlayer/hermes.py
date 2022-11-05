#!/usr/bin/python

# https://docs.snips.ai/reference/hermes#playing-a-wav-sound

import os
import sys
import argparse
import time
import paho.mqtt.client as mqtt
import sounddevice
import soundfile
from LMSTools import LMSDiscovery, LMSServer, LMSPlayer
import io
import RPi.GPIO as GPIO
from zeroconf import ServiceBrowser, Zeroconf
from requests import post

volumeWeight=0.1

_RUNNING = True

def initGpio()
    if gpioSpeakerSwitcher is not None and GPIO.gpio_function(gpioSpeakerSwitcher) != GPIO.OUT:
        GPIO.setup(gpioSpeakerSwitcher, GPIO.OUT)
        GPIO.output(gpioSpeakerSwitcher, 0)
    if gpioRelay is not None and GPIO.gpio_function(gpioRelay) != GPIO.OUT:
        GPIO.setup(gpioRelay, GPIO.OUT)
        GPIO.output(gpioRelay, 0)
    if gpioMute is not None and GPIO.gpio_function(gpioMute) != GPIO.OUT:
        GPIO.setup(gpioMute, GPIO.OUT)
        GPIO.output(gpioMute, 1)

def powerAmp()
    if gpioRelay is not None and not GPIO.input(gpioRelay):
        GPIO.output(gpioRelay, 1)
    if gpioSpeakerSwitcher is not None:
        GPIO.output(gpioSpeakerSwitcher, 1)
    if gpioMute is not None:
        GPIO.output(gpioMute, 0)
    if hassSwitch is not None:
        url = "http://" + hassHost + "/api/services/switch/turn_on"
        headers = {
            "Authorization": "Bearer " + hassBearer,
            "content-type": "application/json"
        }
        data = '{"entity_id": "' + hassSwitch + '"}'
        post(url, headers=headers, data=data)

def unpowerAmp()
    if hassSwitch is not None:
        url = "http://" + hassHost + "/api/services/switch/turn_off"
        headers = {
            "Authorization": "Bearer " + hassBearer,
            "content-type": "application/json"
        }
        data = '{"entity_id": "' + hassSwitch + '"}'
        post(url, headers=headers, data=data)
    if gpioMute is not None:
        GPIO.output(gpioMute, 1)
    if gpioSpeakerSwitcher is not None:
        GPIO.output(gpioSpeakerSwitcher, 0)
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

def find_service(self, zeroconf, service_type, name, state_change):
    info = zeroconf.get_service_info(service_type, name)
    #if not (info.port == 1883 and service_type == "_mqtt._tcp.local."):
    if not (service_type == "_mqtt._tcp.local."):
        return

    if state_change is ServiceStateChange.Added:
        mqttHost[0] = str(socket.inet_ntoa(info.address))
        mqttHost[1] = info.port
    elif state_change is ServiceStateChange.Removed:
        pass

if __name__ == '__main__':
    print('Starting hermes audio player')

    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('-N', '--nameFile', help='squeezlite name file')
    
    if os.getenv('HERMES_SITE_ID') is not None and os.getenv('HERMES_SITE_ID').len > 0:
        siteId = os.getenv('HERMES_SITE_ID')
    if args.nameFile is not None:
        with open(args.nameFile, 'r') as f:
            siteId = f.read()
    else:
        siteId = 'default'
    
    outputDevice = os.getenv('OUTPUT_DEVICE')
    macAddress = os.getenv('OUTPUT_DEVICE')
    power = os.getenv('OUTPUT_DEVICE')
    hassHost = os.getenv('HASS_HOST')
    hassBearer = os.getenv('HASS_BEARER')       

    if os.getenv('LMS_HOST') is not None:
        lmsHost = os.getenv('LMS_HOST').split(':')
        if len(lmsHost) == 1:
            lmsHost.append(9000)
    else:
        servers = LMSDiscovery().all()
        lmsHost = [servers[0]['host'], servers[0]['port']]
        if len(servers) == 0:
            sys.exit('No Logitech Media Server could be discovered and no config given manually')

    if os.getenv('MQTT_HOST') is not None:
        mqttHost = os.getenv('MQTT_HOST').split(':')
        if len(mqttHost) == 1:
            mqttHost.append(1883)
    else:
        zeroconf = Zeroconf()
        browser = ServiceBrowser(zeroconf, "_mqtt._tcp.local.", handlers=[find_service])
        time.sleep(5)
        zeroconf.close()
            if not(mqttHost[0])
                sys.exit('No mqtt broker could be discovered via zeroconf and no config given manually')

    powerConfig = power.split(';')
    gpioMute = powerConfig[0] if powerConfig[0] else None
    gpioRelay = powerConfig[1] if powerConfig[1] else None
    gpioAllMute = powerConfig[2].split(':') if powerConfig[2] else None
    gpioSpeakerSwitcher = powerConfig[3] if powerConfig[3] else None
    hassSwitch = powerConfig[4] if powerConfig[4] else None

    # set pin numbering mode
    GPIO.setmode(GPIO.BOARD)

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
    mqttClient.message_callback_add("hermes/audioServer/{}/playBytes/#".format(siteId), playBytes)
#    mqttClient.message_callback_add("hermes/audioServer/{}/playFinished/#".format(siteId), playFinished)
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