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

# Update
echo -e "\e[1m\e[32m1. Update... \e[0m" && sleep 1
sudo apt update && sudo apt upgrade -y
sleep 1

# Package
echo -e "\e[1m\e[32m2. Installing package... \e[0m" && sleep 1
sudo apt install curl tar wget clang pkg-config protobuf-compiler libssl-dev jq build-essential protobuf-compiler bsdmainutils git make ncdu gcc git jq chrony liblz4-tool -y
sleep 1

# Install Docker
echo -e "\e[1m\e[32m3. Installing docker... \e[0m" && sleep 1
sudo apt-get update
sudo apt-get install \
ca-certificates \
curl \
gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
"deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
"$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sleep 1

# Fill data
echo -e "\e[1m\e[32m4. Fill data... \e[0m" && sleep 1

## DIR_PATH
if [ ! $moniker_union ]; then
    read -p "MONIKER: " moniker_union
    echo 'export moniker_union='\"${moniker_union}\" >> $HOME/.bash_profile
fi
echo 'source $HOME/.bashrc' >> $HOME/.bash_profile
source $HOME/.bash_profile
sleep 1

# Export Binary
echo -e "\e[1m\e[32m5. Export Binary... \e[0m" && sleep 1
export CHAIN_ID=union-testnet-4
export MONIKER="$moniker_union"
export KEY_NAME=union
export GENESIS_URL="https://rpc.cryptware.io/genesis"
export UNIOND_VERSION='v0.14.0'

# Download Docker Image
echo -e "\e[1m\e[32m6. Download Docker Image... \e[0m" && sleep 1
docker pull ghcr.io/unionlabs/uniond:$UNIOND_VERSION
sleep 1

# Initializing the Chain Config & State Folder
echo -e "\e[1m\e[32m7. Initializing the Chain Config & State Folder... \e[0m" && sleep 1
cd $HOME
mkdir ~/.union
curl https://rpc.cryptware.io/genesis | jq '.result.genesis' > ~/.union/config/genesis.json
docker run -u $(id -u):$(id -g) -v ~/.union:/.union -it ghcr.io/unionlabs/uniond:$UNIOND_VERSION init $MONIKER bn254 --home /.union
alias uniond='docker run -v ~/.union:/.union --network host -it ghcr.io/unionlabs/uniond:$UNIOND_VERSION --home /.union'

# SEEDS
SEEDS="a069a341154484298156a56ace42b6e6a71e7b9d@blazingbit.io:27656,8a07752a234bb16471dbb577180de7805ba6b5d9@union.testnet.4.seed.poisonphang.com:26656"
sleep 1
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/" $HOME/.union/config/config.toml

# Run Node Uniond
echo -e "\e[1m\e[32m8. Run Node Uniond... \e[0m" && sleep 1
cd $HOME
cd ~/.union
curl -o compose.yaml https://raw.githubusercontent.com/vnbnode/binaries/main/Projects/Union/compose.yaml
docker compose up -d

# NAMES=`docker ps | egrep 'sarvalabs/moipod' | awk '{print $18}'`
cd $HOME
rm $HOME/union-auto.sh

# Command check
echo '====================== SETUP FINISHED ======================'
echo -e "\e[1;32mView the logs from the running: \e[0m\e[1;36msudo docker logs -f union-node\e[0m"
echo -e "\e[1;32mCheck the list of containers: \e[0m\e[1;36msudo docker ps -a\e[0m"
echo -e "\e[1;32mStart your node: \e[0m\e[1;36msudo docker start union-node\e[0m"
echo -e "\e[1;32mRestart your node: \e[0m\e[1;36msudo docker restart union-node\e[0m"
echo -e "\e[1;32mStop your node: \e[0m\e[1;36msudo docker stop union-node\e[0m"
echo -e "\e[1;32mRemove: \e[0m\e[1;36msudo docker rm union-node\e[0m"
echo '============================================================='
