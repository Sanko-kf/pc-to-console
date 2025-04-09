@echo off
:: Path to the folder containing videos
set "videosFolder=(ADD_PATH)"

:: Path to VLC player
set "vlcPath=(ADD_PATH)"

:: Launch VLC with the video folder in shuffle mode and fullscreen
start "" "%vlcPath%" --fullscreen --random "%videosFolder%"

:: End of script
exit /b