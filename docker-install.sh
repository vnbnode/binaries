#!/bin/bash

exists() {
  command -v "$1" >/dev/null 2>&1
}

# Cài curl nếu chưa có
if ! exists curl; then
  sudo apt update && sudo apt install curl -y < "/dev/null"
fi

# Hiển thị logo
sleep 1 && curl -s https://raw.githubusercontent.com/vnbnode/binaries/main/Logo/logo.sh | bash && sleep 3

# Cập nhật hệ thống
cd $HOME
echo -e "\e[1m\e[32m1. Cập nhật hệ thống... \e[0m" && sleep 1
sudo apt update && sudo apt upgrade -y

# Cài các gói cần thiết
echo -e "\e[1m\e[32m2. Cài đặt package cần thiết... \e[0m" && sleep 1
sudo apt install -y \
  curl tar wget clang pkg-config protobuf-compiler libssl-dev \
  jq build-essential bsdmainutils git make ncdu gcc chrony lz4 \
  tmux unzip bc snapd liblz4-tool

# Gỡ docker cũ nếu có
if dpkg -l | grep -qw docker; then
  echo -e "\e[1m\e[32m3. Gỡ bỏ Docker cũ... \e[0m" && sleep 1
  sudo apt-get remove -y docker docker-engine docker.io containerd runc
fi

# Cài Docker
echo -e "\e[1m\e[32m4. Cài đặt Docker... \e[0m" && sleep 1
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg

# Thêm kho Docker và khóa GPG
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Cài Docker Engine và Docker Compose plugin
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo -e "\e[1m\e[32m✅ Cài đặt hoàn tất! \e[0m" && sleep 1
