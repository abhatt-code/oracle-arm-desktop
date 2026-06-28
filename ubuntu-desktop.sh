#!/bin/bash

# Disclaimer
echo "************************************************************"
echo "* DISCLAIMER:                                              *"
echo "* This script is provided AS-IS without any warranties or  *"
echo "* guarantees. Use at your own risk. The author will not be *"
echo "* held liable for any issues, damages, or losses caused by *"
echo "* running this script.                                     *"
echo "************************************************************"

# Prompt user to agree to the disclaimer
read -p "Do you agree to proceed? (y/n): " AGREEMENT

# Check user input
if [[ "$AGREEMENT" != "y" ]]; then
    echo "You have declined the agreement. Exiting script."
    echo "Installation aborted. You can rerun the script anytime to proceed."
    
    # Prompt to delete the script file
    read -p "Do you want to delete the downloaded script file (ubuntu-desktop.sh)? (y/n): " DELETE_FILE
    if [[ "$DELETE_FILE" == "y" ]]; then
        SCRIPT_PATH="$(realpath "$0")"
        rm -- "$SCRIPT_PATH"
        echo "Script file deleted."
    else
        echo "Script file retained."
    fi
    
    exit 1
fi

echo "Proceeding with the setup..."

echo "Updating and upgrading system..."
sudo apt update && sudo apt upgrade -y

echo "Installing XFCE Desktop..."
sudo apt install xfce4 xfce4-goodies -y

echo "Installing XRDP for Remote Desktop Access..."
sudo apt install xrdp -y
sudo systemctl enable xrdp
sudo systemctl start xrdp

echo "Configuring XRDP to use XFCE..."
echo "startxfce4" | sudo tee /etc/skel/.xsession
sudo systemctl restart xrdp

echo "Allowing RDP port through firewall..."
sudo ufw allow 3389/tcp
sudo ufw enable -y

echo "Creating a new user for RDP login..."
read -p "Enter a new username for RDP: " new_user
sudo useradd -m -s /bin/bash $new_user

# Ensure password confirmation matches before proceeding
while true; do
    read -s -p "Enter a password for $new_user: " password
    echo
    read -s -p "Retype the password: " password_confirm
    echo
    if [[ "$password" == "$password_confirm" ]]; then
        echo "$new_user:$password" | sudo chpasswd
        break
    else
        echo "Passwords do not match. Please try again."
    fi
done

echo "Granting the new user sudo privileges..."
sudo usermod -aG sudo $new_user

echo "Installing Chromium Browser (Native ARM64 alternative)..."
sudo apt update && sudo apt install chromium-browser -y

echo "Modifying Chromium launcher to use --no-sandbox..."
sudo sed -i 's|Exec=chromium-browser %U|Exec=chromium-browser --no-sandbox %U|' /usr/share/applications/chromium-browser.desktop

echo "Installing GDebi for easy .deb installations..."
sudo apt install gdebi -y

echo "Setting GDebi as default for .deb files..."
xdg-mime default gdebi.desktop application/vnd.debian.binary-package

echo "Restarting XRDP service..."
sudo systemctl restart xrdp

echo "Installation complete! You can now connect via RDP."
echo "Use the following credentials:"
echo "Username: $new_user"
echo "Password: (You set this during installation)"
echo "RDP Address: Use your VPS IP address."

# Prompt to delete the script file
read -p "Do you want to delete the downloaded script file (ubuntu-desktop.sh)? (y/n): " DELETE_FILE
if [[ "$DELETE_FILE" == "y" ]]; then
    SCRIPT_PATH="$(realpath "$0")"
    rm -- "$SCRIPT_PATH"
    echo "Script file deleted."
else
    echo "Script file retained."
fi
