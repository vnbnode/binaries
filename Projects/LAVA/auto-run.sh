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

# Set Var
read -r -p "Enter node moniker: " MONIKER
sleep 1

#Update system
echo -e "\e[1m\e[32m1. Updating packages and dependencies--> \e[0m" && sleep 1
sudo apt -q update
sudo apt -qy install curl git jq lz4 build-essential
sudo apt -qy upgrade
sudo apt install build-essential
sudo apt install -y unzip logrotate git jq sed wget curl coreutils systemd
# Create the temp dir for the installation
temp_folder=$(mktemp -d) && cd $temp_folder

#INSTALL GO
### Configurations
go_package_url="https://go.dev/dl/go1.20.5.linux-amd64.tar.gz"
go_package_file_name=${go_package_url##*\/}
# Download GO
wget -q $go_package_url
# Unpack the GO installation file
sudo tar -C /usr/local -xzf $go_package_file_name
# Environment adjustments
echo "export PATH=\$PATH:/usr/local/go/bin" >>~/.profile
echo "export PATH=\$PATH:\$(go env GOPATH)/bin" >>~/.profile
source ~/.profile
go version

#Install all Binaries
echo -e "\e[1m\e[32m3. Downloading and building binaries--> \e[0m" && sleep 1
git clone https://github.com/lavanet/lava.git
cd lava
make install-all
lavad version && lavap version  && sleep 1
#Build all Binaries
make build-all

echo -e "\e[1m\e[32m4. Download app configurations--> \e[0m" && sleep 1
git clone https://github.com/lavanet/lava-config.git
cd lava-config/testnet-2
source setup_config/setup_config.sh
echo "Lava config file path: $lava_config_folder"
mkdir -p $lavad_home_folder
mkdir -p $lava_config_folder
cp default_lavad_config_files/* $lava_config_folder

echo -e "\e[1m\e[32m5. Set the genesis file--> \e[0m" && sleep 1
cp genesis_json/genesis.json $lava_config_folder/genesis.json

echo -e "\e[1m\e[32m6. Set up Cosmovisor--> \e[0m" && sleep 1
go install github.com/cosmos/cosmos-sdk/cosmovisor/cmd/cosmovisor@v1.0.0
mkdir -p $lavad_home_folder/cosmovisor/genesis/bin/
wget -O  $lavad_home_folder/cosmovisor/genesis/bin/lavad "https://github.com/lavanet/lava/releases/download/v0.21.1.2/lavad-v0.21.1.2-linux-amd64"
chmod +x $lavad_home_folder/cosmovisor/genesis/bin/lavad
sleep 0.5
echo "# Setup Cosmovisor" >> ~/.profile
echo "export DAEMON_NAME=lavad" >> ~/.profile
echo "export CHAIN_ID=lava-testnet-2" >> ~/.profile
echo "export DAEMON_HOME=$HOME/.lava" >> ~/.profile
echo "export DAEMON_ALLOW_DOWNLOAD_BINARIES=true" >> ~/.profile
echo "export DAEMON_LOG_BUFFER_SIZE=512" >> ~/.profile
echo "export DAEMON_RESTART_AFTER_UPGRADE=true" >> ~/.profile
echo "export UNSAFE_SKIP_BACKUP=true" >> ~/.profile
source ~/.profile

echo -e "\e[1m\e[32m7. Initialize the chain--> \e[0m" && sleep 1
$lavad_home_folder/cosmovisor/genesis/bin/lavad init \
my-node \
--chain-id lava-testnet-2 \
--home $lavad_home_folder \
--overwrite
cp genesis_json/genesis.json $lava_config_folder/genesis.json

echo -e "\e[1m\e[32m8. Create Cosmovisor unit file--> \e[0m" && sleep 1
echo "[Unit]
Description=Cosmovisor daemon
After=network-online.target
[Service]
Environment="DAEMON_NAME=lavad"
Environment="DAEMON_HOME=${HOME}/.lava"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=true"
Environment="DAEMON_LOG_BUFFER_SIZE=512"
Environment="UNSAFE_SKIP_BACKUP=true"
User=$USER
ExecStart=${HOME}/go/bin/cosmovisor start --home=$lavad_home_folder --p2p.seeds $seed_node
Restart=always
RestartSec=3
LimitNOFILE=infinity
LimitNPROC=infinity
[Install]
WantedBy=multi-user.target
" >cosmovisor.service
sudo mv cosmovisor.service /lib/systemd/system/cosmovisor.service

echo -e "\e[1m\e[32m9. Run Cosmovisor unit file--> \e[0m" && sleep 1
sudo systemctl daemon-reload
sudo systemctl enable cosmovisor.service
sudo systemctl restart systemd-journald
sudo systemctl start cosmovisor

# Logo
sleep 1 && curl -s https://raw.githubusercontent.com/vnbnode/binaries/main/Logo/logo.sh | bash && sleep 1
echo '====================== SETUP FINISHED =============================================================='
echo 'echo -e "\e[1;32mCheck status: \e[0m\e[1;36m${CYAN}sudo systemctl status cosmovisor\e[0m"
echo -e "\e[1;32mCheck logs: \e[0m\e[1;36m${CYAN}sudo systemctl status cosmovisor\e[0m"
echo -e "\e[1;32mCheck synchronization: \e[0m\e[1;36m${CYAN}$HOME/.lava/cosmovisor/current/bin/lavad status | jq .SyncInfo.catching_up\e[0m"
echo -e "\e[1;32mMore commands: \e[0m\e[1;36m${CYAN}$GITHUB${NC}\e[0m"
echo '====================================================================================================='
