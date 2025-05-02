# Check for administrator rights
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script requires administrator privileges." -ForegroundColor Yellow
    Write-Host "Restarting with elevated privileges..." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Apply dark theme
Write-Host "Applying dark theme..." -ForegroundColor Green
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0 -Type DWord
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0 -Type DWord

# Apply custom wallpaper
$wallpaperPath = "C:\Users\aaa\Desktop\vector-background-damask-seamless-pattern-ornement-classique-damas-ancienne-texture-victorienne-sans-soudure-pour-papiers-peints-textile-emballage-modele-baroque-floral-exquis_1217-738.png"
if (Test-Path $wallpaperPath) {
    Write-Host "Applying your custom wallpaper..." -ForegroundColor Green
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "Wallpaper" -Value $wallpaperPath
    rundll32.exe user32.dll, UpdatePerUserSystemParameters
} else {
    Write-Host "Specified wallpaper file does not exist: $wallpaperPath" -ForegroundColor Red
}

# Hide desktop icons
Write-Host "Hiding desktop icons..." -ForegroundColor Green
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideIcons" -Value 1 -Type DWord
Stop-Process -Name "explorer" -Force

# Remove "Search" and "Show Desktop" from taskbar
Write-Host "Removing taskbar elements..." -ForegroundColor Green
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 0 -Type DWord
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value 0 -Type DWord

# Uninstall OneDrive, Outlook and Xbox
Write-Host "Uninstalling unwanted applications..." -ForegroundColor Green

# Uninstall OneDrive
$onedrivePath = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
if (Test-Path $onedrivePath) {
    Start-Process $onedrivePath -ArgumentList "/uninstall" -Wait
}
$onedrivePath = "$env:SystemRoot\System32\OneDriveSetup.exe"
if (Test-Path $onedrivePath) {
    Start-Process $onedrivePath -ArgumentList "/uninstall" -Wait
}

# Remove OneDrive folder
$onedriveFolder = "$env:USERPROFILE\OneDrive"
if (Test-Path $onedriveFolder) {
    Remove-Item -Path $onedriveFolder -Recurse -Force
}

# Uninstall Outlook and "Outlook New"
Get-AppxPackage -Name *Outlook* | Remove-AppxPackage -ErrorAction SilentlyContinue

# Uninstall desktop versions of Outlook
$outlookProducts = Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE (Name LIKE '%Outlook%') OR (Name LIKE '%Microsoft 365%') OR (Name LIKE '%Office%')"
foreach ($product in $outlookProducts) {
    try {
        $product.Uninstall()
    } catch {
        Write-Host "Failed to uninstall $($product.Name)" -ForegroundColor Red
    }
}

# Uninstall Xbox and its components
Get-AppxPackage -Name *Xbox* | Remove-AppxPackage -ErrorAction SilentlyContinue
Get-AppxPackage -Name Microsoft.GamingApp | Remove-AppxPackage -ErrorAction SilentlyContinue
Get-AppxPackage -Name Microsoft.Xbox.TCUI | Remove-AppxPackage -ErrorAction SilentlyContinue
Get-AppxPackage -Name Microsoft.XboxGameOverlay | Remove-AppxPackage -ErrorAction SilentlyContinue
Get-AppxPackage -Name Microsoft.XboxGamingOverlay | Remove-AppxPackage -ErrorAction SilentlyContinue
Get-AppxPackage -Name Microsoft.XboxIdentityProvider | Remove-AppxPackage -ErrorAction SilentlyContinue
Get-AppxPackage -Name Microsoft.XboxSpeechToTextOverlay | Remove-AppxPackage -ErrorAction SilentlyContinue

# Restart Explorer to apply changes
Write-Host "Restarting Windows Explorer..." -ForegroundColor Green
Start-Process "explorer.exe"

Write-Host "Configuration complete!" -ForegroundColor Green