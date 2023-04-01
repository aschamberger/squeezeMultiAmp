#!/bin/sh

OUTPUT_DEVICE=${OUTPUT_DEVICE:-default}
MAC_ADDRESS=${MAC_ADDRESS:-02:00:00:00:00:00}
POWER=${POWER:-;;;}
MQTT_HOST=${MQTT:-localhost:1883}
LMS_HOST=${HASS_HOST:-localhost:9000}
HASS_HOST=${HASS_HOST:-homeassistant:8123}

export PYTHONUNBUFFERED=1

# run hermes audio player with user hermes
exec su-exec hermes python3 /usr/local/bin/hermes.py -N /config/squeeze.name