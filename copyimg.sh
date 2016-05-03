#!/bin/bash
#author Philon
#modified by SN4T14
#version 1.3

set -e
set -u

function get_devs() {
	echo $(ls /dev/ | grep "sd.$")
}
function get_dev_num() {
	echo $(get_devs | wc -w)
}
is_fromfile=false
source_dev=""
source_filepath=""
expected_dev_num=1

#Make sure dcfldd is installed
command -v dcfldd >/dev/null 2>&1 || {
	echo "dcfldd is not installed. Installing..."
	apt-get install dcfldd -y >/dev/null
}

#Make sure only the boot-drive is connected
if [ $(get_dev_num) -ne $expected_dev_num ]; then
	echo "Error: Unplug all extra drives before starting. "
	exit 3
fi
boot_dev=$(get_devs)

#Check whether image name passed as $1
if [ "$#" -eq 0 ]; then
	is_fromfile=false
	echo "copying from drive, execute as $0 image.img to copy from image"
else
	is_fromfile=true
fi

if [ $is_fromfile == false ]; then
	#wait for source drive to be plugged in
	echo "Plug in the source Drive!"
	expected_dev_num=2
	while true; do
		if [ $(get_dev_num) -eq $expected_dev_num ]; then
			for dev in $(get_devs) ; do
				if [ $dev != $boot_dev ]; then
					source_dev=$dev
				fi
			done
			break
		fi
		sleep 1
	done
else
	path="$1"
	if [ -z "$path" ]; then
		#Unreachable code? We already check if $# is 0
		echo >&2 "Error: File path may not be empty, execute as $0 <image>"
		exit 3
	fi
	source_filepath="$path"
fi

while true; do
	#wait for user to plug in destination drives
	echo "Plug in all destination drives!"
	read -p "Press enter when you're done..." d
	if [ $(get_dev_num) -eq $expected_dev_num ]; then
		echo "No destination drives found!"
		continue
	else
		read -p "Found $(expr $(get_dev_num) - $expected_dev_num) drives, correct? [y/n] " correct

		if [ "$correct" != "y" ]; then
			continue
		fi
	fi

	#build copy command
	copy_cmd=""
	if [ $is_fromfile == false ]; then
		copy_cmd="time dcfldd bs=4k if=/dev/$source_dev"
		for dev in $(get_devs) ; do
			if [ $dev != $boot_dev ] && [ $dev != $source_dev ]; then
				copy_cmd="$copy_cmd of=/dev/$dev"
			fi
		done
	else
		copy_cmd="time dcfldd bs=4k if=$source_filepath"
		for dev in $(get_devs) ; do
			if [ $dev != $boot_dev ]; then
				copy_cmd="$copy_cmd of=/dev/$dev"
			fi
		done
	fi

	#execute
	echo "Starting to copy...."
	eval $copy_cmd
	echo "done! Lets copy some more..."
done

exit 0
