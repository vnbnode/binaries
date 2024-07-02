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

cd $HOME && source <(curl -s https://raw.githubusercontent.com/vnbnode/binaries/main/update-binary.sh)

sleep 1

# Set Var
read -r -p "Enter node moniker: " MONIKER
echo 'export MONIKER='$MONIKER >> $HOME/.bash_profile
sleep 1

source $HOME/.bash_profile
echo 'export CHAIN_ID="zgtendermint_16600-1"' >> ~/.bash_profile
echo 'export WALLET_NAME="wallet"' >> ~/.bash_profile
echo 'export RPC_PORT="10157"' >> ~/.bash_profile
source $HOME/.bash_profile
echo '================================================='
echo -e "Your Node Name Is: \e[1m\e[32m$MONIKER\e[0m"
echo '================================================='
sleep 2

# Build binary
sleep 1

git clone -b v0.2.3 https://github.com/0glabs/0g-chain.git
cd 0g-chain
make install
0gchaind version
cd $HOME
sleep 1

# Service Setup

sudo tee /etc/systemd/system/0g.service > /dev/null <<EOF
[Unit]
Description=0G Node
After=network.target

[Service]
User=$USER
Type=simple
ExecStart=$(which 0gchaind) start --home $HOME/.0gchain
Restart=on-failure
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

sleep 1

# initiate Node
cd $HOME
0gchaind init $MONIKER --chain-id $CHAIN_ID
0gchaind config chain-id $CHAIN_ID
0gchaind config keyring-backend os

sleep 1
# Download Genesis & Addrbook
rm $HOME/.0gchain/config/genesis.json
wget https://github.com/0glabs/0g-chain/releases/download/v0.2.3/genesis.json -O $HOME/.0gchain/config/genesis.json
sleep 1

# Configure
seeds=$(curl -s https://raw.githubusercontent.com/vnbnode/binaries/main/Projects/0g/seeds.txt)
sed -i.bak -e "s/^seeds *=.*/seeds = \"$seeds\"/" $HOME/.0gchain/config/config.toml
sleep 1
peers=$(curl -s https://raw.githubusercontent.com/vnbnode/binaries/main/Projects/0g/peers.txt)
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" $HOME/.0gchain/config/config.toml
sed -i.bak -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.0gchain/config/app.toml
sed -i.bak -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.0gchain/config/app.toml
sed -i.bak -e "s/^pruning-interval *=.*/pruning-interval = \"10\"/" $HOME/.0gchain/config/app.toml
sed -i "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0ua0gi\"/" $HOME/.0gchain/config/app.toml
sed -i "s/^indexer *=.*/indexer = \"kv\"/" $HOME/.0gchain/config/config.toml
sleep 1

# Custom Port

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
  sleep 1

# Start Node
sudo systemctl daemon-reload
sudo systemctl enable 0g
sudo systemctl restart 0g
sleep 2

echo '====================== SETUP FINISHED =============================================================='
echo 'echo -e "\e[1;32mCheck logs: \e[0m\e[1;36m${YELLOW} sudo journalctl -u 0gd -f -o cat \e[0m"
echo '====================================================================================================='
sleep 2
