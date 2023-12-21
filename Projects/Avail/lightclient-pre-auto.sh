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
echo '================ SETUP FOR AVAIL LIGHT CLIENT VERSION 1.7.4 BY VNBNODE ==============='&& sleep 1
# Upgrade
sudo apt update
sudo apt install make clang pkg-config libssl-dev build-essential

# Download & run binaries
mkdir -p ${HOME}/avail-light
cd avail-light

sleep 1 && curl -s https://raw.githubusercontent.com/vnbnode/binaries/main/Logo/logo.sh | bash && sleep 1
echo '================ SETUP FOR AVAIL LIGHT CLIENT VERSION 1.7.4 BY VNBNODE ==============='&& sleep 1
wget https://github.com/availproject/avail-light/releases/download/v1.7.4/avail-light-linux-amd64.tar.gz
tar -xvzf avail-light-linux-amd64.tar.gz
cp avail-light-linux-amd64 avail-light

tee /etc/systemd/system/availd.service > /dev/null << EOF
[Unit]
Description=Avail Light Client
After=network.target
StartLimitIntervalSec=0
[Service] 
User=root 
ExecStart=/root/avail-light/avail-light --network goldberg
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
echo '============================= THANK YOU FOR SUPPORT VNBnode ==================================='
