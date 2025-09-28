#!/bin/bash

set -e

exists() {
  command -v "$1" >/dev/null 2>&1
}

# Cài curl nếu chưa có
if ! exists curl; then
  apt update && apt install -y curl
fi

# Hiển thị logo
echo -e "\033[0;35m"
echo " ============================================================================"
echo "||░██═╗░░░░░░░██╗░███╗░░██╗░███████═╗░░███╗░░██╗ █████╗░██████═╗░░░███████╗░||"
echo "||░░██╚╗░░░░░██╔╝░████╗░██║░██╔══███╝░░████╗░██║██╔══██╗██╔══ ██╚╗░██╔════╝░||"
echo "||░░░██╚╗░░░██╔╝░░██╔██╗██║░██████╔╝░░░██╔██╗██║██║░░██║██║░░░░██║░█████╗░░░||"
echo "||░░░░██╚╗░██╔╝░░░██║╚████║ ██╔══███╗░░██║╚████║██║░░██║██╚══ ██╔╝░██╔══╝░░░||"
echo "||░░░░░█████╔╝░░░░██║░╚███║ ███████ ║░░██║░╚███║╚█████╔╝██████░║░░░███████╗░||"
echo "||░░░░░░╚═══╝░░░░░╚═╝░░╚══╝░╚══════╝░░░╚═╝░░╚══╝░╚════╝░╚══════╝░░░╚══════╝░||"
echo " ============================================================================"
echo -e "\e[0m"
sleep 1

# Cài các gói cần thiết cho Docker
echo -e "\e[1m\e[32m1. Cài đặt gói cần thiết cho Docker... \e[0m" && sleep 1
apt update
apt install -y ca-certificates curl gnupg lsb-release

# Gỡ docker cũ nếu có
if dpkg -l | grep -qw docker; then
  echo -e "\e[1m\e[32m2. Gỡ bỏ Docker cũ... \e[0m" && sleep 1
  apt remove -y docker docker-engine docker.io containerd runc
fi

# Thêm kho Docker và khóa GPG
echo -e "\e[1m\e[32m3. Thêm kho Docker và khóa GPG... \e[0m" && sleep 1
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Cài Docker Engine và Docker Compose plugin
echo -e "\e[1m\e[32m4. Cài đặt Docker... \e[0m" && sleep 1
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo -e "\e[1m\e[32m✅ Docker đã được cài đặt thành công trên Debian 12! \e[0m"
