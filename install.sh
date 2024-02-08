#!/bin/bash

# Check if jq is installed, if not, install it
if ! command -v jq &> /dev/null; then
    echo "jq not found, installing..."
    sudo apt-get install -y jq # You can replace this with the appropriate package manager for your Linux distribution
fi

# Get the current user's username
user=$(logname)

# Get the latest release information from GitHub API
latest_Infoscreen=$(curl -sL https://api.github.com/repos/SteveMutter/Infoscreen/releases/latest | jq -r ".tarball_url")
version_number=$(basename $latest_Infoscreen)
version_number="${version_number#v}" # Remove leading 'v'

# Check if the latest release URL is not empty
if [ -n "$latest_Infoscreen" ]; then
    # Download the latest release source code into the user's Downloads directory
    echo "Downloading Version $version_number of Infoscreen source code into /home/$user/Downloads..."
    wget "$latest_Infoscreen" -O /home/$user/Downloads/Infoscreen_source_code.tar.gz
    echo "Download of Version $version_number complete."

    # Unzip the downloaded zip file into a directory
    echo "Unzipping the downloaded archive..."
    mkdir -p /home/$user/temp # Create the directory if it doesn't exist
    tar -xzvf /home/$user/Downloads/Infoscreen_source_code.tar.gz -C /home/$user/temp
    echo "Unzip complete."

    # Delete the zip archive
    echo "Deleting the zip archive..."
    rm /home/$user/Downloads/Infoscreen_source_code.tar.gz
    echo "Deletion complete."
    
    # Move all files directly into temp
    echo "Moving all files directly into temp..."
    mv /home/$user/temp/SteveMutter-Infoscreen-*/* /home/$user/temp/
    rm -r /home/$user/temp/SteveMutter-Infoscreen-*/ # Remove the now empty subdirectory
    echo "Move complete."
    
    # Change ownership of temp to the current user
    echo "Changing ownership of temp..."
    chown -R $user:$user /home/$user/temp
    echo "Ownership changed."
    
    # Execute download.sh.x script
    echo "Executing infoscreen.sh.x script..."
    chmod +x /home/$user/temp/download.sh.x
    su -c "/home/$user/temp/download.sh.x" $user
    echo "Execution complete."
    
else
    echo "Failed to retrieve the latest version of Infoscreen. Please try again later."
fi
