#!/bin/bash
exists()
{
  command -v "$1" >/dev/null 2>&1
}
# Check if 'curl' is installed
if exists curl; then
  echo ""
else
  echo "Installing curl..."
  if ! sudo apt update && sudo apt install curl -y < "/dev/null"; then
    echo "Failed to install curl. Exiting."
    exit 1
  fi
fi
bash_profile=$HOME/.bash_profile
if [ -f "$bash_profile" ]; then
    source $HOME/.bash_profile
fi
sleep 1 && curl -s https://raw.githubusercontent.com/vnbnode/binaries/main/Logo/logo.sh | bash && sleep 1

cd $HOME
sudo install -m 0755 -d /etc/apt/keyrings
sudo rm -f /etc/apt/keyrings/docker.gpg
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

sudo docker --version
sudo docker pull nillion/verifier:v1.0.1

mkdir -p $HOME/nillion/accuser
docker run -v ./nillion/verifier:/var/tmp nillion/verifier:v1.0.1 initialise
