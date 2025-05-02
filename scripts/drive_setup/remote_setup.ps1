# Check for admin rights
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script requires administrator privileges." -ForegroundColor Yellow
    Write-Host "Relaunching with elevated privileges..." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Global Variables
$rclonePath = "$env:USERPROFILE\rclone\rclone-v1.69.1-windows-amd64"
$drivesFolder = Join-Path -Path $env:USERPROFILE -ChildPath "Documents\Drive"

# Function to display the main menu
function Show-Menu {
    Clear-Host
    Write-Host "================ Rclone Manager ================"
    Write-Host "1. Install prerequisites (WinFSP + Rclone + Git scripts)"
    Write-Host "2. Create a new Google Drive remote"
    Write-Host "3. Mount remote and create links"
    Write-Host "4. Exit"
    Write-Host "================================================"
}

# Function to install prerequisites (WinFSP, Rclone, Git scripts)
function Install-Prerequisites {
    # Installation variables
    $rcloneUrl = "https://downloads.rclone.org/v1.69.1/rclone-v1.69.1-windows-amd64.zip"
    $rcloneZip = "$env:USERPROFILE\rclone.zip"
    $extractTo = "$env:USERPROFILE\rclone"
    $winfspUrl = "https://github.com/winfsp/winfsp/releases/download/v2.0/winfsp-2.0.23075.msi"
    $winfspInstaller = "$env:TEMP\winfsp-installer.msi"

    # Download and install WinFSP
    Write-Host "Downloading WinFSP..."
    Invoke-WebRequest -Uri $winfspUrl -OutFile $winfspInstaller -ErrorAction Stop

    Write-Host "Installing WinFSP..."
    Start-Process -FilePath $winfspInstaller -Args "/quiet" -Wait -ErrorAction Stop
    Remove-Item $winfspInstaller -ErrorAction SilentlyContinue

    # Download and extract Rclone
    Write-Host "Downloading Rclone..."
    Invoke-WebRequest -Uri $rcloneUrl -OutFile $rcloneZip -ErrorAction Stop
    Expand-Archive -Path $rcloneZip -DestinationPath $extractTo -Force -ErrorAction Stop
    Remove-Item $rcloneZip -ErrorAction SilentlyContinue

    # Add Rclone to PATH
    [Environment]::SetEnvironmentVariable("PATH", "$env:PATH;$rclonePath", "User")
    $env:PATH = "$env:PATH;$rclonePath"

    # Configure paths and URLs
    $scriptsDir = Join-Path -Path ([Environment]::GetFolderPath("MyDocuments")) -ChildPath "Drive\Scripts"
    $exeFile = Join-Path -Path $scriptsDir -ChildPath "mount_remotes.exe"
    $linkScript = Join-Path -Path $scriptsDir -ChildPath "link_files.ps1"
    
    # URLs for raw.githubusercontent.com
    $exeUrl = "https://raw.githubusercontent.com/Sanko-kf/pc-to-console/main/scripts/drive_setup/mount_remotes.exe"
    $linkScriptUrl = "https://raw.githubusercontent.com/Sanko-kf/pc-to-console/main/scripts/drive_setup/link_files.ps1"

    # Create the scripts directory if it doesn't exist
    if (-not (Test-Path $scriptsDir)) {
        New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
        Write-Host "Scripts directory created: $scriptsDir" -ForegroundColor Cyan
    }

    # Download mount_remotes.exe if it doesn't exist
    if (-not (Test-Path $exeFile)) {
        Write-Host "Downloading mount_remotes.exe..." -ForegroundColor Cyan
        try {
            Invoke-WebRequest -Uri $exeUrl -OutFile $exeFile
            Write-Host "Download complete." -ForegroundColor Green
        } catch {
            Write-Host "Failed to download mount_remotes.exe: $_" -ForegroundColor Red
            Pause
            return
        }
    }

    # Download link_files.ps1 if it doesn't exist
    if (-not (Test-Path $linkScript)) {
        Write-Host "Downloading link_files.ps1..." -ForegroundColor Cyan
        try {
            Invoke-WebRequest -Uri $linkScriptUrl -OutFile $linkScript
            Write-Host "Download complete." -ForegroundColor Green
        } catch {
            Write-Host "Failed to download link_files.ps1: $_" -ForegroundColor Yellow
            # Proceed anyway since this is not critical
        }
    }

    # Create a scheduled task to run on startup
    $taskName = "Mount Remotes Startup"
    $taskExists = Get-ScheduledTask | Where-Object { $_.TaskName -eq $taskName }
 
    if (-not $taskExists) {
        Write-Host "Creating scheduled task for automatic startup..." -ForegroundColor Cyan
        try {
            $action = New-ScheduledTaskAction -Execute $exeFile -WorkingDirectory $scriptsDir
            $trigger = New-ScheduledTaskTrigger -AtLogOn
            $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable
             
            Register-ScheduledTask -TaskName $taskName `
                -Action $action `
                -Trigger $trigger `
                -Settings $settings `
                -RunLevel "Highest" `
                -Force | Out-Null
 
            Write-Host "Scheduled task created successfully!" -ForegroundColor Green
        } catch {
            Write-Host "Error creating scheduled task: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "Scheduled task already exists" -ForegroundColor Yellow
    }
 
    Write-Host "Operations completed successfully!" -ForegroundColor Green
    Pause
}

# Function to create a new Google Drive remote
function Create-Remote {
    if (-not (Test-Path "$rclonePath\rclone.exe")) {
        Write-Host "Rclone is not installed. Please install the prerequisites first." -ForegroundColor Red
        Pause
        return
    }

    Write-Host "Setting up a new Google Drive remote..."
    & "$rclonePath\rclone.exe" authorize "drive"
    $remoteName = Read-Host "Enter the remote name (e.g., 'gdrive')"
    $token = Read-Host "Paste the token here"
    & "$rclonePath\rclone.exe" config create $remoteName drive token="$token"

    # Create the base folder for this remote
    $remoteFolder = Join-Path -Path $drivesFolder -ChildPath $remoteName
    New-Item -ItemType Directory -Path $remoteFolder -Force | Out-Null

    Write-Host "Remote $remoteName created successfully!" -ForegroundColor Green
    Pause
}

# Function to start the drive and create links
function Start-DriveAndLinks {
    # Define user base directory path
    $scriptDir = Join-Path $env:USERPROFILE "Documents\Drive\Scripts"
    $exeFile = Join-Path $scriptDir "mount_remotes.exe"
    $psScript = Join-Path $scriptDir "link_files.ps1"

    # Check if the files exist
    if (-not (Test-Path $exeFile)) {
        Write-Host "Executable file not found: $exeFile" -ForegroundColor Red
        Pause
        return
    }

    if (-not (Test-Path $psScript)) {
        Write-Host "PowerShell script not found: $psScript" -ForegroundColor Red
        Pause
        return
    }

    # Display debug information
    Write-Host "Launching $exeFile" -ForegroundColor Cyan
    Write-Host "Working directory: $scriptDir" -ForegroundColor Cyan

    try {
        # Launch mount_remotes.exe with admin privileges
        $exeArgs = @{
            FilePath         = $exeFile
            Verb             = "RunAs"
            Wait             = $false
            ErrorAction      = "Stop"
            WindowStyle      = "Normal"
            WorkingDirectory = $scriptDir
        }

        $exeProcess = Start-Process @exeArgs -PassThru

        # Now run the PowerShell script
        Write-Host "Launching $psScript" -ForegroundColor Cyan

        $psArgs = @{
            FilePath         = "powershell.exe"
            ArgumentList     = "-NoProfile -ExecutionPolicy Bypass -File `"$psScript`""
            Wait             = $true
            ErrorAction      = "Stop"
            WindowStyle      = "Normal"
            WorkingDirectory = $scriptDir
        }

        $psProcess = Start-Process @psArgs -PassThru

        if ($psProcess.ExitCode -ne 0) {
            Write-Host "link_files.ps1 failed with code: $($psProcess.ExitCode)" -ForegroundColor Yellow
        } else {
            Write-Host "link_files.ps1 executed successfully" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "ERROR during execution:" -ForegroundColor Red
        Write-Host "Message: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Details: $($_.ScriptStackTrace)" -ForegroundColor DarkRed
        Pause
        return
    }

    Pause
}

# Function to pause the script and wait for a key press
function Pause {
    Write-Host "Press any key to continue..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Main menu loop
do {
    Show-Menu
    $choice = Read-Host "Please make a choice"
    switch ($choice) {
        '1' { Install-Prerequisites }
        '2' { Create-Remote }
        '3' { Start-DriveAndLinks }
        '4' { Write-Host "Goodbye!"; exit }
        default { Write-Host "Invalid option" -ForegroundColor Red; Pause }
    }
} while ($true)
