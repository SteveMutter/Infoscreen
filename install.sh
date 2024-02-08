#!/bin/bash


if ! command -v jq &> /dev/null; then
    echo "jq not found, installing..."
    sudo apt-get install -y jq 
fi


user=$(logname)


latest_Infoscreen=$(curl -sL https://api.github.com/repos/SteveMutter/Infoscreen/releases/latest | jq -r ".tarball_url")
version_number=$(basename $latest_Infoscreen)
version_number="${version_number#v}" 


if [ -n "$latest_Infoscreen" ]; then
    
    echo "Downloading Version $version_number of Infoscreen source code into /home/$user/Downloads..."
    wget "$latest_Infoscreen" -O /home/$user/Downloads/Infoscreen_source_code.tar.gz
    echo "Download of Version $version_number complete."

   
    echo "Unzipping the downloaded archive..."
    mkdir -p /home/$user/temp 
    tar -xzvf /home/$user/Downloads/Infoscreen_source_code.tar.gz -C /home/$user/temp
    echo "Unzip complete."

  
    echo "Deleting the zip archive..."
    rm /home/$user/Downloads/Infoscreen_source_code.tar.gz
    echo "Deletion complete."
    
  
    echo "Moving all files directly into temp..."
    mv /home/$user/temp/SteveMutter-Infoscreen-*/* /home/$user/temp/
    rm -r /home/$user/temp/SteveMutter-Infoscreen-*/ 
    echo "Move complete."
    
   
    echo "Changing ownership of temp..."
    chown -R $user:$user /home/$user/temp
    echo "Ownership changed."
    
 
    echo "Executing infoscreen.sh.x script..."
    chmod +x /home/$user/temp/download.sh.x
    su -c "/home/$user/temp/download.sh.x" $user
    echo "Execution complete."
    
else
    echo "Failed to retrieve the latest version of Infoscreen. Please try again later."
fi
