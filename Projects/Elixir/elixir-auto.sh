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

# ADDRESS
echo -e "\e[1m\e[32m3. Fill data... \e[0m" && sleep 1
read -p ' ^|^m Enter ADDRESS: ' address_ev

while [ "$address_ev" == "" ]
do
  echo -e "\033[0;31m   ^|^x Incorrect ADDRESS. \033[0m \n"
  read -p ' ^|^m Enter ADDRESS again: ' address_ev
done

# PRIVATE_KEY
read -p ' ^|^m Enter PRIVATE_KEY: ' private_key_ev

while [ "$private_key_ev" == "" ]
do
  echo -e "\033[0;31m   ^|^x Incorrect PRIVATE_KEY. \033[0m \n"
  read -p ' ^|^m Enter PRIVATE_KEY again: ' private_key_ev
done

# VALIDATOR_NAME
read -p ' ^|^m Enter VALIDATOR_NAME: ' validator_name_ev

while [ "$validator_name_ev" == "" ]
do
  echo -e "\033[0;31m   ^|^x Incorrect VALIDATOR_NAME. \033[0m \n"
  read -p ' ^|^m Enter VALIDATOR_NAME again: ' validator_name_ev
done

# Create Dir
mkdir "$HOME/ev"
EV_DIR="$HOME/ev"
DOCKERFILE="$EV_DIR"
mkdir -p "$DOCKERFILE"

# Output the password to a file
echo 'FROM elixirprotocol/validator:testnet-2' >> $DOCKERFILE/Dockerfile
echo '' >> $DOCKERFILE/Dockerfile
echo 'ENV ADDRESS='$address_ev >> $DOCKERFILE/Dockerfile
echo 'ENV PRIVATE_KEY='$private_key_ev >> $DOCKERFILE/Dockerfile
echo 'ENV VALIDATOR_NAME='$validator_name_ev >> $DOCKERFILE/Dockerfile
chmod 775 $DOCKERFILE/Dockerfile

# Build Dockerfile
echo -e "\e[1m\e[32m4. Build Dockerfile... \e[0m" && sleep 1
cd $HOME
cd ev
docker build . -f Dockerfile -t elixir-validator
sleep 1

# Run Node
echo -e "\e[1m\e[32m5. Run Node... \e[0m" && sleep 1
docker run -d --restart unless-stopped --name ev elixir-validator
docker update --restart=unless-stopped ev
sleep 1

cd $HOME
rm $HOME/elixir-auto.sh
# NAMES=`docker ps | egrep 'elixir-validator' | awk '{print $16}'`

# Command check
echo '====================== SETUP FINISHED ======================'
echo -e "\e[1;32mView the logs from the running: \e[0m\e[1;36msudo docker logs -f ev\e[0m"
echo -e "\e[1;32mCheck the list of containers: \e[0m\e[1;36msudo docker ps -a\e[0m"
echo -e "\e[1;32mStart your node: \e[0m\e[1;36msudo docker start ev\e[0m"
echo -e "\e[1;32mRestart your node: \e[0m\e[1;36msudo docker restart ev\e[0m"
echo -e "\e[1;32mStop your node: \e[0m\e[1;36msudo docker stop ev\e[0m"
echo -e "\e[1;32mRemove: \e[0m\e[1;36msudo docker rm ev\e[0m"
echo '============================================================='
