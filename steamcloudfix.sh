#!/bin/bash

# Steam Cloud Sync Fixer
# This script attempts to fix the "Steam cloud out of date" error by renaming the
# remotecache.vdf file for each game, forcing Steam to re-evaluate the cloud sync status.

# --- Functions ---

# Function to display a colored message
# $1: color (green, red, yellow, blue)
# $2: message
function color_echo() {
    case "$1" in
        green) echo -e "\e[32m$2\e[0m" ;;
        red) echo -e "\e[31m$2\e[0m" ;;
        yellow) echo -e "\e[33m$2\e[0m" ;;
        blue) echo -e "\e[34m$2\e[0m" ;;
        *) echo "$2" ;;
    esac
}

# Function to find the Steam installation directory
function find_steam_dir() {
    local steam_paths=(
        "$HOME/.steam/steam"
        "$HOME/.local/share/Steam"
        "$HOME/.var/app/com.valvesoftware.Steam/.steam/steam"
    )

    for path in "${steam_paths[@]}"; do
        if [ -d "$path" ]; then
            echo "$path"
            return
        fi
    done
}

# --- Main Script ---

color_echo "blue" "--- Steam Cloud Sync Fixer ---"

# Find the Steam directory
STEAM_DIR=$(find_steam_dir)

if [ -z "$STEAM_DIR" ]; then
    color_echo "red" "Error: Could not find the Steam installation directory."
    exit 1
fi

color_echo "green" "Found Steam directory at: $STEAM_DIR"

# Navigate to the userdata directory
USERDATA_DIR="$STEAM_DIR/userdata"
if [ ! -d "$USERDATA_DIR" ]; then
    color_echo "red" "Error: Could not find the userdata directory."
    exit 1
fi

# Find user IDs
USER_IDS=($(ls "$USERDATA_DIR"))

if [ ${#USER_IDS[@]} -eq 0 ]; then
    color_echo "red" "Error: No user data found in the userdata directory."
    exit 1
fi

# Select a user ID if multiple exist
if [ ${#USER_IDS[@]} -gt 1 ]; then
    color_echo "yellow" "Multiple user IDs found. Please select one:"
    select user_id in "${USER_IDS[@]}"; do
        if [[ -n "$user_id" ]]; then
            USER_ID="$user_id"
            break
        else
            color_echo "red" "Invalid selection. Please try again."
        fi
    done
else
    USER_ID="${USER_IDS[0]}"
fi

color_echo "green" "Using user ID: $USER_ID"
USER_DIR="$USERDATA_DIR/$USER_ID"

# Confirm before proceeding
color_echo "yellow" "\nThis script will rename 'remotecache.vdf' to 'remotecache.vdf.bak' for all games."
color_echo "yellow" "This is generally safe and can resolve cloud sync issues."
read -p "Do you want to continue? (y/n): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    color_echo "red" "Operation cancelled."
    exit 0
fi

# Find and rename remotecache.vdf for each game
FIXED_COUNT=0
for game_dir in "$USER_DIR"/*; do
    if [ -d "$game_dir" ]; then
        remotecache_file="$game_dir/remotecache.vdf"
        if [ -f "$remotecache_file" ]; then
            mv "$remotecache_file" "${remotecache_file}.bak"
            APP_ID=$(basename "$game_dir")
            color_echo "green" "Fixed AppID: $APP_ID"
            ((FIXED_COUNT++))
        fi
    fi
done

if [ $FIXED_COUNT -gt 0 ]; then
    color_echo "blue" "\nSuccessfully fixed $FIXED_COUNT games."
    color_echo "blue" "Please restart Steam for the changes to take effect."
else
    color_echo "yellow" "\nNo games with cloud sync issues were found."
fi

exit 0
