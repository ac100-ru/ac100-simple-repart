#!/bin/bash
# Toshiba ac100 simple-repart script ver 0.1
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

last_partition_8gb=2876677 
last_partition_16gb=14628096 
last_partition_size=0 # Detect later

config_8gb="android-8gb.cfg"
config_16gb="android-32gb.cfg"
config="none" # Detect later


function error {
	echo -e "\n\e[00;31m$1\e[00m\n"
	exit 3
}


function backup {
	sudo ./nvflash --bl bootloader.bin --rawdeviceread 0 1536 ac100-2.img --rawdeviceread 1536 256 ac100-3.img --rawdeviceread 1792 1024 ac100-4.img --rawdeviceread 2816 2560 ac100-5.img --rawdeviceread 5376 4096 ac100-6.img --rawdeviceread 9984 153600 ac100-8.img --rawdeviceread 163584 204800 ac100-9.img --rawdeviceread 368384 1024 ac100-10.img --rawdeviceread 369664 632320 ac100-12.img --rawdeviceread 1002240 ${last_partition_size} ac100-14.img --go
	[[ $? == 0 ]] || error "Can't backup your ac100"
}


function create-bct {
	echo "
Press any key to continue to bct creation"
	read -n 1 any

	dd if=ac100-2.img of=ac100.bct bs=4080 count=1 
}


function repart {
	echo "
Press any key to continue to repartition phase"
	read -n 1 any

	sudo ./nvflash -r --bct ac100.bct --setbct --configfile "${config}" --create --verifypart -1 --go
	[[ $? == 0 ]] || error "Can't repart your ac100"
}


function restore {
	echo "
Press any key to continue to flash phase"
	read -n 1 any

	sudo ./nvflash -r --rawdevicewrite 0 1536 ac100-2.img --rawdevicewrite 1536 256 ac100-3.img --rawdevicewrite 1792 1024 ac100-4.img --sync
	[[ $? == 0 ]] || error "Can't restore your ac100"
}


# Main Script

echo -e "\e[00;34m
This script will: 
1. backup your ac100 internal flash partitions to files
2. write extended partition table config to ac100
3. restore backup files back to ac100
\e[00m \e[00;31m
REQUIREMENTS:
1. working nvflash connection
2. enough free space to backup files\e[00m
"
echo "Are you ready to continue? Press y or n:"
read -n 1 ready
echo -e "\n"

if [ "$ready" == "n" ]; then
 echo -e "Come back then you are ready."
 exit 1
fi

clear

echo "
What flash size of your ac100:
Press 1 if 8GB
Press 2 if 32GB"
read -n 1 version
echo -e "\n"

case $version in
	"1")
		last_partition_size="${last_partition_8gb}"
		config="${config_8gb}"
	;;

	"2")
		last_partition_size="${last_partition_32gb}"
		config="${config_32gb}"
	;;

	*)
		echo "Check your ac100 flash size"
		exit 2
	;;
esac

backup
create-bct
repart
restore

echo "Repartition finished. Reboot to verify."

