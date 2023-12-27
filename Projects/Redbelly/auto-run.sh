#!/bin/bash
exists()
{
  command -v "$1" >/dev/null 2>&1
}
if exists curl; then
echo ''
else
  sudo apt update && sudo apt install curl -y < "/dev/null"
fi

# Logo
sleep 1 && curl -s https://raw.githubusercontent.com/vnbnode/binaries/main/Logo/logo.sh | bash && sleep 1

# Set DNS Configuration
echo 'Example Fully Qualified Domain Name: redbelly.vnbnode.com'
read -r -p "Enter Your Domain Name without https:// :" fqn
sleep 0.5
read -r -p "Enter Your Email : " email
sleep 0.5
read -r -p "Enter Node ID - As Node Registration : " ID
sleep 0.5
read -r -p "Enter signing address : " Signing
sleep 0.5
read -r -p "Enter Signing privatekey : " Privkey
sleep 1

# Update system and install build tools
sudo apt update
sudo apt install snapd
sudo snap install core; sudo snap refresh core
sudo apt install net-tools
# Install cert bot
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
netstat -an | grep 80
sleep 1
# Install cert bot
sudo certbot certonly --standalone -d $fqn. --non-interactive --agree-tos -m $email
sudo chown -R $USER:$USER /etc/letsencrypt/
sudo certbot certificates
sleep 1
# Update system and install build tools
sudo apt-get update
sudo apt-get install -y cron curl unzip
sudo DEBIAN_FRONTEND=noninteractive apt-get -y upgrade

# Download binaries and genesis
cd $HOME
wget https://github.com/vnbnode/binaries/blob/main/Projects/Redbelly/genesis.json
