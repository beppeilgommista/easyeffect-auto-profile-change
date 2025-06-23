# easyeffect-auto-profile-change
This script aim to allow the automatic profile change when you use easyeffect with pipewire virtual devices

What you need:
1. Script in: ~/easyeffects-auto-preset.sh - Monitors audio device changes and switches EasyEffects presets automatically
2. Systemd Service: ~/.config/systemd/user/easyeffects-auto-preset.service - Runs the script automatically in the background
3. Log File in: ~/.local/share/easyeffects-auto-preset.log - Tracks all preset changes

Current Configuration:
+  UMC_Speakers → Speaker preset
+  UMC_Headphones → Hifiman-HE400SE preset

🎛️ How to Use:

- place the script in your home folder
- give execute permission to your script


The service is already running automatically! It will:
•  Start automatically when you log in
•  Monitor when you switch between your virtual devices
•  Automatically load the appropriate EasyEffects preset

Manual Controls:

# Test the configuration
```
./easyeffects-auto-preset.sh test
```
# View current device/preset mapping
```
./easyeffects-auto-preset.sh config
```

# Check service status
```
systemctl --user status easyeffects-auto-preset.service
```
# Stop/start the service
```
systemctl --user stop easyeffects-auto-preset.service
systemctl --user start easyeffects-auto-preset.service
```
# Enable/disable logging
1. Open the script: ``` nano ~/easyeffects-auto-preset.sh ```
2. Change line 11 from ENABLE_LOGGING=true to ENABLE_LOGGING=false (or the opposite)
3. Restart the service: ``` systemctl --user restart easyeffects-auto-preset.service ```

# To customize presets
Edit the DEVICE_PRESETS array in the script and restart the service.

# Available commands
```
./easyeffects-auto-preset.sh status
./easyeffects-auto-preset.sh help
```
