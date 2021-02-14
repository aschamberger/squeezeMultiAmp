FROM alpine:3.13 as builder

ENV LANG C.UTF-8

RUN apk update \
    && apk add --no-cache build-base python3 python3-dev py3-pip py3-numpy libffi-dev portaudio libsndfile

RUN mkdir /wheels

RUN pip install wheel \
    && pip wheel --wheel-dir=/wheels RPi.GPIO==0.7.1a3 \
#    && pip wheel --wheel-dir=/wheels numpy \
    && pip wheel --wheel-dir=/wheels sounddevice \
    && pip wheel --wheel-dir=/wheels soundfile \
    && pip wheel --wheel-dir=/wheels paho-mqtt\
    && pip wheel --wheel-dir=/wheels https://github.com/aschamberger/LMSTools/archive/development.tar.gz

FROM alpine:3.13

ENV LANG C.UTF-8

RUN apk update \
    && apk add --no-cache su-exec python3 py3-pip py3-numpy libffi portaudio libsndfile

# add group piaudio and pigpio with gid of underlying raspberry os groups
RUN addgroup -g 29 -S piaudio \
    && addgroup -g 997 -S pigpio \
    && adduser -S hermes \
	&& addgroup hermes piaudio \
	&& addgroup hermes pigpio

# create file to be able to map host asound.conf
RUN touch /etc/asound.conf
	
COPY --from=builder /wheels /wheels

RUN pip install --no-index --find-links=/wheels RPi.GPIO \
#    && pip install --no-index --find-links=/wheels numpy \
    && pip install --no-index --find-links=/wheels sounddevice \
    && pip install --no-index --find-links=/wheels soundfile \
    && pip install --no-index --find-links=/wheels paho-mqtt \
    && pip install --no-index --find-links=/wheels LMSTools

COPY void.wav /usr/local/bin/void.wav
COPY hermes.py /usr/local/bin/hermes.py
COPY hermes.sh /usr/local/bin/hermes.sh
RUN chmod +x /usr/local/bin/hermes.sh

CMD [ "hermes.sh" ]
