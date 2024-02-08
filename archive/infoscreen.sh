#!/bin/bash

# Determine script directory
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Log file path
LOGFILE="$SCRIPT_DIR/install_Infoscreen_log.txt"

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOGFILE"
}

# Start logging
log "Script started."

# Check if background.png exists
BACKGROUND_IMAGE="$SCRIPT_DIR/bg.png"

if [ -e "$BACKGROUND_IMAGE" ]; then
    # Set desktop background using feh if it exists
    if command -v feh &> /dev/null; then
        feh --bg-fill "$BACKGROUND_IMAGE"
        log "Desktop background set to $BACKGROUND_IMAGE"
    else
        echo "feh not found. Installing feh..."
        if [ -x "$(command -v apt)" ]; then
            sudo apt update -y
            sudo apt install feh -y
        else
            echo "Unsupported package manager. Please install feh manually."
            exit 1
        fi

        log "feh installed."
        feh --bg-fill "$BACKGROUND_IMAGE"
        log "Desktop background set to $BACKGROUND_IMAGE."
    fi
else
    echo "Background Image not found..."
    sleep 3
    echo "Continuing..."
fi

# Backup existing Samba configuration
sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.bak
log "Existing Samba configuration backed up to smb.conf.bak."

# Update package information
sudo apt update -y
log "Package information updated."

# Upgrade installed packages
sudo apt upgrade -y
log "Packages upgraded."

# Install Samba
sudo apt install samba -y
log "Samba installed."

# Prompt the user for Samba server name (default: Infoscreen Share)
read -p "Enter Samba server name (default: Infoscreen Share): " SAMBANAME
SAMBANAME=${SAMBANAME:-"Infoscreen Share"}

# Set the Samba share directory within the user's home folder
SAMBASHAREDIR="$HOME/Infoscreen_Share"

# Get the current username (same as the user who executed the script)
USERNAME=$(logname)

# Enable Samba server
sudo systemctl enable smbd
sudo systemctl restart smbd
log "Samba server enabled and restarted."

# Set the Samba share directory within the user's home folder
SAMBASHAREDIR="$(getent passwd $USERNAME | cut -d: -f6)/$SAMBANAME"

# Configure Samba with default values
echo "[$SAMBANAME]
    Comment = $SAMBANAME
    Path = $SAMBASHAREDIR
    Browseable = yes
    Writeable = Yes
    only guest = no
    create mask = 0777
    directory mask = 0777
    Public = yes
    Guest ok = no
    force user = $USERNAME" | sudo tee /etc/samba/smb.conf > /dev/null
log "Samba configured."

# Create the Samba share directory within the user's home folder
mkdir -p "$SAMBASHAREDIR"
sudo chown -R $USERNAME:$USERNAME "$SAMBASHAREDIR"

# Restart Samba to apply the configuration
sudo systemctl restart smbd
log "Samba restarted to apply configuration."

# Prompt user to set up Samba password
echo "Setting up Samba password for user $USERNAME..."
sudo smbpasswd -a $USERNAME
log "Samba password set for user $USERNAME."

echo "Samba setup complete. Server name: $USERNAME Share"
echo "Samba share directory: $SAMBASHAREDIR"

# Copy Tageseinteilung.htm to Samba share directory if exists
HTML_FILE="$SCRIPT_DIR/Tageseinteilung.htm"
if [ -e "$HTML_FILE" ]; then
    cp "$HTML_FILE" "$SAMBASHAREDIR"
    log "Tageseinteilung.htm copied to Samba share directory."
    echo "Tageseinteilung.htm copied to Samba share directory."
else
    log "Tageseinteilung.htm not found in script's folder."
    echo "Tageseinteilung.htm not found in script's folder."
fi

# Ensure Directory is owned by user
sudo chown -R $USERNAME:$USERNAME "$SAMBASHAREDIR"

# Create "content" directory within the user's home folder
CONTENT_DIR="$(getent passwd $USERNAME | cut -d: -f6)/content"
mkdir -p "$CONTENT_DIR"

# Copy Infoscreen2024.html to "content" directory if exists
HTML_FILE="$SCRIPT_DIR/InfoScreen2024.html"
if [ -e "$HTML_FILE" ]; then
    # Backup original file
    cp "$HTML_FILE" "$CONTENT_DIR/InfoScreen2024.html.bak"

    # Copy the original file to "content" directory
    cp "$HTML_FILE" "$CONTENT_DIR"

    # Modify iframe content in the copied file
    sed -i "s|var shared_folder = \"Samba_Share_Folder\";|var shared_folder = \"$SAMBASHAREDIR\";|" "$CONTENT_DIR/InfoScreen2024.html"
    sed -i "s|file://$SAMBASHAREDIR/Tageseinteilung.htm|" "$CONTENT_DIR/InfoScreen2024.html"

    log "Infoscreen2024.html copied to content directory with updated iframe."
    echo "Infoscreen2024.html copied to content directory with updated iframe."
else
    log "Infoscreen2024.html not found in script's folder."
    echo "Infoscreen2024.html not found in script's folder."
fi

# Ensure Directory is owned by user
sudo chown -R $USERNAME:$USERNAME "$CONTENT_DIR"

# End logging
log "Script completed."
