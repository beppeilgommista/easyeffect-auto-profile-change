#!/bin/bash

# EasyEffects Auto Preset Switcher
# Monitors PipeWire sink changes and automatically switches EasyEffects presets

# =============================================================================
# CONFIGURATION
# =============================================================================

# Enable/Disable logging - Set to 'true' to enable, 'false' to disable
ENABLE_LOGGING=false

# Device/Preset mapping - Adjust these preset names to match your preferences
declare -A DEVICE_PRESETS=(
    ["UMC_Speakers"]="Speaker"
    ["UMC_Headphones"]="Hifiman-HE400SE"
)

# Log file location (only used when ENABLE_LOGGING=true)
LOGFILE="$HOME/.local/share/easyeffects-auto-preset.log"

# =============================================================================
# FUNCTIONS
# =============================================================================

# Function to log messages (respects ENABLE_LOGGING setting)
log() {
    if [[ "$ENABLE_LOGGING" == "true" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"
    fi
}

# Function to switch EasyEffects preset
switch_preset() {
    local device="$1"
    local preset="${DEVICE_PRESETS[$device]}"
    
    if [[ -n "$preset" ]]; then
        log "Switching to preset '$preset' for device '$device'"
        flatpak run com.github.wwmm.easyeffects -l "$preset" &>/dev/null
        if [[ $? -eq 0 ]]; then
            log "Successfully switched to preset '$preset'"
        else
            log "Failed to switch to preset '$preset'"
        fi
    else
        log "No preset configured for device '$device'"
    fi
}

# Function to get current default sink
get_current_sink() {
    pactl get-default-sink 2>/dev/null
}

# Function to monitor sink changes using pactl subscribe
monitor_sink_changes() {
    log "Starting EasyEffects Auto Preset Switcher..."
    log "Monitoring devices: ${!DEVICE_PRESETS[*]}"
    
    # Get initial sink and set preset
    current_sink=$(get_current_sink)
    if [[ -n "$current_sink" ]]; then
        log "Initial sink: $current_sink"
        switch_preset "$current_sink"
    fi
    
    # Monitor for changes
    pactl subscribe | while read -r event; do
        if [[ "$event" == *"sink"* && "$event" == *"change"* ]]; then
            sleep 0.5  # Small delay to ensure the change is complete
            new_sink=$(get_current_sink)
            
            if [[ "$new_sink" != "$current_sink" ]]; then
                log "Sink changed from '$current_sink' to '$new_sink'"
                current_sink="$new_sink"
                switch_preset "$current_sink"
            fi
        fi
    done
}

# Function to show usage
show_usage() {
    echo "EasyEffects Auto Preset Switcher"
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  start     Start monitoring (default)"
    echo "  test      Test current configuration"
    echo "  config    Show current device/preset mapping"
    echo "  status    Show logging and configuration status"
    echo "  help      Show this help message"
    echo ""
    echo "Configuration:"
    echo "  To customize presets: edit the DEVICE_PRESETS array in this script"
    echo "  To enable/disable logging: set ENABLE_LOGGING=true/false in this script"
}

# Function to test current configuration
test_config() {
    echo "Testing current configuration..."
    echo ""
    echo "Available sinks:"
    pactl list sinks short | awk '{print "  " $2}'
    echo ""
    echo "Current default sink:"
    current_sink=$(get_current_sink)
    echo "  $current_sink"
    echo ""
    echo "Available EasyEffects presets:"
    flatpak run com.github.wwmm.easyeffects -p | grep "Profili di Uscita:" | sed 's/Profili di Uscita: //' | tr ',' '\n' | sed 's/^/  /'
    echo ""
    echo "Configured device/preset mapping:"
    for device in "${!DEVICE_PRESETS[@]}"; do
        echo "  $device -> ${DEVICE_PRESETS[$device]}"
    done
    echo ""
    
    # Test if current sink has a preset configured
    if [[ -n "${DEVICE_PRESETS[$current_sink]}" ]]; then
        echo "✓ Current sink '$current_sink' has preset '${DEVICE_PRESETS[$current_sink]}' configured"
    else
        echo "⚠ Current sink '$current_sink' has no preset configured"
    fi
}

# Function to show current status
show_status() {
    echo "EasyEffects Auto Preset Switcher - Status"
    echo "========================================"
    echo ""
    echo "Logging Status: $(if [[ "$ENABLE_LOGGING" == "true" ]]; then echo "✓ ENABLED"; else echo "✗ DISABLED"; fi)"
    if [[ "$ENABLE_LOGGING" == "true" ]]; then
        echo "Log File: $LOGFILE"
        if [[ -f "$LOGFILE" ]]; then
            echo "Log File Size: $(du -h "$LOGFILE" | cut -f1)"
            echo "Last Log Entry: $(tail -1 "$LOGFILE" 2>/dev/null || echo "No entries yet")"
        else
            echo "Log File: Not created yet"
        fi
    fi
    echo ""
    echo "Device/Preset Configuration:"
    for device in "${!DEVICE_PRESETS[@]}"; do
        echo "  $device → ${DEVICE_PRESETS[$device]}"
    done
    echo ""
    echo "Current Default Sink: $(get_current_sink)"
    echo ""
    echo "Service Status:"
    if systemctl --user is-active easyeffects-auto-preset.service >/dev/null 2>&1; then
        echo "  ✓ Service is running"
    else
        echo "  ✗ Service is not running"
    fi
}

# =============================================================================
# MAIN SCRIPT LOGIC
# =============================================================================
case "${1:-start}" in
    "start")
        monitor_sink_changes
        ;;
    "test")
        test_config
        ;;
    "config")
        echo "Device/Preset Configuration:"
        for device in "${!DEVICE_PRESETS[@]}"; do
            echo "  $device -> ${DEVICE_PRESETS[$device]}"
        done
        ;;
    "status")
        show_status
        ;;
    "help")
        show_usage
        ;;
    *)
        echo "Unknown option: $1"
        show_usage
        exit 1
        ;;
esac
