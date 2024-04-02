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
echo '================ SETUP FOR AVAIL LIGHT CLIENT VERSION 1.7.9 BY VNBNODE ==============='&& sleep 1

# Update & Install Rust
sudo apt-get update
sudo apt install build-essential
sudo apt install --assume-yes git clang curl libssl-dev protobuf-compiler
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env
rustup default stable
rustup update
rustup update nightly
rustup target add wasm32-unknown-unknown --toolchain nightly

# Download and run  Avail Light Client
git clone https://github.com/availproject/avail-light.git
cd avail-light
git checkout v1.7.9
cargo build --release

# Setup service file
tee /etc/systemd/system/availd.service > /dev/null << EOF
[Unit]
Description=Avail Light Client
After=network.target
StartLimitIntervalSec=0
[Service] 
User=root 
ExecStart= /root/avail-light/target/release/avail-light --network goldberg
Restart=always 
RestartSec=120
[Install] 
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable availd
systemctl start availd.service

# Logo
sleep 1 && curl -s https://raw.githubusercontent.com/vnbnode/binaries/main/Logo/logo.sh | bash && sleep 1
echo '====================================== SETUP FINISHED ========================================='
echo -e "\e[1;32m Check status: \e[0m\e[1;36m${CYAN} systemctl status availd.service ${NC}\e[0m"
echo -e "\e[1;32m Check logs  : \e[0m\e[1;36m${CYAN} journalctl -f -u availd ${NC}\e[0m"
echo '===================================== SETUP FINISHED =========================================='
