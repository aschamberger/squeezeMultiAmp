#!/bin/sh

# squeezelite power script
# squeezelite -S /path/to/power_mute.sh
# squeezelite sets $1 to
#   0: off
#   1: on
#   2: init

#echo "power/mute ..."

# create lock in order to make sure we have exclusive access to GPIO
exec 200>/var/lock/gpio || exit 1
flock 200 || exit 1

case $1 in
    # init
    2)
        echo "init $OUTPUT_DEVICE:\n"
        if [[ -n "$GPIO_PSU_RELAY" ]]; then
            # set output mode if not initialized yet
            RELAY_MODE=$(gpio get_mode $GPIO_PSU_RELAY)
            if [[ $RELAY_MODE == 0 ]]; then
                gpio set_mode $GPIO_PSU_RELAY 1
                gpio write $GPIO_PSU_RELAY 0
                echo "PSU relay: $GPIO_PSU_RELAY ..."
            fi
        fi
        if [[ -n "$GPIO_SPS" ]]; then
            # set output mode if not initialized yet
            SPEAKER_SWITCHER_MODE=$(gpio get_mode $GPIO_SPS)
            if [[ $SPEAKER_SWITCHER_MODE == 0 ]]; then
                gpio set_mode $GPIO_SPS 1
                gpio write $GPIO_SPS 0
                echo "SPS: $GPIO_SPS ..."
            fi
        fi
        if [[ -n "$GPIO_MUTE" ]]; then
            # set output mode if not initialized yet
            MUTE_MODE=$(gpio get_mode $GPIO_MUTE)
            if [[ $MUTE_MODE == 0 ]]; then
                gpio set_mode $GPIO_MUTE 1
                gpio write $GPIO_MUTE 1
                echo "Mute: $GPIO_MUTE ..."
            fi
        fi
        if [[ -n "$GPIO_SHUTDOWN" ]]; then
            # set output mode if not initialized yet
            SHUTDOWN_MODE=$(gpio get_mode $GPIO_SHUTDOWN)
            if [[ $SHUTDOWN_MODE == 0 ]]; then
                gpio set_mode $GPIO_SHUTDOWN 1
                gpio write $GPIO_SHUTDOWN 1
                echo "Shutdown: $GPIO_SHUTDOWN ..."
            fi
        fi
        echo "\n"
        ;;
    # on
    1)
        echo "power on $OUTPUT_DEVICE:\n"
        if [[ -n "$GPIO_PSU_RELAY" ]]; then
            RELAY_ON=$(gpio read $GPIO_PSU_RELAY)
            if [[ $RELAY_ON == 0 ]]; then
                gpio write $GPIO_PSU_RELAY 1
                echo "PSU relay: $GPIO_PSU_RELAY ..."
                sleep 2
            fi
        fi
        if [[ -n "$GPIO_SPS" ]]; then
            gpio write $GPIO_SPS 1
            echo "SPS: $GPIO_SPS ..."
        fi
        if [[ -n "$GPIO_SHUTDOWN" ]]; then
            gpio write $GPIO_SHUTDOWN 0
            echo "Shutdown: $GPIO_SHUTDOWN ..."
        fi
        if [[ -n "$GPIO_MUTE" ]]; then
            gpio write $GPIO_MUTE 0
            echo "Mute: $GPIO_MUTE ..."
        fi
        if [[ -n "$HASS_SWITCH" ]]; then
            curl -s -X POST -H "Authorization: Bearer $HASS_BEARER" \
                -H "Content-Type: application/json" \
                -d '{"entity_id": "'"$HASS_SWITCH"'"}' \
                http://$HASS_HOST/api/services/switch/turn_on
            echo "HASS switch: $HASS_SWITCH ..."
        fi
        echo "\n"
        ;;
    # off
    0)
        echo "power off $OUTPUT_DEVICE:\n"
        if [[ -n "$HASS_SWITCH" ]]; then
            curl -s -X POST -H "Authorization: Bearer $HASS_BEARER" \
                -H "Content-Type: application/json" \
                -d '{"entity_id": "'"$HASS_SWITCH"'"}' \
                http://$HASS_HOST/api/services/switch/turn_off
            echo "HASS switch: $HASS_SWITCH ..."
        fi
        if [[ -n "$GPIO_MUTE" ]]; then
            if [[ -n "$GPIO_AMP_MUTE_ON_PLAYERS" ]]; then
                echo "Mute on players ..."
                ALL_OFF=1
                IFS=\;
                for token in $GPIO_AMP_MUTE_ON_PLAYERS; do
                    if [[ -n "$token" ]]; then
                        # check power state via lms api
                        DATA='{"id": 1, "method": "slim.request", "params":["'"$token"'", ["power", "?"]]}'
                        POWER=$(curl -s -H 'Content-Type: application/json' -d "$DATA" http://$LMS_HOST/jsonrpc.js)
                        # empty result if player not registered
                        if [[ -n "$POWER" ]]; then
                            PLAYER_ON=$(echo $POWER | jq -r '.result._power' )
                            if [[ $PLAYER_ON == 1 ]]; then
                                ALL_OFF=0
                                break
                            fi
                        fi
                    fi
                done
                if [[ $ALL_OFF == 1 ]]; then
                    gpio write $GPIO_MUTE 1
                    echo "Mute: $GPIO_MUTE ..."
                fi
            else
                echo "Mute on GPIO ..."
                gpio write $GPIO_MUTE 1
                echo "Mute: $GPIO_MUTE ..."
            fi
        fi
        if [[ -n "$GPIO_SHUTDOWN" ]]; then
            if [[ -n "$GPIO_AMP_SHUTDOWN_ON_AMP_MUTE" ]]; then
                echo "Shutdown on mute ($GPIO_AMP_SHUTDOWN_ON_AMP_MUTE) ..."
                GPIO_ON=$(gpio read $GPIO_AMP_SHUTDOWN_ON_AMP_MUTE)
                if [[ $GPIO_ON == 1 ]]; then
                    gpio write $GPIO_SHUTDOWN 1
                    echo "Shutdown: $GPIO_SHUTDOWN ..."
                fi
            else
                echo "Shutdown on GPIO ..."
                gpio write $GPIO_SHUTDOWN 1
                echo "Shutdown: $GPIO_SHUTDOWN ..."
            fi
        fi
        if [[ -n "$GPIO_SPS" ]]; then
            gpio write $GPIO_SPS 0
            echo "SPS: $GPIO_SPS ..."
        fi
        if [[ -n "$GPIO_PSU_RELAY" ]]; then
            sleep 5
            ALL_OFF=1
            IFS=\;
            for token in $GPIO_PSU_RELAY_OFF_ON_AMP_SHUTDOWN; do
                if [[ -n "$token" ]]; then
                    GPIO_ON=$(gpio read $token)
                    if [[ $GPIO_ON == 0 ]]; then
                        ALL_OFF=0
                        break
                    fi
                fi
            done
            if [[ $ALL_OFF == 1 ]]; then
                gpio write $GPIO_PSU_RELAY 0
                echo "PSU relay: $GPIO_PSU_RELAY ..."
            fi
        fi
        echo "\n"
        ;;
esac

# release gpio lock
flock -u 200
