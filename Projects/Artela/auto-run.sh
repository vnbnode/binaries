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
sleep 0.5
export NODE_MONIKER=$NODE_MONIKER

apt update && apt upgrade -y
sleep 0.5
apt install curl iptables build-essential git wget jq make gcc nano tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev -y
sleep 0.5

#INSTALL GO
ver="1.20.3"
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
rm "go$ver.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile
go version
sleep 1

#Install all Binaries
cd $HOME
rm -rf artela
git clone https://github.com/artela-network/artela
sleep 0.5
cd artela
git checkout v0.4.7-rc4
make install
sleep 0.5

artelad config chain-id artela_11822-1
artelad init "$NODE_MONIKER" --chain-id artela_11822-1
sleep 0.5

curl -s https://t-ss.nodeist.net/artela/genesis.json > $HOME/.artelad/config/genesis.json
curl -s https://t-ss.nodeist.net/artela/addrbook.json > $HOME/.artelad/config/addrbook.json
sleep 0.5

SEEDS=""
PEERS="b23bc610c374fd071c20ce4a2349bf91b8fbd7db@65.108.72.233:11656"
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.artelad/config/config.toml

sed -i 's|^pruning *=.*|pruning = "custom"|g' $HOME/.artelad/config/app.toml
sed -i 's|^pruning-keep-recent  *=.*|pruning-keep-recent = "100"|g' $HOME/.artelad/config/app.toml
sed -i 's|^pruning-interval *=.*|pruning-interval = "10"|g' $HOME/.artelad/config/app.toml
sed -i 's|^snapshot-interval *=.*|snapshot-interval = 0|g' $HOME/.artelad/config/app.toml

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.025art"|g' $HOME/.artelad/config/app.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.artelad/config/config.toml
sleep 0.5

#Create service file
tee /etc/systemd/system/artelad.service > /dev/null << EOF
[Unit]
Description=artela node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which artelad) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF
sleep 0.5

artelad tendermint unsafe-reset-all --home $HOME/.artelad --keep-addr-book
sleep 0.5
apt install snapd
snap install lz4
sleep 0.5

curl -L https://t-ss.nodeist.net/artela/snapshot_latest.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.artelad --strip-components 2
sleep 1

sudo systemctl daemon-reload
sudo systemctl enable artelad
sudo systemctl start artelad
sleep 1

# Logo
sleep 1 && curl -s https://raw.githubusercontent.com/vnbnode/binaries/main/Logo/logo.sh | bash && sleep 1
echo '====================== SETUP FINISHED ========================================='
echo 'echo -e "\e[1;32m Check status: \e[0m\e[1;36m${CYAN} sudo systemctl status artelad ${NC}\e[0m"
echo -e "\e[1;32m Check logs: \e[0m\e[1;36m${CYAN} sudo journalctl -fu artelad -o cat ${NC}\e[0m"
echo -e "\e[1;32m Check synchronization: \e[0m\e[1;36m${CYAN} artelad status | jq .SyncInfo.catching_up ${NC}\e[0m"
echo '======================== THANK FOR SUPPORT VNBnode ==========================='
