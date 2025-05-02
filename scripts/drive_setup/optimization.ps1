# Check for admin rights
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script requires administrator privileges." -ForegroundColor Yellow
    Write-Host "Relaunching with elevated privileges..." -ForegroundColor Yellow
    Write-Host "Recommendation: Accept privilege elevation to allow all system modifications" -ForegroundColor Magenta
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Download and execute the first debloat script
Write-Host "Downloading and executing the first debloat script..." -ForegroundColor Cyan
Write-Host "Recommendation: Choose 'Remove Bloatware' and 'Disable Telemetry' options for complete debloating" -ForegroundColor Magenta
& ([scriptblock]::Create((irm "https://debloat.raphi.re/")))

# Download the .bat file
$batUrl = "https://drive.usercontent.google.com/download?id=1Q_slb69fXxaYBQvu0d-2OBU8G4evJQS3&export=download&authuser=0&confirm=t&uuid=516b2b92-9b21-41b7-8fc5-33cfd8aea06f&at=APcmpoymHAKukju36O5FFG0cbPQS%3A1745226988298"
$batPath = "$env:TEMP\script.bat"

Write-Host "Downloading the .bat file..." -ForegroundColor Cyan
Write-Host "Recommendation: Verify the file comes from a trusted source before execution" -ForegroundColor Magenta
try {
    Invoke-WebRequest -Uri $batUrl -OutFile $batPath
    Write-Host ".bat file downloaded successfully." -ForegroundColor Green
    
    # Execute the .bat file
    Write-Host "Executing the .bat file..." -ForegroundColor Cyan
    Write-Host "Recommendation: Review the actions performed by the script and confirm they match your needs" -ForegroundColor Magenta
    Start-Process -FilePath $batPath -Wait
    Write-Host ".bat file executed successfully." -ForegroundColor Green
}
catch {
    Write-Host "Error while downloading or executing the .bat file: $_" -ForegroundColor Red
}

Write-Host "All operations completed." -ForegroundColor Green
Write-Host "Final recommendation: Restart your system to apply all changes" -ForegroundColor Magenta