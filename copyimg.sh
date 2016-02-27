#!/bin/bash
#author Philon
#version 1.2

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

#Ask if to copy from drive or file
read -p "Copy from drive [d] or file [f]? " df
if [ $df == "d" ]; then
	is_fromfile=false
elif [ $df == "f" ]; then
	is_fromfile=true
else
	echo >&2 "Error: Invalid option given, aborting..."
	exit 3
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
	#ask which file to copy
	read -p "Enter path to the source file: " path
	if [ -z "$path" ]; then
		echo >&2 "Error: File path may not be empty"
		exit 3
	fi
	source_filepath="$path"
fi

while true; do
	#wait for user to plug in destination drives
	echo "Plug in all destination drives!"
	read -p "Press enter when you're done..." d
	if [ $(get_dev_num) -eq $expected_dev_num ]; then
		echo "No destination drives found, aborting!"
		exit 3
	fi

	#build copy command
	copy_cmd=""
	if [ $is_fromfile == false ]; then
		#copy_cmd="cat bs=4k /dev/$source_dev | tee"
		copy_cmd="dcfldd bs=4k if=/dev/$source_dev"
		for dev in $(get_devs) ; do
			if [ $dev != $boot_dev ] && [ $dev != $source_dev ]; then
				#copy_cmd="$copy_cmd >(dd of=/dev/$dev)"
				copy_cmd="$copy_cmd of=/dev/$dev"
			fi
		done
		#copy_cmd="$copy_cmd >/dev/null"
	else
		copy_cmd="dcfldd bs=4k if=$source_filepath"
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
