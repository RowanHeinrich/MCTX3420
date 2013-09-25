#!/bin/bash
# Use this to quickly test run the server in valgrind
#spawn-fcgi -p9005 -n ./valgrind.sh
# Use this to run the server normally
#./stream &

# Check running as root
if [ "$(whoami)" != "root" ]; then
	(echo "Run $0 as root.") 1>&2
	exit 1
fi

# Check existence of program
if [ ! -e "server" ]; then
	(echo "Rebuild server.") 1>&2;
	exit 1
fi

# Identify cape-manager slots
slot=$(echo /sys/devices/bone_capemgr.*/slots | awk '{print $1}')
pwm=/sys/class/pwm/

# Load PWM module
#modprobe pwm_test
(echo am33xx_pwm > $slot) 1>&2 >> /dev/null
#for port in P9_21 P9_22 P9_14 P9_16 P9_29 P9_31 P9_42 P8_13 P8_19 P8_34 P8_36 P8_45 P8_46; do
#	echo bone_pwm_$port > $slot
#done
echo 0 > $pwm/export
echo 1 > $pwm/export
echo bone_pwm_P9_21 > $slot
echo bone_pwm_P9_22 > $slot

# Load ADCs
(echo cape-bone-iio > $slot) 1>&2 >> /dev/null
# Find adc_device_path
# NOTE: This has to be passed as a parameter, because it is not always the same. For some unfathomable reason. Hooray.
adc_device_path=$(dirname $(find /sys -name *AIN0))


# Run the program with parameters
# TODO: Can tell spawn-fcgi to run the program as an unprivelaged user?
# But first will have to work out how to set PWM/GPIO as unprivelaged user
fails=0
while [ $fails -lt 10 ]; do
	spawn-fcgi -p9005 -n -- ./server -a "$adc_device_path"
	if [ "$?" == "0" ]; then
		exit 0
	fi
	fails=$(( $fails + 1 ))
	(echo "Restarting server after Fatal Error #$fails") 1>&2
	
done
(echo "Server had too many Fatal Errors ($fails)") 1>&2
exit $fails

