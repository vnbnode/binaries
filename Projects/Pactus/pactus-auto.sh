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

# Update
echo -e "\e[1m\e[32m1. Update... \e[0m" && sleep 1
sudo apt update && sudo apt upgrade -y
sleep 1

# Package
echo -e "\e[1m\e[32m2. Installing package... \e[0m" && sleep 1
sudo apt install curl tar wget clang pkg-config protobuf-compiler libssl-dev jq build-essential protobuf-compiler bsdmainutils git make ncdu gcc git jq chrony liblz4-tool -y
sleep 1

# Check if Docker is already installed
if command -v docker > /dev/null 2>&1; then
echo "Docker is already installed."
else
# Docker is not installed, proceed with installation
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
rm $HOME/get-docker.sh
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
docker -v
fi
sleep 1

# Pull image new
echo -e "\e[1m\e[32m4. Pull image... \e[0m" && sleep 1
docker pull pactus/pactus
sleep 1

# Create wallet or Recovery wallet
echo -e "\e[1m\e[32m5. Create wallet or Recovery wallet... \e[0m" && sleep 1
SelectVersion="Please choose: \n 1. Create wallet (Gives you 60 seconds to save the seed wallet)\n 2. Recovery wallet"
echo -e "${SelectVersion}"
read -p "Enter index: " version;
if [ "$version" != "2" ];then
	docker run -it --rm -v ~/pactus:/root/pactus pactus/pactus pactus-daemon init
    sleep 60
else
# Fill Wallet Seed
if [ ! $walletseed ]; then
    read -p "Fill in wallet seed: " walletseed
    echo 'export walletseed='\"${walletseed}\" >> $HOME/.bash_profile
fi
echo 'source $HOME/.bashrc' >> $HOME/.bash_profile
source $HOME/.bash_profile
sleep 1
# Recovery wallet seed
docker run -it --rm -v ~/pactus:/root/pactus pactus/pactus pactus-daemon init --restore "$walletseed"
fi
sleep 1

# Fill in wallet password
if [ ! $passpactus ]; then
    read -p "Fill in wallet password: " passpactus
    echo 'export passpactus='\"${passpactus}\" >> $HOME/.bash_profile
fi
echo 'source $HOME/.bashrc' >> $HOME/.bash_profile
source $HOME/.bash_profile
sleep 1

## Container name
if [ ! $container_name_pactus ]; then
    read -p "Container_name: " container_name_pactus
    echo 'export container_name_pactus='\"${container_name_pactus}\" >> $HOME/.bash_profile
fi
echo 'source $HOME/.bashrc' >> $HOME/.bash_profile
source $HOME/.bash_profile
sleep 1

# Run Node
echo -e "\e[1m\e[32m6. Run node pactus... \e[0m" && sleep 1
docker run -it -d -v ~/pactus:/root/pactus --network host --name $container_name_pactus pactus/pactus pactus-daemon start --password $passpactus
docker update --restart=unless-stopped pactus
sleep 1

# NAMES=`docker ps | egrep 'pactus/pactus' | awk '{print $13}'`
rm $HOME/pactus-auto.sh

# Command check
echo '====================== SETUP FINISHED ======================'
echo -e "\e[1;32mView the logs from the running: \e[0m\e[1;36msudo docker logs -f $container_name_pactus\e[0m"
echo -e "\e[1;32mCheck the list of containers: \e[0m\e[1;36msudo docker ps -a\e[0m"
echo -e "\e[1;32mStart your node: \e[0m\e[1;36msudo docker start $container_name_pactus\e[0m"
echo -e "\e[1;32mRestart your node: \e[0m\e[1;36msudo docker restart $container_name_pactus\e[0m"
echo -e "\e[1;32mStop your node: \e[0m\e[1;36msudo docker stop $container_name_pactuss\e[0m"
echo -e "\e[1;32mRemove: \e[0m\e[1;36msudo docker rm $container_name_pactus\e[0m"
echo '============================================================='
