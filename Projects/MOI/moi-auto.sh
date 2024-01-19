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

# Fill data
echo -e "\e[1m\e[32m4. Fill data... \e[0m" && sleep 1

## DIR_PATH
read -r -p "DIR_PATH: " moi_dirpath
while [ "$moi_dirpath" == "" ]
do
  echo -e "\033[0;31m   >.< x Incorrect DIR_PATH. \033[0m \n"
  read -p ' Enter DIR_PATH again: ' moi_dirpath
done

## KEYSTORE_PATH
read -r -p "KEYSTORE_PATH: " moi_keystore
while [ "$moi_keystore" == "" ]
do
  echo -e "\033[0;31m   >.< x Incorrect KEYSTORE_PATH. \033[0m \n"
  read -p ' Enter KEYSTORE_PATH again: ' moi_keystore
done

## PASSWD
read -r -p "PASSWORD KEYSTORE: " moi_passwd
while [ "$moi_passwd" == "" ]
do
  echo -e "\033[0;31m   >.< x Incorrect PASSWORD KEYSTORE. \033[0m \n"
  read -p ' Enter PASSWORD KEYSTORE again: ' moi_passwd
done

## ADDRESS
read -r -p "ADDRESS: " moi_address
while [ "$moi_address" == "" ]
do
  echo -e "\033[0;31m   >.< x Incorrect ADDRESS. \033[0m \n"
  read -p ' Enter ADDRESS again: ' moi_address
done

## INDEX
read -r -p "KRAMA ID INDEX: " moi_index
while [ "$moi_index" == "" ]
do
  echo -e "\033[0;31m   >.< x Incorrect KRAMA ID INDEX. \033[0m \n"
  read -p ' Enter KRAMA ID INDEX again: ' moi_index
done

## IP
read -r -p "IP PUBLIC: " moi_ip
while [ "$moi_ip" == "" ]
do
  echo -e "\033[0;31m   >.< x Incorrect IP PUBLIC. \033[0m \n"
  read -p ' Enter IP PUBLIC again: ' moi_ip
done

## Container name
read -r -p "Container_name: " container_name_moi
while [ "$container_name_moi" == "" ]
do
  echo -e "\033[0;31m   >.< x Incorrect Container_name. \033[0m \n"
  read -p ' Enter Container_name again: ' container_name_moi
done

# Register and Start the Guardian Node
echo -e "\e[1m\e[32m5. Register the Guardian Node... \e[0m" && sleep 1
SelectVersion="Please choose: \n 1. CPU from 2015 or later\n 2. CPU from 2015 or earlier"
echo -e "${SelectVersion}"
read -p "Enter index: " version;
if [ "$version" != "2" ];then
	sudo docker run --network host --rm -it -w /data -v $(pwd):/data sarvalabs/moipod:latest register --data-dir $moi_dirpath --mnemonic-keystore-path $moi_dirpath/keystore.json --mnemonic-keystore-password $moi_passwd --watchdog-url https://babylon-watchdog.moi.technology/add --node-password $moi_passwd --network-rpc-url https://voyage-rpc.moi.technology/babylon --wallet-address $moi_address --node-index $moi_index --local-rpc-url http://$moi_ip:1600
        sudo docker run --name $container_name_moi --network host -it -d -w /data -v $(pwd):/data sarvalabs/moipod:latest server --babylon --data-dir $moi_dirpath --log-level DEBUG --node-password $moi_passwd
        docker update --restart=unless-stopped $container_name_moi
else
        sudo docker run --network host --rm -it -w /data -v $(pwd):/data sarvalabs/moipod:v0.5.0-port register --data-dir $moi_dirpath --mnemonic-keystore-path $moi_dirpath/keystore.json --mnemonic-keystore-password $moi_passwd --watchdog-url https://babylon-watchdog.moi.technology/add --node-password $moi_passwd --network-rpc-url https://voyage-rpc.moi.technology/babylon --wallet-address $moi_address --node-index $moi_index --local-rpc-url http://$moi_ip:1600
	sudo docker run --name $container_name_moi --network host -it -d -w /data -v $(pwd):/data sarvalabs/moipod:v0.5.0-port server --babylon --data-dir $moi_dirpath --log-level DEBUG --node-password $moi_passwd
        docker update --restart=unless-stopped $container_name_moi
fi

# Allow port 30333
echo -e "\e[1m\e[32m6. Allow Port 1600 and 6000... \e[0m" && sleep 1
sudo ufw allow 1600/tcp
sudo ufw allow 6000/tcp
sudo ufw allow 6000/udp

# NAMES=`docker ps | egrep 'sarvalabs/moipod' | awk '{print $18}'`

# Command check
echo '====================== SETUP FINISHED ======================'
echo -e "\e[1;32mView the logs from the running: \e[0m\e[1;36mtail -f $moi_dirpath/log/3*\e[0m"
echo -e "\e[1;32mView the logs from the running: \e[0m\e[1;36msudo docker logs -f $container_name_moi\e[0m"
echo -e "\e[1;32mCheck the list of containers: \e[0m\e[1;36msudo docker ps -a\e[0m"
echo -e "\e[1;32mStart your node: \e[0m\e[1;36msudo docker start $container_name_moi\e[0m"
echo -e "\e[1;32mRestart your node: \e[0m\e[1;36msudo docker restart $container_name_moi\e[0m"
echo -e "\e[1;32mStop your node: \e[0m\e[1;36msudo docker stop $container_name_moi\e[0m"
echo -e "\e[1;32mRemove: \e[0m\e[1;36msudo docker rm $container_name_moi\e[0m"
echo '============================================================='            
            break
            ;;
        "Update Node")
# Update the Guardian Node
echo -e "\e[1m\e[32mUpdate the Guardian Node... \e[0m" && sleep 1
SelectVersion="Please choose: \n 1. CPU from 2015 or later\n 2. CPU from 2015 or earlier"
echo -e "${SelectVersion}"
read -p "Enter index: " version;
if [ "$version" != "2" ];then
    docker stop $container_name_moi
    docker rm $container_name_moi
    sudo docker run --name $container_name_moi --network host -it -d -w /data -v $(pwd):/data sarvalabs/moipod:latest server --babylon --data-dir $moi_dirpath --log-level DEBUG --node-password $moi_passwd
    docker update --restart=unless-stopped $container_name_moi
else
    docker stop $container_name_moi
    docker rm $container_name_moi
	sudo docker run --name $container_name_moi --network host -it -d -w /data -v $(pwd):/data sarvalabs/moipod:v0.5.0-port server --babylon --data-dir $moi_dirpath --log-level DEBUG --node-password $moi_passwd
    docker update --restart=unless-stopped $container_name_moi
fi

# Command check
echo '====================== SETUP FINISHED ======================'
echo -e "\e[1;32mView the logs from the running: \e[0m\e[1;36mtail -f $moi_dirpath/log/3*\e[0m"
echo -e "\e[1;32mView the logs from the running: \e[0m\e[1;36msudo docker logs -f $container_name_moi\e[0m"
echo -e "\e[1;32mCheck the list of containers: \e[0m\e[1;36msudo docker ps -a\e[0m"
echo -e "\e[1;32mStart your node: \e[0m\e[1;36msudo docker start $container_name_moi\e[0m"
echo -e "\e[1;32mRestart your node: \e[0m\e[1;36msudo docker restart $container_name_moi\e[0m"
echo -e "\e[1;32mStop your node: \e[0m\e[1;36msudo docker stop $container_name_moi\e[0m"
echo -e "\e[1;32mRemove: \e[0m\e[1;36msudo docker rm $container_name_moi\e[0m"
echo '============================================================='
            break
            ;;
        "Remove Node")
# Remove the Guardian Node
docker stop $container_name_moi
docker rm $container_name_moi
rm -r $HOME/moi
            break
            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
