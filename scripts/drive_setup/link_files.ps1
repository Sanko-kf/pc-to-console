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
    Write-Host "1. Auto-prepare emulations (TBD)"
    Write-Host "2. Manually create a symbolic link"
    Write-Host "==========================================="
}

# Placeholder for future automation
function Option1 {
    Write-Host "Option 1 - To be implemented later."
    Pause
    Exit
}

# Create a symbolic link manually
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
