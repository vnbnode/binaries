#!/bin/bash

# Display logo
curl -s https://raw.githubusercontent.com/vnbnode/binaries/main/Logo/logo.sh | bash

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

# 2. Install Go
wget https://go.dev/dl/go1.22.0.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.22.0.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

# 3. Install Rust
export RUSTUP_INIT_SKIP_PATH_CHECK=yes
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env

# 4. Git clone the 0g storage node repository
git clone -b v0.3.2 https://github.com/0glabs/0g-storage-node.git
cd $HOME/0g-storage-node
git fetch
git checkout tags/v0.3.2
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
s|^\s*#\?\s*network_boot_nodes\s*=.*|network_boot_nodes = \["/ip4/54.219.26.22/udp/1234/p2p/16Uiu2HAmTVDGNhkHD98zDnJxQWu3i1FL1aFYeh9wiQTNu4pDCgps","/ip4/52.52.127.117/udp/1234/p2p/16Uiu2HAkzRjxK2gorngB1Xq84qDrT4hSVznYDHj6BkbaE4SGx9oS"\]|
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
