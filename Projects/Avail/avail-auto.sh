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

# Set Node Name
read -r -p "Enter Node Name: " Avail_VALIDATOR
export Avail_VALIDATOR=$Avail_VALIDATOR
sleep 1

# Pull image new
echo -e "\e[1m\e[32m4. Pull image... \e[0m" && sleep 1
docker pull availj/avail:v1.9.0.0

# Run Node
echo -e "\e[1m\e[32m5. Run node avail... \e[0m" && sleep 1
sudo docker run -v $(pwd)/avail/:/da/avail:rw --network host -d --restart unless-stopped availj/avail:v1.9.0.0 --chain goldberg --name "${Avail_VALIDATOR}" --validator -d /da/avail

# Allow port 30333
echo -e "\e[1m\e[32m6. Allow Port 30333... \e[0m" && sleep 1
sudo ufw allow 30333/tcp
sudo ufw allow 30333/udp

rm -r $HOME/avail-auto.sh

NAMES=`docker ps | egrep 'availj/avail' | awk '{print $10}'`

# Command check
echo '====================== SETUP FINISHED ======================'
echo -e "\e[1;32mView the logs from the running: \e[0m\e[1;36msudo docker logs -f ${NAMES}\e[0m"
echo -e "\e[1;32mCheck the list of containers: \e[0m\e[1;36msudo docker ps -a\e[0m"
echo -e "\e[1;32mStart your node: \e[0m\e[1;36msudo docker start ${NAMES}\e[0m"
echo -e "\e[1;32mRestart your node: \e[0m\e[1;36msudo docker restart ${NAMES}\e[0m"
echo -e "\e[1;32mStop your node: \e[0m\e[1;36msudo docker stop ${NAMES}\e[0m"
echo -e "\e[1;32mRemove: \e[0m\e[1;36msudo docker rm ${NAMES}\e[0m"
echo '============================================================='     
            break
            ;;
        "Update Node")
NAMES=`docker ps | egrep 'availj/avail' | awk '{print $10}'`
docker stop ${NAMES}
docker rm ${NAMES}

# Pull image new
echo -e "\e[1m\e[32m4. Pull image... \e[0m" && sleep 1
docker pull availj/avail:v1.9.0.0

# Run Node
echo -e "\e[1m\e[32m5. Run node avail... \e[0m" && sleep 1
sudo docker run -v $(pwd)/avail/:/da/avail:rw --network host -d --restart unless-stopped availj/avail:v1.9.0.0 --chain goldberg --name "${Avail_VALIDATOR}" --validator -d /da/avail

rm -r $HOME/avail-auto.sh

# Command check
echo '====================== SETUP FINISHED ======================'
echo -e "\e[1;32mView the logs from the running: \e[0m\e[1;36msudo docker logs -f ${NAMES}\e[0m"
echo -e "\e[1;32mCheck the list of containers: \e[0m\e[1;36msudo docker ps -a\e[0m"
echo -e "\e[1;32mStart your node: \e[0m\e[1;36msudo docker start ${NAMES}\e[0m"
echo -e "\e[1;32mRestart your node: \e[0m\e[1;36msudo docker restart ${NAMES}\e[0m"
echo -e "\e[1;32mStop your node: \e[0m\e[1;36msudo docker stop ${NAMES}\e[0m"
echo -e "\e[1;32mRemove: \e[0m\e[1;36msudo docker rm ${NAMES}\e[0m"
echo '============================================================='         
            break
            ;;
        "Remove Node")
# Remove the Guardian Node
NAMES=`docker ps | egrep 'availj/avail' | awk '{print $10}'`
docker stop ${NAMES}
docker rm ${NAMES}
rm -r $HOME/avail
rm $HOME/avail-auto.sh
            break
            ;;
        "Quit")
rm $HOME/avail-auto.sh
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
