import os
import subprocess
import ctypes

# For hiding subprocess windows
CREATE_NO_WINDOW = 0x08000000

# Folder where drives will be mounted
MOUNT_FOLDER = os.path.join("C:\\Users", os.getenv('USERNAME'), "Documents\\Drive")

# PowerShell script to clean up old mount folders (except Scripts)
ps_script = """
$drivePath = Join-Path -Path ([Environment]::GetFolderPath("MyDocuments")) -ChildPath "drive"
if (Test-Path -Path $drivePath -PathType Container) {
    $foldersToDelete = Get-ChildItem -Path $drivePath -Directory | Where-Object { $_.Name -ne "Scripts" }
    foreach ($folder in $foldersToDelete) {
        try {
            Remove-Item -Path $folder.FullName -Recurse -Force
            Write-Host "Dossier supprimé: $($folder.FullName)"
        }
        catch {
            Write-Host "Erreur lors de la suppression de $($folder.FullName): $_"
        }
    }
}
"""

# Execute the PowerShell cleanup script
subprocess.run(["powershell", "-Command", ps_script], creationflags=CREATE_NO_WINDOW)

# Get the list of Rclone remotes
remotes = subprocess.run(['rclone', 'listremotes'], capture_output=True, text=True).stdout.splitlines()

# Mount each remote silently
for remote in remotes:
    remote = remote.strip().rstrip(':')
    mount_path = os.path.join(MOUNT_FOLDER, remote)

    subprocess.Popen([
        'rclone',
        'mount',
        f'{remote}:',
        mount_path,
        '--vfs-cache-mode', 'full',
        '--vfs-cache-max-size', '5G',
        '--vfs-cache-max-age', '6h',
        '--dir-cache-time', '120h',
        '--vfs-read-chunk-size', '64M',
        '--vfs-read-chunk-size-limit', '512M',
        '--no-modtime',
        '--links',
        '--volname', remote,
        '--umask', '000',
        '--log-level=INFO',
        '--no-console'
    ], creationflags=CREATE_NO_WINDOW)