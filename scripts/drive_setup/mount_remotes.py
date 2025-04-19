import os
import subprocess
import ctypes

# For hiding subprocess windows
CREATE_NO_WINDOW = 0x08000000

# Folder where drives will be mounted – uses the current system username
MOUNT_FOLDER = os.path.join("C:\\Users", os.getenv('USERNAME'), "Documents\\Drive")

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
