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

# Set Validator name
read -r -p "Enter node moniker: " MONIKER
sleep 1

# Download CometBFT
mkdir -p $HOME/.local/bin
curl -sL https://github.com/cometbft/cometbft/releases/download/v0.37.2/cometbft_0.37.2_linux_amd64.tar.gz | tar -C $HOME/.local/bin -xzf- cometbft && sleep 1

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"  && sleep 1

# Update system and install build tools
sudo apt -q update
sudo apt -qy install make git-core libssl-dev pkg-config libclang-12-dev libudev-dev build-essential protobuf-compiler
sudo apt -qy upgrade
sleep 1

# Build Namada

Explain
cd $HOME
rm -rf public-testnet-15.0dacadb8d663
git clone -b v0.28.1 https://github.com/anoma/namada.git public-testnet-15.0dacadb8d663
cd public-testnet-15.0dacadb8d663
make build-release
for BIN in namada namadac namadan namadar namadaw; do install -m 0755 target/release/$BIN $HOME/.local/bin/$BIN; done
sleep 1

# Create SystemD service unit

Explain
sudo tee /etc/systemd/system/namada.service > /dev/null << EOF
[Unit]
Description=Namada node
After=network-online.target

[Service]
User=$USER
ExecStart=$HOME/.local/bin/namada node ledger run
Restart=always
RestartSec=10
LimitNOFILE=65535
Environment="CMT_LOG_LEVEL=p2p:none,pex:error"
Environment="NAMADA_CMT_STDOUT=true"
Environment="NAMADA_LOG=info"
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:$HOME/.local/bin"

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable namada.service

# Initialize the node

export PATH=$HOME/.local/bin:$PATH
namada client utils join-network --chain-id public-testnet-15.0dacadb8d663

export CUSTOM_PORT=266
sed -i \
  -e "s|^proxy_app = \"tcp://127.0.0.1:26658\"|proxy_app = \"tcp://127.0.0.1:${CUSTOM_PORT}58\"|" \
  -e "s|^laddr = \"tcp://127.0.0.1:26657\"|laddr = \"tcp://127.0.0.1:${CUSTOM_PORT}57\"|" \
  -e "s|^laddr = \"tcp://0.0.0.0:26656\"|laddr = \"tcp://0.0.0.0:${CUSTOM_PORT}56\"|" \
  -e "s|^prometheus_listen_addr = \":26660\"|prometheus_listen_addr = \":${CUSTOM_PORT}66\"|" \
  $HOME/.local/share/namada/public-testnet-15.0dacadb8d663/config.toml
sleep 1

# Start service
sudo systemctl start namada.service
# Logo
sleep 1 && curl -s https://raw.githubusercontent.com/vnbnode/binaries/main/Logo/logo.sh | bash && sleep 1
echo '============================================== SETUP FINISHED ====================================================='
echo -e "\e[1;32mCheck logs: \e[0m\e[1;36m${CYAN} sudo journalctl -u namada.service -f --no-hostname -o cat ${NC}\e[0m"
echo -e "\e[1;32mCheck synchronization: \e[0m\e[1;36m${CYAN} namada  status 2>&1 | jq .SyncInfo ${NC}\e[0m"
echo -e "\e[1;32mCreate Wallet: \e[0m\e[1;36m${CYAN} namada wallet key gen --hd-path default --alias wallet ${NC}\e[0m"
echo -e "\e[1;32mRecover Wallet: \e[0m\e[1;36m${CYAN} namada wallet key restore --hd-path default --alias wallet ${NC}\e[0m"
echo -e "\e[1;32mMore commands: \e[0m\e[1;36m${CYAN}$GITHUB${NC}\e[0m"
echo '============================================== SETUP FINISHED ====================================================='
