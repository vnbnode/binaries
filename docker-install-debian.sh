#!/bin/bash

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

map_deepin_to_debian() {
    if [ "$1" -lt 20 ]; then
        echo "stretch"
    elif [ "$1" -ge 20 ]; then
        echo "buster"
    else
        echo "Unknown version of Deepin"
        exit 1
    fi
}

# Get Deepin version
DEEPIN_VERSION=$(grep 'VERSION_ID' /etc/os-release | cut -d '"' -f 2)
DEBIAN_VERSION=$(map_deepin_to_debian "$DEEPIN_VERSION")

# Logo
sleep 1 && curl -s https://raw.githubusercontent.com/vnbnode/binaries/main/Logo/logo.sh | bash && sleep 1

# Update
cd $HOME
echo -e "\e[1m\e[32m1. Update... \e[0m" && sleep 1
sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common || { echo "Failed to install dependencies"; exit 1; }
sleep 1

# Package
echo -e "\e[1m\e[32m2. Installing package... \e[0m" && sleep 1
sudo apt install curl tar wget clang pkg-config protobuf-compiler libssl-dev jq build-essential protobuf-compiler bsdmainutils git make ncdu gcc git jq chrony liblz4-tool -y
sudo apt-get install git curl build-essential make jq gcc snapd chrony lz4 tmux unzip bc -y
sleep 1

# Check if Docker is installed and remove it
if dpkg -l | grep -qw docker; then
echo -e "\e[1m\e[32m3. Removing old Docker versions... \e[0m" && sleep 1
sudo apt-get remove -y docker docker-engine docker.io containerd runc || { echo "Failed to remove existing Docker installations"; exit 1; }
fi

# Docker
echo -e "\e[1m\e[32m4. Installing docker... \e[0m" && sleep 1
echo "Adding Docker's GPG key..."
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add - || { echo "Failed to add Docker's GPG key"; exit 1; }
sudo apt-get update -y
sudo apt-get install -y docker-ce || { echo "Failed to install Docker CE"; exit 1; }
sudo usermod -aG docker $(whoami) || { echo "Failed to add user to Docker group"; exit 1; }
sleep 1

echo -e "\e[1m\e[32mFINISH \e[0m" && sleep 1
