#!/bin/sh

MQTT=${MQTT:-localhost:1883}
LMS=${LMS:-localhost:9000}
SITE_ID=${SITE_ID:-default}
OUTPUT_DEVICE=${OUTPUT_DEVICE:-default}
MAC_ADDRESS=${MAC_ADDRESS:-02:00:00:00:00:00}
GPIO=${GPIO:-;;}

# run hermes audio player with user hermes
exec su-exec hermes python3 /usr/local/bin/hermes.py "$MQTT" "$LMS" "$SITE_ID" "$OUTPUT_DEVICE" "$MAC_ADDRESS" "$GPIO"