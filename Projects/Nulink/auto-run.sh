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

# Generate Geth Account
wget https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-1.10.23-d901d853.tar.gz

tar -xvzf geth-linux-amd64-1.10.23-d901d853.tar.gz

cd geth-linux-amd64-1.10.23-d901d853/

./geth account new --keystore ./keystore
sleep 5
echo -e "\e[1;32m \e[0m\e[1;36m${CYAN} SAVE YOUR ADDRESS AND PASSWORDS ${NC}\e[0m"
echo -e "\e[1;32m \e[0m\e[1;36m${CYAN} SAVE YOUR PRIVATE KEY AND PATH ${NC}\e[0m"
sleep 5

# Install docker

sudo apt-get update
sudo apt-get install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Pull the latest NuLink image

docker pull nulink/nulink:latest
cd /root
mkdir nulink
cp /root/geth-linux-amd64-1.10.23-d901d853/keystore/* /root/nulink
chmod -R 777 /root/nulink

apt install python3-pip
pip install virtualenv
virtualenv /root/nulink-venv
source /root/nulink-venv/bin/activate
wget https://download.nulink.org/release/core/nulink-0.5.0-py3-none-any.whl
pip install nulink-0.5.0-py3-none-any.whl
pip install --upgrade pip
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
pip install nulink-0.5.0-py3-none-any.whl
source /root/nulink-venv/bin/activate

# Verify again
source /root/nulink-venv/bin/activate
python -c "import nulink"
nulink --help

# Initiate Worker
read -r -p "NULINK_KEYSTORE_PASSWORD : " NULINK_KEYSTORE_PASSWORD
sleep 0.5
read -r -p "NULINK_OPERATOR_ETH_PASSWORD : " NULINK_OPERATOR_ETH_PASSWORD
sleep 0.5
echo -e "\e[1;32m \e[0m\e[1;36m${CYAN} YOUR KEYSTORE ${NC}\e[0m"
filename=$(basename ~/geth-linux-amd64-1.10.23-d901d853/keystore/*)
export filename1=$filename
sleep 1
echo -e "\e[1;32m \e[0m\e[1;36m${CYAN} COPY YOUR KEYSTORE ${NC}\e[0m"
evm=$(grep -oP '(?<="address":")[^"]+' ~/geth-linux-amd64-1.10.23-d901d853/keystore/*)
wallet='0x'$evm
export wallet1=$wallet
sleep 1

# Initialize Node Configuration

docker run -it --rm \
-p 9151:9151 \
-v /root/nulink:/code \
-v /root/nulink:/home/circleci/.local/share/nulink \
-e NULINK_KEYSTORE_PASSWORD \
nulink/nulink nulink ursula init \
--signer keystore:///code/$filename1 \
--eth-provider https://data-seed-prebsc-2-s2.binance.org:8545 \
--network horus \
--payment-provider https://data-seed-prebsc-2-s2.binance.org:8545 \
--payment-network bsc_testnet \
--operator-address $wallet1 \
--max-gas-price 10000000000

#Launch the Node

docker run --restart on-failure -d \
--name ursula \
-p 9151:9151 \
-v /root/nulink:/code \
-v /root/nulink:/home/circleci/.local/share/nulink \
-e NULINK_KEYSTORE_PASSWORD \
-e NULINK_OPERATOR_ETH_PASSWORD \
nulink/nulink nulink ursula run --no-block-until-ready

# Logo
sleep 1 && curl -s https://raw.githubusercontent.com/vnbnode/binaries/main/Logo/logo.sh | bash && sleep 1
echo '=============================== SETUP FINISHED ==============================='
echo -e "\e[1;32m Start node: \e[0m\e[1;36m${CYAN} docker restart ursula ${NC}\e[0m"
echo -e "\e[1;32m Check logs  : \e[0m\e[1;36m${CYAN} docker logs -f ursula ${NC}\e[0m"
echo '======================== THANK FOR SUPPORT VNBnode ==========================='
