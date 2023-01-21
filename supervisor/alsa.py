#!/usr/bin/python3

import subprocess

def alsactlStore():
    p = subprocess.run( [ 'alsactl', 'store' ], capture_output=True, text=True )
    if p.returncode == 0:
        return p.stdout
    else:
        print("error")

def getEqualizer(channel):
    device = channel + '_eq'
    # amixer -D ch1_eq scontents
    p = subprocess.run( [ 'amixer', '-D', device, 'scontents' ], capture_output=True, text=True )
    if p.returncode == 0:
        return extractEqualizerSettings(p.stdout)
    else:
        print("error")

def setEqualizer(channel, equal):
    set_equal = ("sset '00. 31 Hz' " + equal[0] + "\n"
    "sset '01. 63 Hz' " + equal[1] + "\n"
    "sset '02. 125 Hz' " + equal[2] + "\n"
    "sset '03. 250 Hz' " + equal[3] + "\n"
    "sset '04. 500 Hz' " + equal[4] + "\n"
    "sset '05. 1 kHz' " + equal[5] + "\n"
    "sset '06. 2 kHz' " + equal[6] + "\n"
    "sset '07. 4 kHz' " + equal[7] + "\n"
    "sset '08. 8 kHz' " + equal[8] + "\n"
    "sset '09. 16 kHz' " + equal[9])

    device = channel + '_eq'
    # amixer -D ch1_eq sset '00. 31 Hz' 66
    # amixer -D ch1_eq -s < stdin
    p = subprocess.run( [ 'amixer', '-D', device, '-s' ], input=set_equal, capture_output=True, text=True )
    if p.returncode == 0:
        return extractEqualizerSettings(p.stdout)
    else:
      print("error")

def extractEqualizerSettings(result):
    lines = result.split("\n")
    equal = [lines[5].split()[4][1:-2],
        lines[12].split()[4][1:-2],
        lines[19].split()[4][1:-2],
        lines[26].split()[4][1:-2],
        lines[33].split()[4][1:-2],
        lines[40].split()[4][1:-2],
        lines[47].split()[4][1:-2],
        lines[54].split()[4][1:-2],
        lines[61].split()[4][1:-2],
        lines[68].split()[4][1:-2]]
    return equal

def getAllDeviceVolumes():
    cardA = getDeviceVolumes("hw:CARD=SND_A")
    cardB = getDeviceVolumes("hw:CARD=SND_B")
    volumes = [cardA[0],
        cardA[2],
        cardA[4],
        cardA[6],
        cardB[0],
        cardB[2],
        cardB[4],
        cardB[6]]
    return volumes

def getDeviceVolumes(device):
    # amixer -D hw:CARD=SND_A get Speaker
    # -M Use the mapped volume for evaluating the percentage representation like alsamixer, to be more natural for human ear.
    # command returs same result as the 'get' command
    p = subprocess.run( [ 'amixer', '-D', device, '-M', 'get', 'Speaker' ], capture_output=True, text=True )
    if p.returncode == 0:
      return extractVolumeSettings(p.stdout)
    else:
      print("error")

def setChannelVolume(channel, volume):
    # ch1 | ch4 | ch3 | ch2
    # ch5 | ch8 | ch7 | ch6
    volumes = ['0%+', '0%+', '0%+', '0%+', '0%+', '0%+', '0%+', '0%+']
    if channel == 'ch1' or channel == 'ch5':
      volumes[0] = volume + '%'
      volumes[1] = volume + '%'
      returnIndex = 0
    elif channel == 'ch4' or channel == 'ch8':
      volumes[2] = volume + '%'
      volumes[3] = volume + '%'
      returnIndex = 2
    elif channel == 'ch3' or channel == 'ch7':
      volumes[4] = volume + '%'
      volumes[5] = volume + '%'
      returnIndex = 4
    elif channel == 'ch2' or channel == 'ch6':
      volumes[6] = volume + '%'
      volumes[7] = volume + '%'
      returnIndex = 6
    set_volume = ",".join(volumes)

    if channel == 'ch1' or channel == 'ch2' or channel == 'ch3' or channel == 'ch4':
      device = "hw:CARD=SND_A"
    elif channel == 'ch5' or channel == 'ch6' or channel == 'ch7' or channel == 'ch8':
      device = "hw:CARD=SND_B"

    # amixer -D hw:CARD=SND_A -M set Speaker <volume>
    # amixer -D hw:CARD=SND_A -M set Speaker 65%,66%,67%,68%,69%,70%,71%,72%
    # -M Use the mapped volume for evaluating the percentage representation like alsamixer, to be more natural for human ear.
    # command returs same result as the 'get' command
    p = subprocess.run( [ 'amixer', '-D', device, '-M', 'set', 'Speaker', set_volume ], capture_output=True, text=True )
    if p.returncode == 0:
        volumes = extractVolumeSettings(p.stdout)
        return volumes[returnIndex]
    else:
        print("error")

def extractVolumeSettings(result):
    lines = result.split("\n")
    equal = [lines[5].split()[4][1:-1],
        lines[6].split()[4][1:-1],
        lines[7].split()[4][1:-1],
        lines[8].split()[4][1:-1],
        lines[9].split()[4][1:-1],
        lines[10].split()[3][1:-1],
        lines[11].split()[4][1:-1],
        lines[12].split()[4][1:-1]]
    return equal

if __name__ == '__main__':
    print('alsa control test')

    channel = 'ch1'
    equal = ['66', '66', '66', '66', '66', '66', '66', '66', '66', '66']

    print(alsa.getEqualizer(channel))
    print(alsa.setEqualizer(channel, equal))
    print(alsa.getAllDeviceVolumes())
    print(alsa.setChannelVolume(channel, '7'))
