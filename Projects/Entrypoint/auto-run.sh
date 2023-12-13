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
read -r -p "Enter node moniker: " NODE_MONIKER

CHAIN_ID="entrypoint-pubtest-2"
CHAIN_DENOM="uentry"
BINARY_NAME="entrypointd"
GITHUB="https://github.com/vnbnode/VNBnode-Guides"
BINARY_VERSION_TAG="v1.3.0"

echo -e "Node Name: ${CYAN}$NODE_MONIKER${NC}"
echo -e "Chain id:     ${CYAN}$CHAIN_ID${NC}"
echo -e "Chain demon:  ${CYAN}$CHAIN_DENOM${NC}"
echo -e "Binary version tag:  ${CYAN}$BINARY_VERSION_TAG${NC}"

sleep 1

#UPDATE APT
echo -e "\e[1m\e[32m1. Updating packages and dependencies--> \e[0m" && sleep 1
sudo apt update && sudo apt upgrade -y
sudo apt install curl tar wget clang pkg-config libssl-dev libleveldb-dev jq build-essential bsdmainutils git make ncdu htop lz4 screen unzip bc fail2ban htop -y

#INSTALL GO
echo -e "\e[1m\e[32m2. Installing GO--> \e[0m" && sleep 1
ver="1.20.5" 
cd $HOME 
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz" 

sudo rm -rf /usr/local/go 
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz" 
rm "go$ver.linux-amd64.tar.gz"

echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile

echo -e "\e[1m\e[32m3. Downloading and building binaries--> \e[0m" && sleep 1

cd $HOME
wget -O entrypointd https://github.com/entrypoint-zone/testnets/releases/download/v1.3.0/entrypointd-1.3.0-linux-amd64
chmod +x entrypointd
sudo mv entrypointd /usr/local/bin
entrypointd version

entrypointd config chain-id $CHAIN_ID
entrypointd config keyring-backend test
entrypointd init "$NODE_MONIKER" --chain-id $CHAIN_ID

# Add Genesis File and Addrbook
wget -O $HOME/.entrypoint/config/genesis.json https://testnet-files.itrocket.net/entrypoint/genesis.json
wget -O $HOME/.entrypoint/config/addrbook.json https://testnet-files.itrocket.net/entrypoint/addrbook.json

#Configure Seeds and Peers
SEEDS="e1b2eddac829b1006eb6e2ddbfc9199f212e505f@entrypoint-testnet-seed.itrocket.net:34656"
PEERS="7048ee28300ffa81103cd24b2af3d1af0c378def@entrypoint-testnet-peer.itrocket.net:34656,e0bf0782c0fc1ee550d2eed0de66b0b1825776ab@167.235.39.5:46656,05419a6f8cc137c4bb2d717ed6c33590aaae022d@213.133.100.172:26878,b17f3f6a57a42081749c8f580af3567b5646f0bf@[2406:da1e:df4:c801:688:ec9c:886:99c9]:26646,d57c7572d58cb3043770f2c0ba412b35035233ad@80.64.208.169:26656,432963f1d61d0d32c9286248c4b5cfe1d89f7541@49.12.123.87:22226,75e83d67504cbfacdc79da55ca46e2c4353816e7@65.109.92.241:3106,6e38397e09a2755841e2f350ba1ff8883a66551a@[2a01:4f9:4a:2864::2]:11556,2418cc16fb1ee6218c01f07571afde0909d6e777@65.109.113.228:61056,f94f05a942b987e71a92cd634915c241f58eac7c@65.109.68.87:29656,fcdd0c5810ac038cb02c806a837296eab334959b@176.103.222.85:26656"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.entrypoint/config/config.toml

# Set Pruning, Enable Prometheus, Gas Prices, and Indexer
PRUNING="custom"
PRUNING_KEEP_RECENT="100"
PRUNING_INTERVAL="10"

sed -i -e "s/^pruning *=.*/pruning = \"$PRUNING\"/" $HOME/.entrypoint/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \
\"$PRUNING_KEEP_RECENT\"/" $HOME/.entrypoint/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \
\"$PRUNING_INTERVAL\"/" $HOME/.entrypoint/config/app.toml
sed -i -e 's|^indexer *=.*|indexer = "null"|' $HOME/.entrypoint/config/config.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.entrypoint/config/config.toml
sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0.01ibc/8A138BC76D0FB2665F8937EC2BF01B9F6A714F6127221A0E155106A45E09BCC5\"|" $HOME/.entrypoint/config/app.toml

# Set Service file
sudo tee /etc/systemd/system/entrypointd.service > /dev/null <<EOF
[Unit]
Description=entrypointd testnet node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which entrypointd) start
Restart=always
RestartSec=3
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable entrypointd 
sleep 1
# Download Snapshot for fast sync
rm -rf $HOME/.entrypoint/data $HOME/.entrypoint/wasmPath
entrypointd tendermint unsafe-reset-all --home $HOME/.entrypoint
if curl -s --head curl https://testnet-files.itrocket.net/entrypoint/snap_entrypoint.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://testnet-files.itrocket.net/entrypoint/snap_entrypoint.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.entrypoint
    else
  echo no have snap
fi
sleep 1
# Start the Node
sudo systemctl restart entrypointd

echo '====================== SETUP FINISHED ======================'
echo -e "\e[1;32mCheck logs: \e[0m\e[1;36m${CYAN}sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat ${NC}\e[0m"
echo -e "\e[1;32mCheck synchronization: \e[0m\e[1;36m${CYAN}$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up${NC}\e[0m"
echo -e "\e[1;32mMore commands: \e[0m\e[1;36m${CYAN}$GITHUB${NC}\e[0m"
echo '============================================================='
