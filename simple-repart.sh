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

# Variables
# Number of sectors for last partition in stock partition setup
backup_last_partition_8gb=2876677 
backup_last_partition_32gb=14628096 
backup_last_partition_size=0 # Detect later

# Number of sectors for last partition in new android setup
write_last_partition_8gb=1352192
write_last_partition_32gb=13103616 
write_last_partition_size=0 # Detect later

config_8gb="android.cfg"
config_32gb="android.cfg"
config="none" # Detect later

# Pregenerated mbr table files for new android setup
em1_img_8gb="EM1-8gb.gen"
em1_img_32gb="EM1-32gb.gen"
em2_img_8gb="EM2-8gb.gen"
em2_img_32gb="EM2-32gb.gen"
mbr_img_8gb="MBR-8gb.gen"
mbr_img_32gb="MBR-32gb.gen"
em1_img="none" # Detect later
em2_img="none" # Detect later
mbr_img="none" # Detect later


# Functions
function error {
	echo -e "\n\e[00;31m$1\e[00m\n"
	exit 3
}

function quit {
	echo "Bye"
	exit 4
}

# Dump all partitions content to local disk
function backup {
	sudo ./nvflash -r --rawdeviceread 0 1536 ac100-2.img --rawdeviceread 1536 256 ac100-3.img --rawdeviceread 1792 1024 ac100-4.img --rawdeviceread 2816 2560 ac100-5.img --rawdeviceread 5376 4096 ac100-6.img --rawdeviceread 9984 153600 ac100-8.img --rawdeviceread 163584 204800 ac100-9.img --rawdeviceread 368384 1024 ac100-10.img --rawdeviceread 369664 632320 ac100-12.img --go
#--rawdeviceread 1002240 ${backup_last_partition_size} ac100-14.img --go
	[[ $? == 0 ]] || error "Can't backup your ac100"
}

# Create bct file from first 4080 bytes of first image
function create-bct {
	echo "
Press any key to create bct"
	read -n 1 any

	dd if=ac100-2.img of=ac100.bct bs=4080 count=1
	[[ $? == 0 ]] || error "Can't create bct"
}

# Change partition table with predefined config file
function repart {
	echo "
Press any key to start repartition phase"
	read -n 1 any

	sudo ./nvflash -r --bct ac100.bct --setbct --configfile "${config}" --create --verifypart -1 --go
	[[ $? == 0 ]] || error "Can't repart your ac100"
}

function need_reset {
	echo "
\e[00;31mAfter last operation you need to reset yout AC100 with power button to nvflash mode again\e[00m"
}

function bootloader {
	echo "Start fastboot booloader..."
	sudo ./nvflash --bl bootloader.bin --go
	[[ $? == 0 ]] || error "Can't load bootloader into ac100"
}

function backup_part {
	sudo ./nvflash -r --getpartitiontable backup_part_table-`date +%F_%T`.txt --go
	[[ $? == 0 ]] || error "Can't create partition table backup"
}

# Flash backup files from local files to device
function restore {
	echo "
Press any key to start flash phase"
	read -n 1 any

	sudo ./nvflash -r --rawdevicewrite 0 1536 ac100-2.img --rawdevicewrite 1536 256 ac100-3.img --rawdevicewrite 1792 1024 ac100-4.img --rawdevicewrite 2816 2560 ac100-5.img --rawdevicewrite 5376 4096 ac100-6.img --rawdevicewrite 9472 512 "${mbr_img}" --rawdevicewrite 9984 262400 ac100-8.img --rawdevicewrite 272384 204800 ac100-9.img --rawdevicewrite 477184 1024 ac100-10.img --rawdevicewrite 477184 256 "${em1_img}" --rawdevicewrite 478464 2048000 ac100-12.img --rawdevicewrite 2526464 256 "${em2_img}" --sync
#--rawdevicewrite 252672 ${write_last_partition_size} ac100-14.img --sync
	[[ $? == 0 ]] || error "Can't flash your ac100"
}


# Main Script
echo -e "\e[00;34m
This script will: 
1. backup your ac100 internal flash partitions to files
2. write extended partition table config to ac100
3. restore backup files back to ac100
\e[00m \e[00;31m
REQUIREMENTS:
1. working nvflash usb connection
2. enough free space for backup files
3. working sudo\e[00m
"
echo "Are you ready to continue? Press y or n:"
read -n 1 ready
echo -e "\n"

if [ "$ready" == "n" ]; then
 echo -e "Come back then you are ready."
 exit 1
fi

# Disable clear screen for now to have full screen log
#clear

# Choose model by internal flash size
echo "
What flash size of your ac100:
Press 1 if 8GB
Press 2 if 32GB"
read -n 1 version
echo -e "\n"

case $version in
	"1")
		backup_last_partition_size="${backup_last_partition_8gb}"
		write_last_partition_size="${write_last_partition_8gb}"
		config="${config_8gb}"
		em1_img="${em1_img_8gb}" 
		em2_img="${em2_img_8gb}" 
		mbr_img="${mbr_img_8gb}" 
	;;

	"2")
		backup_last_partition_size="${backup_last_partition_32gb}"
		write_last_partition_size="${write_last_partition_32gb}"
		config="${config_32gb}"
		em1_img="${em1_img_32gb}" 
		em2_img="${em2_img_32gb}" 
		mbr_img="${mbr_img_32gb}"
	;;

	*)
		echo "Check your ac100 flash size"
		exit 2
	;;
esac

# Choose phase
echo "
What to do:
Press 1 for backup stock partition, then repart, then restore backup
Press 2 for backup only
Press 3 for repart only
Press 4 for restore backup only"
read -n 1 phase
echo -e "\n"


case $phase in
	"1")	
		# Run all functions
		bootloader
		backup_part
		backup
		create-bct
		repart
		need_reset
		bootloader
		restore
		quit
	;;

	"2")
		# Run backup functions
		bootloader
		backup_part
		backup
		create-bct
		quit
	;;


	"3")
		# Run repart functions
		bootloader
		repart
		need_reset
		quit
	;;

	"4")
		# Run restore functions
		bootloader
		restore
		quit
	;;

	*)
		echo "Make right choice"
		exit 5
	;;
esac
echo "Repartition finished. Reboot to verify."

