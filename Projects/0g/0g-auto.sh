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
main_menu() {
    PS3='Please enter your choice: '
    options=("Install Validator" "Install Storage Node" "Install Storage KV" "Install DA Node" "Quit")
    select opt in "${options[@]}"
    do
        case $opt in
            "Install Validator")                
                validator_menu
                ;;
            "Install Storage Node")
                storage_menu
                ;;
            "Install Storage KV")                
                kv_menu
                ;;
            "Install DA Node")               
                da_menu
                ;;            
            "Quit")
                echo "Quitting..."
                exit 0
                ;;
            *) 
                echo "Invalid option $REPLY"
                ;;
        esac
    done
}

validator_menu() {
    PS3='Please enter your choice: '
    options=("Install" "Remove Validator" "Back" "Quit")
    select opt in "${options[@]}"
    do
        case $opt in
            "Install")
# Update and install packages for compiling
echo -e "\e[1m\e[32m1. Update... \e[0m" && sleep 1
sudo apt update && sudo apt upgrade -y
sudo apt install curl tar wget clang pkg-config protobuf-compiler libssl-dev jq build-essential protobuf-compiler bsdmainutils git make ncdu gcc git jq chrony liblz4-tool -y
sudo apt -qy upgrade

## Go
echo -e "\e[1m\e[32m3. Installing Go... \e[0m" && sleep 1
VER="1.21.3"
wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
rm "go$VER.linux-amd64.tar.gz"
[ ! -f ~/.bash_profile ] && touch ~/.bash_profile
echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
source $HOME/.bash_profile
[ ! -d ~/go/bin ] && mkdir -p ~/go/bin

# Build binary
echo -e "\e[1m\e[32m4. Build binary... \e[0m" && sleep 1
#git clone -b v0.3.0-testnet https://github.com/0glabs/0g-chain.git
#git checkout v0.3.0-testnet
#./0g-chain/networks/testnet/install.sh
#source ~/.profile
#cd 0g-chain
#make install
wget -O $HOME/0gchaind https://github.com/0glabs/0g-chain/releases/download/v0.3.2/0gchaind-linux-v0.3.2
chmod +x $HOME/0gchaind
mv $HOME/0gchaind $HOME/go/bin/0gchaind
mkdir -p $HOME/.0gchain/cosmovisor/genesis/bin
cp $HOME/go/bin/0gchaind $HOME/.0gchain/cosmovisor/genesis/bin/
sudo ln -s $HOME/.0gchain/cosmovisor/genesis $HOME/.0gchain/cosmovisor/current -f
sudo ln -s $HOME/.0gchain/cosmovisor/current/bin/0gchaind /usr/local/bin/0gchaind -f

# Cosmovisor Setup
echo -e "\e[1m\e[32m4. Cosmovisor Setup... \e[0m" && sleep 1
go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@v1.5.0
sudo tee /etc/systemd/system/0g.service > /dev/null << EOF
[Unit]
Description=0G node service
After=network-online.target
 
[Service]
User=$USER
ExecStart=$(which cosmovisor) run start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
Environment="DAEMON_NAME=0gchaind"
Environment="DAEMON_HOME=/root/.0gchain"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=true"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable 0g

# Fill Moniker
echo -e "\e[1m\e[32m5. Initialize Node... \e[0m" && sleep 1
read -r -p "MONIKER: " MONIKER
while [ "$MONIKER" == "" ]
do
  echo -e "\033[0;31m   >.< x Incorrect MONIKER name. \033[0m \n"
  read -p ' Enter MONIKER again: ' MONIKER
done

# Initialize Node
echo 'export CHAIN_ID="zgtendermint_16600-2"' >> ~/.bash_profile
echo 'export name_project_0g="0g"' >> ~/.bash_profile
echo 'export WALLET_NAME="wallet"' >> ~/.bash_profile
source $HOME/.bash_profile
0gchaind init $MONIKER --chain-id $CHAIN_ID
0gchaind config chain-id $CHAIN_ID
0gchaind config keyring-backend os

# Download Genesis & Addrbook
echo -e "\e[1m\e[32m6. Download Genesis & Addrbook... \e[0m" && sleep 1
rm $HOME/.0gchain/config/genesis.json
wget https://github.com/0glabs/0g-chain/releases/download/v0.2.3/genesis.json -O $HOME/.0gchain/config/genesis.json

# Configure
echo -e "\e[1m\e[32m7. Configure... \e[0m" && sleep 1
seeds=$(curl -s https://raw.githubusercontent.com/vnbnode/binaries/main/Projects/0g/seeds.txt)
sed -i.bak -e "s/^seeds *=.*/seeds = \"$seeds\"/" $HOME/.0gchain/config/config.toml
peers=$(curl -s https://raw.githubusercontent.com/vnbnode/binaries/main/Projects/0g/peers.txt)
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" $HOME/.0gchain/config/config.toml
sed -i.bak -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.0gchain/config/app.toml
sed -i.bak -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.0gchain/config/app.toml
sed -i.bak -e "s/^pruning-interval *=.*/pruning-interval = \"10\"/" $HOME/.0gchain/config/app.toml
sed -i "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0ua0gi\"/" $HOME/.0gchain/config/app.toml
sed -i "s/^indexer *=.*/indexer = \"kv\"/" $HOME/.0gchain/config/config.toml

# Custom Port
echo -e "\e[1m\e[32m8. Custom Port... \e[0m" && sleep 1
echo 'export port="101"' >> ~/.bash_profile
source $HOME/.bash_profile
sed -i -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://0.0.0.0:${port}58\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://0.0.0.0:${port}57\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${port}60\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${port}56\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${port}60\"%" $HOME/.0gchain/config/config.toml
sed -i -e "s%^address = \"tcp://localhost:1317\"%address = \"tcp://0.0.0.0:${port}17\"%; s%^address = \":8080\"%address = \":${port}80\"%; s%^address = \"localhost:9090\"%address = \"0.0.0.0:${port}90\"%; s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${port}91\"%; s%:8545%:${port}45%; s%:8546%:${port}46%; s%:6065%:${port}65%" $HOME/.0gchain/config/app.toml
sed -i.bak -e "s%:1317%:${port}17%g;
s%:8080%:${port}80%g;
s%:9090%:${port}90%g;
s%:9091%:${port}91%g;
s%:8545%:${port}45%g;
s%:8546%:${port}46%g;
s%:6065%:${port}65%g" $HOME/.0gchain/config/app.toml
sed -i.bak -e "s%:26658%:${port}58%g;
s%:26657%:${port}57%g;
s%:6060%:${port}60%g;
s%:26656%:${port}56%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${port}56\"%;
s%:26660%:${port}60%g" $HOME/.0gchain/config/config.toml
sed -i \
  -e 's|^node *=.*|node = "tcp://localhost:10157"|' \
  $HOME/.0gchain/config/client.toml
IP_Public=$(curl -s ifconfig.me)
P2P_Peers=$(echo $(0gchaind tendermint show-node-id)'@'$(curl -s ifconfig.me)':'$(awk -F'[ ":]+' '/^\[p2p\]/ {getline; if ($1 == "laddr") {print $3; exit}}' $HOME/.0gchain/config/config.toml | cut -d':' -f2))

# Start Node
echo -e "\e[1m\e[32m9. Start Node... \e[0m" && sleep 1
sudo systemctl restart 0g

# Command check
echo '====================== SETUP FINISHED ======================'
echo -e "\e[1;32mView the logs from the running: \e[0m\e[1;36mjournalctl -fu $name_project_0g -o cat\e[0m"
echo -e "\e[1;32mStart your node: \e[0m\e[1;36msystemctl start $name_project_0g\e[0m"
echo -e "\e[1;32mRestart your node: \e[0m\e[1;36msystemctl restart $name_project_0g\e[0m"
echo -e "\e[1;32mStop your node: \e[0m\e[1;36msystemctl stop $name_project_0g\e[0m"
echo -e "\e[1;32mIP Public: \e[0m\e[1;36m$IP_Public\e[0m" 
echo -e "\e[1;32mP2P_Peers: \e[0m\e[1;36m$P2P_Peers\e[0m" 
echo '============================================================='
cd $HOME
                ;;
            "Remove Validator")
                echo "Removing Validator..." 
sudo systemctl stop $name_project_0g
sudo systemctl disable $name_project_0g
sudo rm /etc/systemd/system/0g.service
sudo systemctl daemon-reload
sudo rm $HOME/go/bin/0gchaind
sudo rm -f $(which 0gchaind)
sudo rm -rf $HOME/0g-chain
sudo rm -rf $HOME/.0gchain
cd $HOME                              
                ;;
            "Back")
                echo "Going back to the previous menu..."
                main_menu
                return
                ;;
            "Quit")
                echo "Quitting..."
                exit 0
                ;;
            *) 
                echo "Invalid option $REPLY"
                ;;
        esac
    done
}

storage_menu() {
    PS3='Please enter your choice: '
    options=("Install" "Remove Storage Node" "Back" "Quit")
    select opt in "${options[@]}"
    do
        case $opt in
            "Install")
                echo "Install..."
# Input required information
read -p "Type your BLOCKCHAIN_RPC_ENDPOINT: " BLOCKCHAIN_RPC_ENDPOINT
ENR_ADDRESS=$(wget -qO- eth0.me)
read -sp "Enter your private key: " PRIVATE_KEY && echo

# Save information to .bash_profile
echo "export BLOCKCHAIN_RPC_ENDPOINT=\"$BLOCKCHAIN_RPC_ENDPOINT\"" >> ~/.bash_profile
echo "export ENR_ADDRESS=\"$ENR_ADDRESS\"" >> ~/.bash_profile
echo 'export LOG_CONTRACT_ADDRESS="0x8873cc79c5b3b5666535C825205C9a128B1D75F1"' >> ~/.bash_profile
echo 'export MINE_CONTRACT_ADDRESS="0x85F6722319538A805ED5733c5F4882d96F1C7384"' >> ~/.bash_profile
echo 'export ZGS_LOG_SYNC_BLOCK="802"' >> ~/.bash_profile
source ~/.bash_profile

# Display the configured variables
echo -e "\n\033[31mCHECK YOUR VARIABLES\033[0m\n\nENR_ADDRESS: $ENR_ADDRESS\nLOG_CONTRACT_ADDRESS: $LOG_CONTRACT_ADDRESS\nMINE_CONTRACT_ADDRESS: $MINE_CONTRACT_ADDRESS\nZGS_LOG_SYNC_BLOCK: $ZGS_LOG_SYNC_BLOCK\nBLOCKCHAIN_RPC_ENDPOINT: $BLOCKCHAIN_RPC_ENDPOINT\n\n\033[33mby VNBnode.\033[0m"

# 1. System updates and installation of required environments
sudo apt-get update
sudo apt-get install -y clang cmake build-essential git cargo

# Go
echo -e "\e[1m\e[32m3. Installing Go... \e[0m" && sleep 1
VER="1.21.3"
wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
rm "go$VER.linux-amd64.tar.gz"
[ ! -f ~/.bash_profile ] && touch ~/.bash_profile
echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
source $HOME/.bash_profile
[ ! -d ~/go/bin ] && mkdir -p ~/go/bin

# Rust
export RUSTUP_INIT_SKIP_PATH_CHECK=yes
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env

# 4. Git clone the 0g storage node repository
git clone -b v0.5.0 https://github.com/0glabs/0g-storage-node.git
cd $HOME/0g-storage-node
git fetch
git checkout tags/v0.5.0
git submodule update --init

# 5. Build the project
cargo build --release

# 6. Update config.toml with necessary parameters
sed -i '
s|^\s*#\?\s*network_dir\s*=.*|network_dir = "network"|
s|^\s*#\?\s*network_enr_address\s*=.*|network_enr_address = "'"$ENR_ADDRESS"'"|
s|^\s*#\?\s*network_enr_tcp_port\s*=.*|network_enr_tcp_port = 1234|
s|^\s*#\?\s*network_enr_udp_port\s*=.*|network_enr_udp_port = 1234|
s|^\s*#\?\s*network_libp2p_port\s*=.*|network_libp2p_port = 1234|
s|^\s*#\?\s*network_discovery_port\s*=.*|network_discovery_port = 1234|
s|^\s*#\?\s*rpc_enabled\s*=.*|rpc_enabled = true|
s|^\s*#\?\s*db_dir\s*=.*|db_dir = "db"|
s|^\s*#\?\s*log_config_file\s*=.*|log_config_file = "log_config"|
s|^\s*#\?\s*log_directory\s*=.*|log_directory = "log"|
s|^\s*#\?\s*network_boot_nodes\s*=.*|network_boot_nodes = \["/ip4/54.219.26.22/udp/1234/p2p/16Uiu2HAmPxGNWu9eVAQPJww79J32pTJLKGcpjRMb4Qb8xxKkyuG1","/ip4/52.52.127.117/udp/1234/p2p/16Uiu2HAm93Hd5azfhkGBbkx1zero3nYHvfjQYM2NtiW4R3r5bE2g","/ip4/18.167.69.68/udp/1234/p2p/16Uiu2HAm2k6ua2mGgvZ8rTMV8GhpW71aVzkQWy7D37TTDuLCpgmX","/ip4/54.219.26.22/udp/1234/p2p/16Uiu2HAmTVDGNhkHD98zDnJxQWu3i1FL1aFYeh9wiQTNu4pDCgps","/ip4/52.52.127.117/udp/1234/p2p/16Uiu2HAkzRjxK2gorngB1Xq84qDrT4hSVznYDHj6BkbaE4SGx9oS"\]|
s|^\s*#\?\s*log_contract_address\s*=.*|log_contract_address = "'"$LOG_CONTRACT_ADDRESS"'"|
s|^\s*#\?\s*mine_contract_address\s*=.*|mine_contract_address = "'"$MINE_CONTRACT_ADDRESS"'"|
s|^\s*#\?\s*log_sync_start_block_number\s*=.*|log_sync_start_block_number = '"$ZGS_LOG_SYNC_BLOCK"'|
s|^\s*#\?\s*blockchain_rpc_endpoint\s*=.*|blockchain_rpc_endpoint = "'"$BLOCKCHAIN_RPC_ENDPOINT"'"|
' $HOME/0g-storage-node/run/config.toml

# Save private key to config.toml
sed -i 's|^miner_key = ""|miner_key = "'"$PRIVATE_KEY"'"|' $HOME/0g-storage-node/run/config.toml

# 7. Create systemd service file
sudo tee /etc/systemd/system/zgs.service > /dev/null <<EOF
[Unit]
Description=ZGS Node
After=network.target

[Service]
User=$USER
WorkingDirectory=$HOME/0g-storage-node/run
ExecStart=$HOME/0g-storage-node/target/release/zgs_node --config $HOME/0g-storage-node/run/config.toml
Restart=on-failure
RestartSec=10
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# 8. Reload systemd and start the service
sudo systemctl daemon-reload
sudo systemctl enable zgs
sudo systemctl start zgs

# 9. Guide to check logs and set up automatic log deletion
echo -e "\n\033[32mSetup complete!\033[0m"
echo -e "\n\033[31mTo check logs, use the following command:\033[0m"
echo -e "tail -f \$HOME/0g-storage-node/run/log/zgs.log.\$(TZ=UTC date +%Y-%m-%d)\n"
echo -e "\033[31mTo set up log deletion every 10 minutes, add the following line to your crontab (use 'crontab -e' to edit):\033[0m"
echo -e "*/10 * * * * rm -rf \$HOME/0g-storage-node/run/log/*\n"                
                ;;
            "Remove Storage Node")
                echo "Removing Storage Node..."
sudo systemctl stop zgs
sudo systemctl disable zgs
sudo rm /etc/systemd/system/zgs.service
sudo systemctl daemon-reload
sudo systemctl reset-failed
rm -rf $HOME/0g-storage-node                               
                ;;
            "Back")
                echo "Going back to the previous menu..."
                main_menu
                return
                ;;
            "Quit")
                echo "Quitting..."
                exit 0
                ;;
            *) 
                echo "Invalid option $REPLY"
                ;;
        esac
    done
}

kv_menu() {
    PS3='Please enter your choice: '
    options=("Install" "Quit")
    select opt in "${options[@]}"
    do
        case $opt in
           "Install")
                echo "Comming Soon. Going back to the previous menu..."
                main_menu
                return
                ;;           
            "Quit")
                echo "Quitting..."
                exit 0
                ;;
            *) 
                echo "Invalid option $REPLY"
                ;;
        esac
    done
}

da_menu() {
    PS3='Please enter your choice: '
    options=("Install" "Quit")
    select opt in "${options[@]}"
    do
        case $opt in
            "Install")
                echo "Comming Soon. Going back to the previous menu..."
                main_menu
                return
                ;;             
            "Quit")
                echo "Quitting..."
                exit 0
                ;;
            *) 
                echo "Invalid option $REPLY"
                ;;
        esac
    done
}

main_menu
