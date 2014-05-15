@echo off
:: Toshiba ac100 simple-repart script ver 0.2
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
set "config_8gb=android.cfg"
set "config_16gb=android.cfg"
set "config_32gb=android.cfg"
set "config=none" REM Detect later

:: Pregenerated mbr table files for new android setup
set "em1_img_8gb=8gb-EM1.gen"
set "em1_img_16gb=16gb-EM1.gen"
set "em1_img_32gb=32gb-EM1.gen"
set "em2_img_8gb=8gb-EM2.gen"
set "em2_img_16gb=16gb-EM2.gen"
set "em2_img_32gb=32gb-EM2.gen"
set "mbr_img_8gb=8gb-MBR.gen"
set "mbr_img_16gb=16gb-MBR.gen"
set "mbr_img_32gb=32gb-MBR.gen"
set "em1_img=none" REM Detect later
set "em2_img=none" REM Detect later
set "mbr_img=none" REM Detect later

:: Main Script
echo ---------------------------------------------------------------------
echo.
echo Welcome to the AC100 simple repartion script!
echo.
echo Using this script it is possible to:
echo 1. Create a Quick (partial) or Full backup of the AC100 eMMC
echo 2. Write an extended partition table config to the AC100 eMMC
echo 3. Restore the AC100 eMMC Quick (partial) or Full
echo.
echo NOTE: Use "Quick" options only if you do not care about your data
echo you may have on the AC100 eMMC!
echo.
echo REQUIREMENTS:
echo 1. Working nvflash usb connection
echo 2. Enough free space for backup files
echo.
echo ---------------------------------------------------------------------
echo.
echo Before continuing, connect your AC100 in nvflash mode using Ctrl+Esc!
echo.
echo ---------------------------------------------------------------------
echo.
choice /m "Are you ready to continue?"

if %errorlevel%==2 ( echo Come back then you are ready. & exit /b )

:: Disable clear screen for now to have full screen log
cls

:: Choose model by internal flash size
echo.
echo Please select the correct eMMC size for your AC100:
echo Press 1 if 8GB
echo Press 2 if 16GB
echo Press 3 if 32GB
echo.
choice /c 123

if %errorlevel%==1 (
::set	backup_last_partition_size=%backup_last_partition_8gb%
::set	write_last_partition_size=%write_last_partition_8gb%
set	config=%config_8gb%
set	em1_img=%em1_img_8gb% 
set	em2_img=%em2_img_8gb% 
set	mbr_img=%mbr_img_8gb% 
)

if %errorlevel%==2 (
::set	backup_last_partition_size=%backup_last_partition_16gb%
::set	write_last_partition_size=%write_last_partition_16gb%
set	config=%config_16gb%
set	em1_img=%em1_img_16gb% 
set	em2_img=%em2_img_16gb% 
set	mbr_img=%mbr_img_16gb%
)

if %errorlevel%==3 (
::set	backup_last_partition_size=%backup_last_partition_32gb%
::set	write_last_partition_size=%write_last_partition_32gb%
set	config=%config_32gb%
set	em1_img=%em1_img_32gb% 
set	em2_img=%em2_img_32gb% 
set	mbr_img=%mbr_img_32gb%
)

:: Choose phase
echo.
echo Please choose from the following options:
echo Use the options listed below if you want to save your data:
echo NOTE: These operations can take a while to complete!
echo.
echo Press 1 for a Full backup
echo Press 2 for a Full restore
echo.
echo Only use the options listed below if you have saved your data!
echo.
echo Press 3 for a Quick backup, repartion and Quick restore (RECOMMENDED)
echo Press 4 for a Quick backup only
echo Press 5 for repartitioning only
echo Press 6 for a Quick restore only
echo.
choice /c 123456

if %errorlevel%==1 (
:: Run FULL backup functions
call :bootloader
call :backup-full
call :create-bct
call :quit
)

if %errorlevel%==2 (
:: Run FULL restore functions
call :bootloader
call :restore-full
call :quit
)

if %errorlevel%==3 (
:: Run all functions
call :bootloader
call :backup
call :create-bct
call :need_reset
call :bootloader
call :repart
call :need_reset
call :bootloader
call :restore
call :quit
)
		
if %errorlevel%==4 (
:: Run backup functions
call :bootloader
call :backup
call :create-bct
call :quit
)

if %errorlevel%==5 (
:: Run repart functions
call :bootloader
call :create-bct
call :repart
call :quit
)

if %errorlevel%==6 (
:: Run restore functions
call :bootloader
call :restore
call :quit
)


:: Functions

:error
echo !!! %1 !!!
goto :eof


:quit
echo.
echo All operations complete. If there were any errors you may now view them above.
echo.
pause
exit


:backup
echo.
echo Dump essential partitions content to local disk
echo.
win\nvflash.exe -r --read 2 ac100-2.img --read 3 ac100-3.img --read 4 ac100-4.img --read 5 ac100-5.img --read 6 ac100-6.img 
if not %errorlevel%==0 ( call :error "Can't backup your AC100" & exit /b )
goto :eof


:backup-full
echo.
echo Dump all partitions content to local disk
echo.
win\nvflash.exe -r --read 2 ac100-2.img --read 3 ac100-3.img --read 4 ac100-4.img --read 5 ac100-5.img --read 6 ac100-6.img --read 7 ac100-7.img --read 8 ac100-8.img --read 9 ac100-9.img --read 10 ac100-10.img --read 11 ac100-11.img --read 12 ac100-12.img --read 13 ac100-13.img --read 14 ac100-14.img
if not %errorlevel%==0 ( call :error "Can't backup your AC100" & exit /b )
goto :eof


:create-bct
echo.
echo Create BCT file from first 4080 bytes of first image
win\dd.exe if=ac100-2.img of=ac100.bct bs=4080 count=1
if not %errorlevel%==0 ( call :error "Can't create BCT file" & exit /b )
goto :eof


:repart
echo.
echo Starting repartition phase...
echo.
win\nvflash.exe -r --bct ac100.bct --setbct --configfile "%config%" --create --verifypart -1 --go
if not %errorlevel%==0 ( call :error "Can't repartion your AC100" & exit /b )
goto :eof


:need_reset
echo.
echo Please shutdown your device by holding the power button
echo Then power on the device while holding Ctrl+Esc buttons
echo.
pause
goto :eof


:bootloader
echo.
echo Start fastboot bootloader...
win\nvflash.exe --bl bootloader.bin --go
if not %errorlevel%==0 ( call :error "Can't load bootloader into AC100" & exit /b )
goto :eof


:backup_part
win\nvflash.exe -r --getpartitiontable backup_part_table-"%Date%".txt --go
if not %errorlevel%==0 ( call :error "Can't create partition table backup" & exit /b )
goto :eof


:restore
echo.
echo Start Quick restore...
echo.
pause
echo.
echo Starting flash phase...
win\nvflash.exe -r --rawdevicewrite 0 1536 ac100-2.img --rawdevicewrite 1792 1024 ac100-4.img --rawdevicewrite 2816 2560 ac100-5.img --rawdevicewrite 5376 4096 ac100-6.img --rawdevicewrite 9472 512 "%mbr_img%" --rawdevicewrite 478208 256 "%em1_img%" --rawdevicewrite 2526464 256 "%em2_img%" --sync
if not %errorlevel%==0 ( call :error "Can't flash your AC100" & exit /b )
goto :eof


:restore-full
echo.
echo Start Full restore...
pause
echo.
echo Starting flash phase...
win\nvflash.exe -r --rawdevicewrite 0 1536 ac100-2.img --rawdevicewrite 1536 256 ac100-3.img --rawdevicewrite 1792 1024 ac100-4.img --download 5 ac100-5.img --download 6 ac100-6.img --download 7 ac100-7.img --download 8 ac100-8.img --download 9 ac100-9.img --download 10 ac100-10.img --download 11 ac100-11.img --download 12 ac100-12.img --download 13 ac100-13.img --download 14 ac100-14.img --sync
if not %errorlevel%==0 ( call :error "Can't flash your AC100" & exit /b )
goto :eof