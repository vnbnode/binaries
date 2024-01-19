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
echo -e "\e[1m\e[32m3. Check if Docker is already installed... \e[0m" && sleep 1
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

# Pull image new
echo -e "\e[1m\e[32m4. Pull image... \e[0m" && sleep 1
docker pull pactus/pactus

# Create wallet or Recovery wallet
echo -e "\e[1m\e[32m5. Create wallet or Recovery wallet... \e[0m" && sleep 1
SelectVersion="Please choose: \n 1. Create wallet (Gives you 60 seconds to save the seed wallet)\n 2. Recovery wallet"
echo -e "${SelectVersion}"
read -p "Enter index: " version;
if [ "$version" != "2" ];then
	docker run -it --rm -v ~/pactus:/root/pactus pactus/pactus pactus-daemon init
    sleep 30
else

# Fill Wallet Seed
read -r -p "Enter Seed Wallet: " pastus_walletseed
while [ "$pastus_walletseed" == "" ]
do
  echo -e "\033[0;31m   >.< x Incorrect Seed Wallet. \033[0m \n"
  read -p ' Enter Seed Wallet again: ' pastus_walletseed
done

# Recovery wallet seed
docker run -it --rm -v ~/pactus:/root/pactus pactus/pactus pactus-daemon init --restore "$pastus_walletseed"
fi

# Fill in Password Wallet
read -r -p "Enter Password Wallet: " passpactus
while [ "$passpactus" == "" ]
do
  echo -e "\033[0;31m   >.< x Incorrect Password Wallet. \033[0m \n"
  read -p ' Enter Password Wallet again: ' passpactus
done

## Container name
read -r -p "Enter Container name: " container_name_pactus
while [ "$container_name_pactus" == "" ]
do
  echo -e "\033[0;31m   >.< x Incorrect Container name. \033[0m \n"
  read -p ' Enter Container name again: ' container_name_pactus
done

# Run Node
echo -e "\e[1m\e[32m6. Run node pactus... \e[0m" && sleep 1
docker run -it -d -v ~/pactus:/root/pactus --network host --name $container_name_pactus pactus/pactus pactus-daemon start --password $passpactus
docker update --restart=unless-stopped pactus

# NAMES=`docker ps | egrep 'pactus/pactus' | awk '{print $13}'`

# Command check
echo '====================== SETUP FINISHED ======================'
echo -e "\e[1;32mView the logs from the running: \e[0m\e[1;36msudo docker logs -f $container_name_pactus\e[0m"
echo -e "\e[1;32mCheck the list of containers: \e[0m\e[1;36msudo docker ps -a\e[0m"
echo -e "\e[1;32mStart your node: \e[0m\e[1;36msudo docker start $container_name_pactus\e[0m"
echo -e "\e[1;32mRestart your node: \e[0m\e[1;36msudo docker restart $container_name_pactus\e[0m"
echo -e "\e[1;32mStop your node: \e[0m\e[1;36msudo docker stop $container_name_pactuss\e[0m"
echo '============================================================='          
            break
            ;;
        "Update Node")
docker stop $container_name_pactuss
docker rm $container_name_pactuss

# Pull image new
echo -e "\e[1m\e[32m4. Pull image... \e[0m" && sleep 1
docker pull pactus/pactus

# Run Node
echo -e "\e[1m\e[32m6. Run node pactus... \e[0m" && sleep 1
docker run -it -d -v ~/pactus:/root/pactus --network host --name $container_name_pactus pactus/pactus pactus-daemon start --password $passpactus
docker update --restart=unless-stopped pactus

# Command check
echo '====================== SETUP FINISHED ======================'
echo -e "\e[1;32mView the logs from the running: \e[0m\e[1;36msudo docker logs -f $container_name_pactus\e[0m"
echo -e "\e[1;32mCheck the list of containers: \e[0m\e[1;36msudo docker ps -a\e[0m"
echo -e "\e[1;32mStart your node: \e[0m\e[1;36msudo docker start $container_name_pactus\e[0m"
echo -e "\e[1;32mRestart your node: \e[0m\e[1;36msudo docker restart $container_name_pactus\e[0m"
echo -e "\e[1;32mStop your node: \e[0m\e[1;36msudo docker stop $container_name_pactuss\e[0m"
echo '============================================================='    
            ;;
        "Remove Node")
# Remove Node
docker stop $container_name_pactus
docker rm $container_name_pactus
rm -r $HOME/avail
            break
            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
