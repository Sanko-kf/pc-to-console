# Check for admin rights
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script requires administrator privileges." -ForegroundColor Yellow
    Write-Host "Relaunching with elevated privileges..." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Display menu
function Show-Menu {
    Clear-Host
    Write-Host "================ Script Selector ================"
    Write-Host "1. Install and run Windows User Setup"
    Write-Host "2. Install and run System Optimization"
    Write-Host "3. Install and run Windows Settings"
    Write-Host "4. Install and run Remote Drive Setup"
    Write-Host "Q. Quit"
    Write-Host "================================================="
}

# Download and execute script in new window
function Invoke-ScriptInNewWindow {
    param (
        [string]$url,
        [string]$scriptName
    )
    
    $tempPath = [System.IO.Path]::GetTempPath()
    $scriptPath = Join-Path -Path $tempPath -ChildPath $scriptName
    
    try {
        Write-Host "Downloading $scriptName..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $url -OutFile $scriptPath -UseBasicParsing
        
        Write-Host "Opening $scriptName in new window..." -ForegroundColor Green
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
    }
    catch {
        Write-Host "Error occurred: $_" -ForegroundColor Red
    }
}

# Main loop
do {
    Show-Menu
    $selection = Read-Host "Please make a selection"
    
    switch ($selection) {
        '1' {
            Invoke-ScriptInNewWindow -url "https://raw.githubusercontent.com/Sanko-kf/pc-to-console/main/scripts/win_user_setup.ps1" -scriptName "win_user_setup.ps1"
        }
        '2' {
            Invoke-ScriptInNewWindow -url "https://raw.githubusercontent.com/Sanko-kf/pc-to-console/main/scripts/optimization.ps1" -scriptName "optimization.ps1"
        }
        '3' {
            Invoke-ScriptInNewWindow -url "https://raw.githubusercontent.com/Sanko-kf/pc-to-console/main/scripts/win_settings.ps1" -scriptName "win_settings.ps1"
        }
        '4' {
            Invoke-ScriptInNewWindow -url "https://raw.githubusercontent.com/Sanko-kf/pc-to-console/main/scripts/drive_setup/remote_setup.ps1" -scriptName "remote_setup.ps1"
        }
        'q' {
            Write-Host "Exiting..." -ForegroundColor Yellow
            exit
        }
        default {
            Write-Host "Invalid selection. Please try again." -ForegroundColor Red
            pause
        }
    }
}
until ($selection -eq 'q')