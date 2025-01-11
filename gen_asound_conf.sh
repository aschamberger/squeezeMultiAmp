#!/bin/sh

# no. of channels: 0, 3 or 4
SND_A=4
SND_B=4
# 0=off; 1=on
SND_PI=0

# internal to physical sequence mapping
i=1 ; eval sequence_map$i=1
i=2 ; eval sequence_map$i=4
i=3 ; eval sequence_map$i=2
i=4 ; eval sequence_map$i=3

OUT=asound.conf

CHANNELS=$(($SND_A+$SND_B+$SND_PI)) 

echo ">>> DEFAULT\n\
" > $OUT

echo "defaults.namehint.showall on\n\
defaults.namehint.extended on\n\
" >> $OUT

default="pcm.!default {\n\
  type plug\n\
  slave.pcm \"all\"\n\
}\n\
"
echo "$default" >> $OUT

echo ">>> ALL\n\
" >> $OUT

all_start="pcm.all {\n\
  type plug\n\
  slave {\n\
    pcm \"multi\"\n\
    channels $((2*$CHANNELS))\n\
  }"
echo "$all_start" >> $OUT

for i in `seq 1 $CHANNELS`
do
all_chan="  ttable.0.$(($i*2-2)) 1\n\
  ttable.1.$(($i*2-1)) 1"
echo "$all_chan" >> $OUT
done

all_end="}\n\
"
echo "$all_end" >> $OUT

for i in `seq 1 $CHANNELS`
do
echo ">>> CHANNEL $i\n\
" >> $OUT

if [ "$SND_A" -eq 3 ] || [ "$SND_A" -eq 4 ] && [ "$i" -le "$SND_A" ]; then
    card="SND_A"
    eval position=\$sequence_map$i
elif [ "$SND_B" -eq 3 ] || [ "$SND_B" -eq 4 ] && [ "$i" -le "$(($SND_A+$SND_B))" ]; then
    card="SND_B"
    eval position=\$sequence_map$(($i-$SND_A))
    position=$(($SND_A+$position))
elif [ "$SND_PI" -eq 1 ]; then
    card="0"
    position=$i
fi

chx="pcm.ch$i {\n\
  type plug\n\
  slave {\n\
    pcm \"multi\"\n\
    channels $((2*CHANNELS))\n\
  }\n\
  ttable.0.$(($position*2-2)) 1\n\
  ttable.1.$(($position*2-1)) 1\n\
}\n\
"
echo "$chx" >> $OUT

chxsv="pcm.ch$((i))_sv {\n\
  type plug\n\
  slave.pcm {\n\
    type softvol\n\
    slave.pcm \"ch$i\"\n\
    control {\n\
      name \"SoftVolCh$i\"\n\
      card $card\n\
    }\n\
  }\n\
}\n\
"
echo "$chxsv" >> $OUT

chxeq="pcm.ch$((i))_eq {\n\
  type plug\n\
  slave.pcm {\n\
    type equal\n\
    slave.pcm \"ch$((i))_sv\"\n\
    controls \"/etc/opt/eq/ch$((i))_eq.bin\"\n\
    library \"/usr/lib/ladspa/caps.so\"\n\
  }\n\
  slave.rate unchanged\n\
}\n\
"
echo "$chxeq" >> $OUT

chxeq="ctl.ch$((i))_eq {\n\
  type equal\n\
  controls \"/etc/opt/eq/ch$((i))_eq.bin\"\n\
  library \"/usr/lib/ladspa/caps.so\"\n\
}\n\
"
echo "$chxeq" >> $OUT

done

echo ">>> MULTI\n\
" >> $OUT

multi_start="pcm.multi {\n\
  type multi\n\
  slaves {"
echo "$multi_start" >> $OUT

if [ "$SND_A" -eq 3 ] || [ "$SND_A" -eq 4 ]; then
slave="    a {\n\
      pcm \"dmixera\"\n\
      channels $((2*$SND_B))\n\
    }"
echo "$slave" >> $OUT
fi

if [ "$SND_B" -eq 3 ] || [ "$SND_B" -eq 4 ]; then
slave="    b {\n\
      pcm \"dmixerb\"\n\
      channels $((2*$SND_B))\n\
    }"
echo "$slave" >> $OUT
fi

if [ "$SND_PI" -eq 1 ]; then
slave="    pi {\n\
      pcm \"dmixerpi\"\n\
      channels 2\n\
    }"
echo "$slave" >> $OUT
fi


multi_start="  }
  bindings {"
echo "$multi_start" >> $OUT

i=0
if [ "$SND_A" -eq 3 ] || [ "$SND_A" -eq 4 ]; then
for ii in `seq 1 $SND_A`
do
multi_chan="    $(($i*2)) { slave a channel $((ii*2-2)) }\n\
    $(($i*2+1)) { slave a channel $((ii*2-1)) }"
echo "$multi_chan" >> $OUT
i=$((i+1))
done
fi

if [ "$SND_B" -eq 3 ] || [ "$SND_B" -eq 4 ]; then
for ii in `seq 1 $SND_A`
do
multi_chan="    $(($i*2)) { slave b channel $((ii*2-2)) }\n\
    $(($i*2+1)) { slave b channel $((ii*2-1)) }"
echo "$multi_chan" >> $OUT
i=$((i+1))
done
fi

if [ "$SND_PI" -eq 1 ]; then
multi_chan="    $(($i*2)) { slave pi channel 0 }\n\
    $(($i*2+1)) { slave pi channel 1 }"
echo "$multi_chan" >> $OUT
fi

multi_end="  }\n\
}\n\
"
echo "$multi_end" >> $OUT

echo ">>> DMIXER\n\
" >> $OUT

if [ "$SND_A" -eq 3 ] || [ "$SND_A" -eq 4 ]; then
dmixer="pcm.dmixera {\n\
  type dmix\n\
  ipc_key 1024\n\
  ipc_perm 0666\n\
  slave {\n\
    pcm \"snda\"\n\
    rate 48000\n\
    period_time 0\n\
    period_size 1024\n\
    buffer_size 8192\n\
    channels 8\n\
  }\n\
  bindings {\n\
    0 0\n\
    1 1\n\
    2 2\n\
    3 3\n\
    4 4\n\
    5 5\n\
    6 6\n\
    7 7\n\
  }\n\
}\n\
"
echo "$dmixer" >> $OUT
fi

if [ "$SND_B" -eq 3 ] || [ "$SND_B" -eq 4 ]; then
dmixer="pcm.dmixerb {\n\
  type dmix\n\
  ipc_key 1024\n\
  ipc_perm 0666\n\
  slave {\n\
    pcm \"sndb\"\n\
    rate 48000\n\
    period_time 0\n\
    period_size 1024\n\
    buffer_size 8192\n\
    channels 8\n\
  }\n\
  bindings {\n\
    0 0\n\
    1 1\n\
    2 2\n\
    3 3\n\
    4 4\n\
    5 5\n\
    6 6\n\
    7 7\n\
  }\n\
}\n\
"
echo "$dmixer" >> $OUT
fi

if [ "$SND_PI" -eq 1 ]; then
dmixer="pcm.dmixerpi {\n\
  type dmix\n\
  ipc_key 1024\n\
  ipc_perm 0666\n\
  slave {\n\
    pcm \"sndpi\"\n\
    rate 48000\n\
    period_time 0\n\
    period_size 1024\n\
    buffer_size 8192\n\
    channels 2\n\
  }\n\
  bindings {\n\
    0 0\n\
    1 1\n\
  }\n\
}\n\
"
echo "$dmixer" >> $OUT
fi

echo ">>> LINE IN\n\
" >> $OUT

if [ "$SND_A" -eq 3 ] || [ "$SND_A" -eq 4 ]; then
linein="pcm.li1 {\n\
  type plug\n\
  slave.pcm \"dsnoopera\"\n\
}\n\
"
echo "$linein" >> $OUT
linein="pcm.li1_sv {\n\
  type plug\n\
  slave.pcm {\n\
    type softvol\n\
    slave.pcm \"li1\"\n\
    control {\n\
      name \"SoftVolLi1\"\n\
      card SND_A\n\
    }
  }
}\n\
"
echo "$linein" >> $OUT
fi

if [ "$SND_B" -eq 3 ] || [ "$SND_B" -eq 4 ]; then
linein="pcm.li2 {\n\
  type plug\n\
  slave.pcm \"dsnooperb\"\n\
}\n\
"
echo "$linein" >> $OUT
linein="pcm.li2_sv {\n\
  type plug\n\
  slave.pcm {\n\
    type softvol\n\
    slave.pcm \"li2\"\n\
    control {\n\
      name \"SoftVolLi2\"\n\
      card SND_B\n\
    }
  }
}\n\
"
echo "$linein" >> $OUT
fi

echo ">>> DSNOOPER\n\
" >> $OUT

if [ "$SND_A" -eq 3 ] || [ "$SND_A" -eq 4 ]; then
dsnooper="pcm.dsnoopera {\n\
  type dsnoop\n\
  ipc_key 1025\n\
  ipc_perm 0666\n\
  slave {\n\
    pcm \"snda\"\n\
    rate 48000\n\
    period_time 0\n\
    period_size 1024\n\
    buffer_size 8192\n\
    channels 2\n\
  }
}\n\
"
echo "$dsnooper" >> $OUT
fi

if [ "$SND_B" -eq 3 ] || [ "$SND_B" -eq 4 ]; then
dsnooper="pcm.dsnooperb {\n\
  type dsnoop\n\
  ipc_key 1025\n\
  ipc_perm 0666\n\
  slave {\n\
    pcm \"sndb\"\n\
    rate 48000\n\
    period_time 0\n\
    period_size 1024\n\
    buffer_size 8192\n\
    channels 2\n\
  }
}\n\
"
echo "$dsnooper" >> $OUT
fi

echo ">>> CARDS\n\
" >> $OUT

if [ "$SND_A" -eq 3 ] || [ "$SND_A" -eq 4 ]; then
card="pcm.snda {\n\
  type hw\n\
  card SND_A\n\
}\n\
"
echo "$card" >> $OUT
card="ctl.snda {\n\
  type hw\n\
  card SND_A\n\
}\n\
"
echo "$card" >> $OUT
fi

if [ "$SND_B" -eq 3 ] || [ "$SND_B" -eq 4 ]; then
card="pcm.sndb {\n\
  type hw\n\
  card SND_B\n\
}\n\
"
echo "$card" >> $OUT
card="ctl.sndb {\n\
  type hw\n\
  card SND_B\n\
}\n\
"
echo "$card" >> $OUT
fi

if [ "$SND_PI" -eq 1 ]; then
card="pcm.sndpi {\n\
  type hw\n\
  card 0\n\
}\n\
"
echo "$card" >> $OUT
card="ctl.sndpi {\n\
  type hw\n\
  card 0\n\
}\n\
"
echo "$card" >> $OUT
fi
