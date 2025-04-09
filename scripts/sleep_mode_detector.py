import time
import win32api
import subprocess
import os

# Paths to the .bat files to execute
BAT_FILE_INACTIVE = ADD_PATH
BAT_FILE_ACTIVE = ADD_PATH

# Inactivity threshold before executing the .bat file (in seconds)
INACTIVITY_THRESHOLD = 300  # 5 minutes (300 seconds)

def get_idle_time():
    """Returns the user's idle time in seconds."""
    return (win32api.GetTickCount() - win32api.GetLastInputInfo()) / 1000

def execute_bat(file_path):
    """Executes a .bat file."""
    if os.path.exists(file_path):
        try:
            subprocess.Popen(file_path, shell=True)
        except Exception as e:
            print(f"Error executing {file_path}: {e}")
    else:
        print(f"File not found: {file_path}")

def main():
    is_inactive = False

    while True:
        idle_time = get_idle_time()

        if idle_time >= INACTIVITY_THRESHOLD and not is_inactive:
            print("User inactive for more than threshold. Executing veille.bat.")
            execute_bat(BAT_FILE_INACTIVE)
            is_inactive = True
        elif idle_time < INACTIVITY_THRESHOLD and is_inactive:
            print("User became active again. Executing stop_veille.bat.")
            execute_bat(BAT_FILE_ACTIVE)
            is_inactive = False

        time.sleep(1)

if __name__ == "__main__":
    main()