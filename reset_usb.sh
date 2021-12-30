service networking stop
sleep 5
echo 0 > /sys/devices/platform/soc/3f980000.usb/buspower
sleep 10
echo 1 > /sys/devices/platform/soc/3f980000.usb/buspower
sleep 5
service networking start