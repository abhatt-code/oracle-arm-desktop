#!/bin/bash

# Initialize installation status tracking
declare -A STATUS
STATUS=(
    ["System Update"]="Pending"
    ["XFCE Desktop"]="Pending"
    ["XRDP Remote Desktop"]="Pending"
    ["UFW Firewall Setup"]="Pending"
    ["User Creation"]="Pending"
    ["Google Chrome"]="Pending"
    ["Utilities (Git, Htop, GDebi)"]="Pending"
)

# Disclaimer
echo "DISCLAIMER: This script is provided AS-IS without warranties; use at your own risk."

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
if sudo apt update && sudo apt upgrade -y; then
    STATUS["System Update"]="SUCCESS"
else
    STATUS["System Update"]="FAILED"
fi

echo "Installing XFCE Desktop..."
if sudo apt install xfce4 xfce4-goodies -y; then
    STATUS["XFCE Desktop"]="SUCCESS"
else
    STATUS["XFCE Desktop"]="FAILED"
fi

echo "Installing XRDP for Remote Desktop Access..."
if sudo apt install xrdp -y && sudo systemctl enable xrdp && sudo systemctl start xrdp; then
    STATUS["XRDP Remote Desktop"]="SUCCESS"
else
    STATUS["XRDP Remote Desktop"]="FAILED"
fi

echo "Configuring XRDP to use XFCE smoothly..."
echo "xfce4-session" | sudo tee /etc/skel/.xsession
echo "STARTUP=xfce4-session" | sudo tee /etc/skel/.xsessionrc
sudo systemctl restart xrdp

echo "Force installing and configuring UFW firewall..."
if sudo apt install ufw -y && sudo ufw allow 22/tcp && sudo ufw allow 3389/tcp && sudo ufw --force enable; then
    STATUS["UFW Firewall Setup"]="SUCCESS"
else
    STATUS["UFW Firewall Setup"]="FAILED"
fi

echo "Removing Oracle default overriding REJECT rule..."
sudo iptables -D INPUT -j REJECT --reject-with icmp-host-prohibited 2>/dev/null || true

echo "Saving firewall layout permanently..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent netfilter-persistent
sudo netfilter-persistent save

echo "Creating a new user for RDP login..."
read -p "Enter a new username for RDP: " new_user
if sudo useradd -m -s /bin/bash "$new_user"; then
    STATUS["User Creation"]="SUCCESS"
    
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
    sudo usermod -aG sudo "$new_user"
else
    STATUS["User Creation"]="FAILED"
    echo "Failed to create user. Skipping password configuration."
fi

echo "Installing Google Chrome..."
if wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O /tmp/chrome.deb && sudo apt install /tmp/chrome.deb -y; then
    STATUS["Google Chrome"]="SUCCESS"
else
    STATUS["Google Chrome"]="FAILED"
fi
rm -f /tmp/chrome.deb

echo "Installing Git, Htop, and GDebi..."
if sudo apt install git htop gdebi -y; then
    STATUS["Utilities (Git, Htop, GDebi)"]="SUCCESS"
    echo "Setting GDebi as default for .deb files..."
    xdg-mime default gdebi.desktop application/vnd.debian.binary-package
else
    STATUS["Utilities (Git, Htop, GDebi)"]="FAILED"
fi

echo "Restarting XRDP service..."
sudo systemctl restart xrdp

echo "========================================================"
echo "                INSTALLATION SUMMARY                    "
echo "========================================================"
for step in "System Update" "XFCE Desktop" "XRDP Remote Desktop" "UFW Firewall Setup" "User Creation" "Google Chrome" "Utilities (Git, Htop, GDebi)"; do
    if [[ "${STATUS[$step]}" == "SUCCESS" ]]; then
        echo -e "[✓] $step: Installed Successfully"
    else
        echo -e "[X] $step: FAILED or MISSED"
    fi
done
echo "========================================================"

if [[ "${STATUS["XRDP Remote Desktop"]}" == "SUCCESS" && "${STATUS["User Creation"]}" == "SUCCESS" ]]; then
    echo "Installation complete! You can now connect via RDP."
    echo "Use the following credentials:"
    echo "Username: $new_user"
    echo "Password: (You set this during installation)"
    echo "RDP Address: Use your VPS IP address."
else
    echo "Installation finished with critical core errors. Please check the summary above."
fi

# Prompt to delete the script file
read -p "Do you want to delete the downloaded script file (ubuntu-desktop.sh)? (y/n): " DELETE_FILE
if [[ "$DELETE_FILE" == "y" ]]; then
    SCRIPT_PATH="$(realpath "$0")"
    rm -- "$SCRIPT_PATH"
    echo "Script file deleted."
else
    echo "Script file retained."
fi
