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

# Choice Option
PS3='Please enter your choice: '
options=("Install Node" "Update Node" "Remove Node" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Install Node")
# Update
echo -e "\e[1m\e[32m1. Update... \e[0m" && sleep 1
sudo apt update && sudo apt upgrade -y

# Package
echo -e "\e[1m\e[32m2. Installing package... \e[0m" && sleep 1
sudo apt install curl tar wget clang pkg-config protobuf-compiler libssl-dev jq build-essential protobuf-compiler bsdmainutils git make ncdu gcc git jq chrony liblz4-tool -y

# Check if Docker is already installed
echo -e "\e[1m\e[32m3. Installing Docker... \e[0m" && sleep 1
if command -v docker > /dev/null 2>&1; then
echo "Docker is already installed."
else
# Docker is not installed, proceed with installation
echo -e "\e[1m\e[32m3. Installing Docker... \e[0m" && sleep 1
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
rm $HOME/get-docker.sh
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
docker -v
fi

# Set walletbevm
read -r -p "Enter Wallet BEVM: " Walletbevm
while [ "$Walletbevm" == "" ]
do
  echo -e "\033[0;31m   >.< x Incorrect DIR_PATH. \033[0m \n"
  read -p ' Enter DIR_PATH again: ' Walletbevm
done

# Pull image new
echo -e "\e[1m\e[32m4. Pull image... \e[0m" && sleep 1
cd /var/lib
rm -r node_bevm_test_storage
mkdir node_bevm_test_storage
sudo docker pull btclayer2/bevm:v0.1.1
sleep 1

# Run Node
echo -e "\e[1m\e[32m5. Run node... \e[0m" && sleep 1
sudo docker run -d --name bevm -v /var/lib/node_bevm_test_storage:/root/.local/share/bevm btclayer2/bevm:v0.1.1 bevm "--chain=testnet" "--name=$Walletbevm" "--pruning=archive" --telemetry-url "wss://telemetry.bevm.io/submit 0"

# NAMES=`docker ps | egrep 'btclayer2/bevm' | awk '{print $16}'`

# Command check
echo '====================== SETUP FINISHED ======================'
echo -e "\e[1;32mView the logs from the running: \e[0m\e[1;36msudo docker logs -f bevm\e[0m"
echo -e "\e[1;32mCheck the list of containers: \e[0m\e[1;36msudo docker ps -a\e[0m"
echo -e "\e[1;32mStart your node: \e[0m\e[1;36msudo docker start bevm\e[0m"
echo -e "\e[1;32mRestart your node: \e[0m\e[1;36msudo docker restart bevm\e[0m"
echo -e "\e[1;32mStop your node: \e[0m\e[1;36msudo docker stop bevm\e[0m"
echo -e "\e[1;32mRemove: \e[0m\e[1;36msudo docker rm bevm\e[0m"
echo '============================================================='     
            break
            ;;
        "Update Node")
# NAMES=`docker ps | egrep 'btclayer2/bevm' | awk '{print $16}'`
docker stop bevm
docker rm bevm

# Pull image new
echo -e "\e[1m\e[32m1. Pull image... \e[0m" && sleep 1
sudo docker pull btclayer2/bevm:v0.1.1

# Run Node
echo -e "\e[1m\e[32m2. Run node... \e[0m" && sleep 1
sudo docker run -d --name bevm -v /var/lib/node_bevm_test_storage:/root/.local/share/bevm btclayer2/bevm:v0.1.1 bevm "--chain=testnet" "--name=$Walletbevm" "--pruning=archive" --telemetry-url "wss://telemetry.bevm.io/submit 0"

# Command check
echo '====================== SETUP FINISHED ======================'
echo -e "\e[1;32mView the logs from the running: \e[0m\e[1;36msudo docker logs -f bevm\e[0m"
echo -e "\e[1;32mCheck the list of containers: \e[0m\e[1;36msudo docker ps -a\e[0m"
echo -e "\e[1;32mStart your node: \e[0m\e[1;36msudo docker start bevm\e[0m"
echo -e "\e[1;32mRestart your node: \e[0m\e[1;36msudo docker restart bevm\e[0m"
echo -e "\e[1;32mStop your node: \e[0m\e[1;36msudo docker stop bevm\e[0m"
echo -e "\e[1;32mRemove: \e[0m\e[1;36msudo docker rm bevm\e[0m"
echo '============================================================='             
            break
            ;;
        "Remove Node")
# Remove the Guardian Node
# NAMES=`docker ps | egrep 'btclayer2/bevm' | awk '{print $14}'`
docker stop bevm
docker rm bevm
rm -r /var/lib/node_bevm_test_storage
            break
            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
