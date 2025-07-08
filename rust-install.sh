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
# ================== LOGO ==================
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

# Update
cd $HOME
echo -e "\e[1m\e[32m1. Update... \e[0m" && sleep 1
sudo apt update && sudo apt upgrade -y
sleep 1

# Install
sudo apt-get update
sudo apt install build-essential
sudo apt install --assume-yes git clang curl libssl-dev protobuf-compiler
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env
rustup default stable
rustup update
rustup update nightly
rustup target add wasm32-unknown-unknown --toolchain nightly

echo -e "\e[1m\e[32mFINISH \e[0m" && sleep 1
