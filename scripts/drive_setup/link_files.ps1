# Check for admin rights
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script requires administrator privileges." -ForegroundColor Yellow
    Write-Host "Relaunching with elevated privileges..." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Display main menu
function Show-Menu {
    Clear-Host
    Write-Host "================ Main Menu ================"
    Write-Host "1. Install custom boot and sleep mode"
    Write-Host "2. Manually create a symbolic link for emulation save or specific folders"
    Write-Host "==========================================="
}

function Option1 {
    Add-Type -AssemblyName System.Windows.Forms

    # Set target directory (adapts to user)
    $targetDir = "C:\Users\$env:USERNAME\Documents\Drive\Scripts"
    
    # Create folder if it doesn't exist
    if (-not (Test-Path $targetDir)) {
        New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
        Write-Host "Creating Scripts folder: $targetDir"
    }

    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Select the folder to create 'Sleep' and 'Boot' subfolders in"

    if ($folderBrowser.ShowDialog() -eq "OK") {
        $selectedPath = $folderBrowser.SelectedPath
        $sleepPath = Join-Path $selectedPath "Sleep"
        $bootPath = Join-Path $selectedPath "Boot"

        if (-not (Test-Path $sleepPath)) {
            New-Item -Path $sleepPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path $bootPath)) {
            New-Item -Path $bootPath -ItemType Directory -Force | Out-Null
        }

        Write-Host "'Sleep' and 'Boot' folders created in: $selectedPath"
    } else {
        Write-Host "No folder selected."
        Pause
        return
    }

    # Install VLC
    Write-Host "Installing VLC Media Player..."
    try {
        $vlcInstall = Start-Process -FilePath "winget" -ArgumentList 'install --id=VideoLAN.VLC -e --silent' -Wait -PassThru -NoNewWindow
        if ($vlcInstall.ExitCode -eq 0) {
            Write-Host "VLC installed successfully."
        } else {
            Write-Host "VLC installation error. Code: $($vlcInstall.ExitCode)"
            Pause
            return
        }
    } catch {
        Write-Host "Error installing VLC: $_"
        Pause
        return
    }

    # Locate VLC path
    $vlcExe = Get-ChildItem -Path "$env:ProgramFiles\VideoLAN\VLC\vlc.exe" -ErrorAction SilentlyContinue
    if (-not $vlcExe) {
        $vlcExe = Get-ChildItem -Path "$env:ProgramFiles(x86)\VideoLAN\VLC\vlc.exe" -ErrorAction SilentlyContinue
    }
    if (-not $vlcExe) {
        Write-Host "Unable to locate vlc.exe."
        Pause
        return
    }
    $vlcPath = $vlcExe.FullName

    # Download files from GitHub
    $githubBaseUrl = "https://raw.githubusercontent.com/Sanko-kf/pc-to-console/main/scripts/"
    
    # Files to download
    $filesToDownload = @(
        @{Name = "sleep_mode_detector.exe"; Path = Join-Path $targetDir "sleep_mode_detector.exe"},
        @{Name = "stop_sleep_mod.bat"; Path = Join-Path $targetDir "stop_sleep_mod.bat"}
    )

    foreach ($file in $filesToDownload) {
        if (-not (Test-Path $file.Path)) {
            Write-Host "Downloading $($file.Name) to $targetDir..." -ForegroundColor Cyan
            try {
                Invoke-WebRequest -Uri ($githubBaseUrl + $file.Name) -OutFile $file.Path -ErrorAction Stop
                Write-Host "$($file.Name) downloaded successfully." -ForegroundColor Green
            } catch {
                Write-Host "Failed to download $($file.Name): $_" -ForegroundColor Red
                Pause
                return
            }
        } else {
            Write-Host "$($file.Name) already exists in $targetDir." -ForegroundColor Green
        }
    }

    # Verify files exist
    if (-not (Test-Path (Join-Path $targetDir "sleep_mode_detector.exe"))) {
        Write-Host "sleep_mode_detector.exe not found in $targetDir"
        Pause
        return
    }

    if (-not (Test-Path (Join-Path $targetDir "stop_sleep_mod.bat"))) {
        Write-Host "stop_sleep_mod.bat not found in $targetDir"
        Pause
        return
    }

    # Create additional BAT files in target directory
    # sleep_mode.bat
    $sleepBatPath = Join-Path $targetDir "sleep_mode.bat"
    $sleepBat = @(
        '@echo off'
        "set ""videosFolder=$sleepPath"""
        "set ""vlcPath=$vlcPath"""
        'start "" "%vlcPath%" --fullscreen --random "%videosFolder%"'
        'exit /b'
    ) -join "`r`n"
    Set-Content -Path $sleepBatPath -Value $sleepBat -Encoding ASCII
    Write-Host "✅ sleep_mode.bat created: $sleepBatPath"

    # custom_steam_boot.bat
    $bootBatPath = Join-Path $targetDir "custom_steam_boot.bat"
    $customBootPath = $bootBatPath
    $bootBat = @(
        '@echo off'
        'setlocal enabledelayedexpansion'
        "set ""boot_folder=$bootPath"""
        'set "steam_folder=C:\Program Files (x86)\Steam\steamui\movies"'
        'set "count=0"'
        'for %%f in ("%boot_folder%\*.webm") do ('
        '    set /a count+=1'
        '    set "boot!count!=%%f"'
        ')'
        'if %count% equ 0 exit /b'
        'set /a "random_num=%random% %% %count% + 1"'
        'set "random_boot=!boot%random_num%!"'
        'copy /y "!random_boot!" "%steam_folder%\bigpicture_startup.webm" >nul 2>&1'
        'exit'
    ) -join "`r`n"
    Set-Content -Path $bootBatPath -Value $bootBat -Encoding ASCII
    Write-Host "custom_steam_boot.bat created: $bootBatPath"

    # SleepModeDetector Task
    $taskName1 = "SleepModeDetector"
    $taskExists1 = Get-ScheduledTask -TaskName $taskName1 -ErrorAction SilentlyContinue

    if (-not $taskExists1) {
        Write-Host "Creating scheduled task: $taskName1..." -ForegroundColor Cyan
        try {
            $action1 = New-ScheduledTaskAction -Execute (Join-Path $targetDir "sleep_mode_detector.exe") -ErrorAction Stop
            $trigger1 = New-ScheduledTaskTrigger -AtLogOn -ErrorAction Stop
            $settings1 = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ErrorAction Stop

            Register-ScheduledTask -TaskName $taskName1 `
                -Action $action1 `
                -Trigger $trigger1 `
                -Settings $settings1 `
                -RunLevel "Highest" `
                -Force `
                -ErrorAction Stop | Out-Null

            Write-Host "Scheduled task '$taskName1' created successfully." -ForegroundColor Green
        } catch {
            Write-Host "Error creating task '$taskName1': $_" -ForegroundColor Red
            Pause
            return
        }
    } else {
        Write-Host "Task '$taskName1' already exists." -ForegroundColor Yellow
    }

    # CustomSteamBoot Task
    $taskName2 = "CustomSteamBoot"
    $taskExists2 = Get-ScheduledTask -TaskName $taskName2 -ErrorAction SilentlyContinue

    if (-not $taskExists2) {
        Write-Host "Creating scheduled task: $taskName2..." -ForegroundColor Cyan
        try {
            $action2 = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c `"$customBootPath`"" -ErrorAction Stop
            $trigger2 = New-ScheduledTaskTrigger -AtLogOn -ErrorAction Stop
            $settings2 = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ErrorAction Stop

            Register-ScheduledTask -TaskName $taskName2 `
                -Action $action2 `
                -Trigger $trigger2 `
                -Settings $settings2 `
                -RunLevel "Highest" `
                -Force `
                -ErrorAction Stop | Out-Null

            Write-Host "Scheduled task '$taskName2' created successfully." -ForegroundColor Green
        } catch {
            Write-Host "Error creating task '$taskName2': $_" -ForegroundColor Red
            Pause
            return
        }
    } else {
        Write-Host "Task '$taskName2' already exists." -ForegroundColor Yellow
    }

    Write-Host "All operations completed in: $targetDir" -ForegroundColor Green
    Write-Host "Installed files:"
    Write-Host "- sleep_mode_detector.exe"
    Write-Host "- stop_sleep_mod.bat" 
    Write-Host "- sleep_mode.bat"
    Write-Host "- custom_steam_boot.bat"
    Write-Host "Scheduled tasks created successfully."

    # Disable sleep and hibernation
    try {
        powercfg -change standby-timeout-ac 0
        powercfg -change standby-timeout-dc 0
        powercfg -h off
        Write-Host "Sleep and hibernation disabled."
    } catch {
        Write-Host "Error disabling sleep/hibernation: $_"
    }

    Pause
}

function Option2 {
    Add-Type -AssemblyName System.Windows.Forms

    do {
        Clear-Host
        Write-Host "=== Create Symlink for FOLDER ==="

        # Select source folder
        $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog -Property @{
            Description = "Select the FOLDER to link"
            ShowNewFolderButton = $false
        }
        
        if ($folderDialog.ShowDialog() -ne 'OK') {
            Write-Host "Operation cancelled." -ForegroundColor Yellow
            break
        }
        $target = $folderDialog.SelectedPath
        $folderName = [System.IO.Path]::GetFileName($target)

        # Select destination folder
        $destDialog = New-Object System.Windows.Forms.FolderBrowserDialog -Property @{
            Description = "Select where to create the link '$folderName'"
            ShowNewFolderButton = $true
        }
        
        if ($destDialog.ShowDialog() -ne 'OK') {
            Write-Host "Operation cancelled." -ForegroundColor Yellow
            break
        }

        $linkPath = Join-Path -Path $destDialog.SelectedPath -ChildPath $folderName

        # Create symlink
        try {
            if (Test-Path -Path $linkPath) {
                Remove-Item -Path $linkPath -Force -Recurse
            }
            New-Item -ItemType SymbolicLink -Path $linkPath -Target $target -Force | Out-Null
            Write-Host "Link successfully created!" -ForegroundColor Green
            Write-Host "[Link] $linkPath" -ForegroundColor Cyan
            Write-Host "[Target] $target" -ForegroundColor Cyan
        }
        catch {
            Write-Host "ERROR: $_" -ForegroundColor Red
        }

        $choice = Read-Host "`nCreate another link? (Y/N)"
    } while ($choice -eq "Y" -or $choice -eq "y")
}

# Run main program
try {
    Clear-Host
    Show-Menu
    $selection = Read-Host "Enter your choice (1 or 2)"

    switch ($selection) {
        '1' { Option1 }
        '2' { Option2 }
        default { 
            Write-Host "Invalid option - Exiting script." -ForegroundColor Red
            Exit 1
        }
    }
}
catch {
    Write-Host "A critical error occurred: $_" -ForegroundColor Red
    Exit 1
}
