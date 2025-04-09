@echo off
setlocal enabledelayedexpansion

:: Path to the folder containing boot files
set "boot_folder=(ADD_PATH)"

:: Path to the Steam folder where the boot file should be copied
set "steam_folder=C:\Program Files (x86)\Steam\steamui\movies"

:: List all boot files in the folder
set "count=0"
for %%f in ("%boot_folder%\*.webm") do (
    set /a count+=1
    set "boot!count!=%%f"
)

:: Check if there are any boot files
if %count% equ 0 exit /b

:: Generate a random number between 1 and the file count
set /a "random_num=%random% %% %count% + 1"

:: Select the random boot file
set "random_boot=!boot%random_num%!"

:: Copy the selected boot file to the Steam folder
copy /y "!random_boot!" "%steam_folder%\bigpicture_startup.webm" >nul 2>&1

:: Close the command window without displaying any message
exit