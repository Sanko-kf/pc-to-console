# Administrator rights verification
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script requires administrator privileges." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Function to create a new local admin user
function Create-LocalAdmin {
    param (
        [string]$Username,
        [string]$Password
    )
    
    # Check if user already exists
    if (Get-LocalUser -Name $Username -ErrorAction SilentlyContinue) {
        Write-Host "User $Username already exists." -ForegroundColor Yellow
        return $false
    }
    
    try {
        # Create user
        $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
        New-LocalUser -Name $Username -Password $SecurePassword -AccountNeverExpires -PasswordNeverExpires
        
        # Try to add to Administrators group (English) or Administrateurs (French)
        $adminGroup = Get-LocalGroup | Where-Object { $_.Name -eq "Administrators" -or $_.Name -eq "Administrateurs" }
        if ($adminGroup) {
            Add-LocalGroupMember -Group $adminGroup.Name -Member $Username
            Write-Host "User $Username created successfully and added to $($adminGroup.Name) group." -ForegroundColor Green
            return $true
        } else {
            Write-Host "Could not find Administrators/Administrateurs group." -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "Error creating user: $_" -ForegroundColor Red
        return $false
    }
}

# Download and configure AutoLogon
function Configure-AutoLogon {
    param (
        [string]$Username,
        [string]$Password
    )
    
    $tempDir = "$env:TEMP\AutoLogon"
    $zipPath = "$tempDir\AutoLogon.zip"
    $exePath = "$tempDir\Autologon.exe"
    
    try {
        # Create temp directory
        if (!(Test-Path $tempDir)) {
            New-Item -ItemType Directory -Path $tempDir | Out-Null
        }
        
        # Download AutoLogon
        Write-Host "Downloading AutoLogon..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri "https://download.sysinternals.com/files/AutoLogon.zip" -OutFile $zipPath
        
        # Unzip
        Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force
        
        # Configure AutoLogon (for local account, domain should be empty "")
        Write-Host "Configuring auto login..." -ForegroundColor Cyan
        Start-Process -FilePath $exePath -ArgumentList "$Username `"`" $Password" -Wait -NoNewWindow
        
        Write-Host "AutoLogon configuration completed." -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Error configuring AutoLogon: $_" -ForegroundColor Red
        return $false
    }
}

# User interface
Write-Host "`nCreating a new local administrator user and configuring auto login`n" -ForegroundColor Magenta

# Get user information
$username = Read-Host "Enter new username"
$password = Read-Host "Enter password" -AsSecureString
$password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

# Create user
if (Create-LocalAdmin -Username $username -Password $password) {
    # Configure AutoLogon
    if (Configure-AutoLogon -Username $username -Password $password) {
        # Prompt for restart
        Write-Host "`nConfiguration complete. The computer needs to restart to apply changes." -ForegroundColor Yellow
        $choice = Read-Host "Do you want to restart now? (Y/N)"
        
        if ($choice -eq "Y" -or $choice -eq "y") {
            Restart-Computer -Force
        }
    }
}