@echo off
:: Toshiba ac100 simple-repart script ver 0.1
::
:: This program is free software: you can redistribute it and/or modify
:: it under the terms of the GNU General Public License as published by
:: the Free Software Foundation, either version 3 of the License, or
:: (at your option) any later version.
::
:: This program is distributed in the hope that it will be useful,
:: but WITHOUT ANY WARRANTY; without even the implied warranty of
:: MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
:: GNU General Public License for more details.
::
:: You should have received a copy of the GNU General Public License
:: along with this program.  If not, see <http://www.gnu.org/licenses/>.

:: Variables
:: Number of sectors for last partition in stock partition setup
set "backup_last_partition_8gb=2876672" 
set "backup_last_partition_32gb=14628096" 
set "backup_last_partition_size=0" REM Detect later

:: Number of sectors for last partition in new android setup
set "write_last_partition_8gb=1352192"
set "write_last_partition_32gb=13103616" 
set "write_last_partition_size=0" REM Detect later

set "config_8gb=android.cfg"
set "config_32gb=android.cfg"
set "config=none" REM Detect later

:: Pregenerated mbr table files for new android setup
set "em1_img_8gb=8gb-EM1.gen"
set "em1_img_32gb=32gb-EM1.gen"
set "em2_img_8gb=8gb-EM2.gen"
set "em2_img_32gb=32gb-EM2.gen"
set "mbr_img_8gb=8gb-MBR.gen"
set "mbr_img_32gb=32gb-MBR.gen"
set "em1_img=none" REM Detect later
set "em2_img=none" REM Detect later
set "mbr_img=none" REM Detect later

:: Main Script
echo.
echo This script will: 
echo 1. backup your ac100 internal flash partitions to files
echo 2. write extended partition table config to ac100
echo 3. restore backup files back to ac100
echo.
echo REQUIREMENTS:
echo 1. working nvflash usb connection
echo 2. enough free space for backup files
echo.
choice /m "Are you ready to continue?"

if %errorlevel%==2 ( echo Come back then you are ready. & exit /b )

:: Disable clear screen for now to have full screen log
:: cls

:: Choose model by internal flash size
echo.
echo What flash size of your ac100:
echo Press 1 if 8GB
echo Press 2 if 32GB"
choice /c 12

if %errorlevel%==1 (
set	backup_last_partition_size=%backup_last_partition_8gb%
set	write_last_partition_size=%write_last_partition_8gb%
set	config=%config_8gb%
set	em1_img=%em1_img_8gb% 
set	em2_img=%em2_img_8gb% 
set	mbr_img=%mbr_img_8gb% 
)

if %errorlevel%==2 (
set	backup_last_partition_size=%backup_last_partition_32gb%
set	write_last_partition_size=%write_last_partition_32gb%
set	config=%config_32gb%
set	em1_img=%em1_img_32gb% 
set	em2_img=%em2_img_32gb% 
set	mbr_img=%mbr_img_32gb%
)

:: Choose phase
echo.
echo What to do:
echo Press 1 for backup stock partition, then repart, then restore backup
echo Press 2 for backup only
echo Press 3 for repart only
echo Press 4 for restore backup only"
choice /c 1234

if %errorlevel%==1 (
:: Run all functions
call :bootloader
call :backup_part
call :backup
call :create-bct
call :repart
call :need_reset
call :bootloader
call :restore
call :quit
)
		
if %errorlevel%==2 (
:: Run backup functions
call :bootloader
call :backup_part
call :backup
call :create-bct
call :quit
)

if %errorlevel%==3 (
:: Run repart functions
call :bootloader
call :repart
call :need_reset
call :quit
)

if %errorlevel%==4 (
:: Run restore functions
call :bootloader
call :restore
call :quit
)

echo "Repartition finished. Reboot to verify."

exit /b

:: Functions
:error
echo !!! %1 !!!
goto :eof

:quit
echo.
echo Bye!
echo.
goto :eof

:: Dump all partitions content to local disk
:backup
win\nvflash.exe -r --rawdeviceread 0 1536 ac100-2.img --rawdeviceread 1536 256 ac100-3.img --rawdeviceread 1792 1024 ac100-4.img --read 5 ac100-5.img --read 6 ac100-6.img --read 8 ac100-8.img --read 9 ac100-9.img --read 10 ac100-10.img --read 12 ac100-12.img --go
::win\nvflash.exe -r --rawdeviceread 0 1536 ac100-2.img --rawdeviceread 1536 256 ac100-3.img --rawdeviceread 1792 1024 ac100-4.img --rawdeviceread 2816 2560 ac100-5.img --rawdeviceread 5376 4096 ac100-6.img --rawdeviceread 9984 153600 ac100-8.img --rawdeviceread 163584 204800 ac100-9.img --rawdeviceread 368384 1024 ac100-10.img --rawdeviceread 369664 632320 ac100-12.img --go
::--rawdeviceread 1002240 ${backup_last_partition_size} ac100-14.img --go
if not %errorlevel%==0 ( call :error "Can't backup your ac100" & exit /b )
goto :eof

:: Create bct file from first 4080 bytes of first image
:create-bct 
echo.
echo Creating bct...
pause

win\dd.exe if=ac100-2.img of=ac100.bct bs=4080 count=1
if not %errorlevel%==0 ( call :error "Can't create bct" & exit /b )
goto :eof

:: Change partition table with predefined config file
:repart 
echo.
echo Starting repartition phase...
pause

win\nvflash.exe -r --bct ac100.bct --setbct --configfile "%config%" --create --verifypart -1 --go
if not %errorlevel%==0 ( call :error "Can't repart your ac100" & exit /b )
goto :eof

:need_reset 
echo.
echo After last operation you need to reset yout AC100 with power button to nvflash mode again
echo.
goto :eof

:bootloader 
echo Remember if you already started booloader you to restart ac100 to apx mode again. 
echo Start fastboot booloader...
win\nvflash.exe --bl bootloader.bin --go
if not %errorlevel%==0 ( call :error "Can't load bootloader into ac100" & exit /b )
goto :eof

:backup_part
win\nvflash.exe -r --getpartitiontable backup_part_table-%Date%.txt --go
if not %errorlevel%==0 ( call :error "Can't create partition table backup" & exit /b )
goto :eof

:: Flash backup files from local files to device
:restore 
echo.
echo Starting flash phase...
pause

win\nvflash.exe -r --rawdevicewrite 0 1536 ac100-2.img --rawdevicewrite 1792 1024 ac100-4.img --rawdevicewrite 2816 2560 ac100-5.img --rawdevicewrite 5376 4096 ac100-6.img --rawdevicewrite 9472 512 "%mbr_img%" --rawdevicewrite 478208 256 "%em1_img%" --rawdevicewrite 2526464 256 "%em2_img%" --sync
::--rawdevicewrite 1536 256 ac100-3.img --rawdevicewrite 9984 262400 ac100-8.img --rawdevicewrite 272384 204800 ac100-9.img --rawdevicewrite 477184 1024 ac100-10.img --rawdevicewrite 478208 256 "${em1_img}" --rawdevicewrite 478464 2048000 ac100-12.img --rawdevicewrite 2526464 256 "${em2_img}" --rawdevicewrite 252672 ${write_last_partition_size} ac100-14.img --sync
if not %errorlevel%==0 ( call :error "Can't flash your ac100" & exit /b )
goto :eof

