# PC to Console

> ** Important Note: If you're using an AMD system, consider installing [BazziteOS](https://bazzite.gg/)** for **better smoothness and performance**.

---

## Description

The goal of this project is to transform a Windows PC into a gaming console, exclusively controllable with a gamepad, while providing practical and essential improvements to the user experience. By enhancing the experience of Steam Big Picture, it aims to offer a fluid and easy-to-use environment, while adding often-overlooked features such as customizable sleep mode management, automated addition of non-Steam games to Steam, and the automation of certain system tasks to streamline daily usage.

The project relies on a series of scripts and tools designed to simplify the installation, configuration, and operation of a PC in console mode. Rather than focusing on "out-of-the-box" solutions, it offers a range of customizable features, allowing users to create a unique experience that goes beyond the limitations of existing systems.

---

## 🚀 Key Features

### 🎮 Full Gamepad Control
- Automatically launches Steam Big Picture with a **custom intro video**
- Designed to work **without keyboard or mouse** (you need mouse and keyboard if you add a specific game on steam)
- Recommended: use **reWASD** for controller paddle support (see below)

### Cloud Save System for Emulators
- Uses **Rclone** to automatically mount cloud remotes under `Documents/Drive/`
- Ideal for **backing up emulated game saves**
- **Internet connection is required** for this system

### Smart Sleep Mode
- Automatically sleeps the PC after 5 minutes of inactivity
- Wakes up instantly when input is detected
- Powered by `sleep_mode_detector.py` + `sleep_mode.bat` / `stop_sleep.bat`

### System Optimization
- Removes login screen for seamless boot
- Boosts system performance via PowerShell scripts
- **Known Bug:** Optimization may **break Wi-Fi** – **Ethernet is highly recommended**

### Custom Steam Boot
- Shows a custom intro video before launching Steam
- Uses a dedicated `.bat` script for immersive console-like startup

---

## Project Structure

```
.
├── install.ps1                       # Main installation script
├── wallpaper.png                     # Custom console wallpaper
├── scripts/
│   ├── win_user_setup.ps1            # User account setup
│   ├── win_settings.ps1              # Windows optimization
│   ├── optimization.ps1              # Extra tweaks
│   ├── sleep_mode_detector.py/.exe   # Inactivity detection
│   ├── sleep_mode.bat / stop_sleep.bat
│   ├── custom_steam_boot.bat         # Steam boot with intro
│   └── drive_setup/
│       ├── remote_setup.ps1          # Rclone setup
│       ├── mount_remotes.py/.exe     # Cloud remote mounter
│       └── link_files.ps1            # File/shortcut linking
```

---

## Installation

To install the entire setup, simply run:

```powershell
install.ps1
```

> This script includes **all steps in the correct order** to configure the full experience.

---

## 🎮 Adding Games & Emulators

- **Emulators** must be **manually installed**.
  - You can use **[EmuDeck](https://www.emudeck.com/)** or perform a manual setup.
- Non-Steam games can be added to Steam via "Add a Non-Steam Game".

### Custom Game Covers
- Use **[SteamGridDB](https://www.steamgriddb.com/)** to add **custom cover art** for your non-Steam games.

---

## reWASD for Paddle Controllers

If you're using advanced controllers with paddles (Xbox Elite, SCUF, etc.):

🔧 **Install [reWASD](https://www.rewasd.com/)** to:
- Map paddle shortcuts
- Auto-launch apps like **Lossless Scaling**
- Bind actions like Alt+Tab, shutdown, or fullscreen switching

> It improve a lot the experience

---

## Known Issues

- **Wi-Fi may break after system optimization**
  - Workaround: comment out the relevant sections in `win_settings.ps1`
  - **Ethernet connection is strongly recommended**

---

##  License

This project is licensed under the [MIT License](./LICENSE.md)  
**Credit required:** Sanko  
**Do not remove this license notice**
