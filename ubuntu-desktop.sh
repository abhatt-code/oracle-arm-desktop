#!/bin/bash

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
sudo apt update && sudo apt upgrade -y

echo "Installing XFCE Desktop..."
sudo apt install xfce4 xfce4-goodies -y

echo "Installing XRDP for Remote Desktop Access..."
sudo apt install xrdp -y
sudo systemctl enable xrdp
sudo systemctl start xrdp

echo "Configuring XRDP to use XFCE smoothly..."
echo "xfce4-session" | sudo tee /etc/skel/.xsession
echo "STARTUP=xfce4-session" | sudo tee /etc/skel/.xsessionrc
sudo systemctl restart xrdp

echo "Force installing and configuring UFW firewall..."
sudo apt install ufw -y
sudo ufw allow 22/tcp
sudo ufw allow 3389/tcp
sudo ufw --force enable

echo "Removing Oracle default overriding REJECT rule..."
sudo iptables -D INPUT -j REJECT --reject-with icmp-host-prohibited 2>/dev/null || true

echo "Saving firewall layout permanently..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent netfilter-persistent
sudo netfilter-persistent save

echo "Creating a new user for RDP login..."
read -p "Enter a new username for RDP: " new_user
sudo useradd -m -s /bin/bash "$new_user"

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

echo "Installing Google Chrome..."
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O /tmp/chrome.deb
sudo apt install /tmp/chrome.deb -y
rm /tmp/chrome.deb

echo "Installing Git, Htop, and GDebi..."
sudo apt install git htop gdebi -y

echo "Setting GDebi as default for .deb files..."
xdg-mime default gdebi.desktop application/vnd.debian.binary-package

echo "Installing Hermes Agent with Desktop features..."
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash -s -- --include-desktop

echo "Restarting XRDP service..."
sudo systemctl restart xrdp

echo "Installation complete! You can now connect via RDP."
echo "Use the following credentials:"
echo "Username: $new_user"
echo "Password: (You set this during installation)"
echo "RDP Address: Use your VPS IP address."
echo "--------------------------------------------------------"
echo "Note: To complete the Hermes Agent setup, log in as your"
echo "new user and run 'hermes setup' in the terminal."
echo "--------------------------------------------------------"

# Prompt to delete the script file
read -p "Do you want to delete the downloaded script file (ubuntu-desktop.sh)? (y/n): " DELETE_FILE
if [[ "$DELETE_FILE" == "y" ]]; then
    SCRIPT_PATH="$(realpath "$0")"
    rm -- "$SCRIPT_PATH"
    echo "Script file deleted."
else
    echo "Script file retained."
fi
