#!/bin/bash

# auto.sh - Automated installation and configuration of Pactus Node

set -e

# ============================
# Get Inputs from User at the Start
# ============================

# Prompt user for wallet password
read -s -p "Enter your Pactus wallet password: " PACTUS_PASSWORD
echo

# Prompt user for the number of validators to create
read -p "How many validators do you want to create (up to 32)? " NUM_VALIDATORS

# Validate that the input is a number and within the valid range (1-32)
if ! [[ "$NUM_VALIDATORS" =~ ^[0-9]+$ ]] || [ "$NUM_VALIDATORS" -lt 1 ] || [ "$NUM_VALIDATORS" -gt 32 ]; then
    echo "Invalid number of validators. Please enter a number between 1 and 32."
    exit 1
fi

# Choose action: init or restore
echo "Choose an action:"
echo "1. Initialize a new wallet"
echo "2. Restore wallet from seed phrase"
read -p "Enter your choice [1/2]: " ACTION_CHOICE

if [[ "$ACTION_CHOICE" == "1" ]]; then
    ACTION="init"
elif [[ "$ACTION_CHOICE" == "2" ]]; then
    ACTION="restore"
else
    echo "Invalid choice. Exiting script."
    exit 1
fi

# If restore, prompt for seed phrase
if [[ "$ACTION" == "restore" ]]; then
    read -p "Enter your seed phrase: " SEED_PHRASE
    if [[ -z "$SEED_PHRASE" ]]; then
        echo "Seed phrase cannot be empty. Exiting script."
        exit 1
    fi
fi

# ============================
# Helper Functions
# ============================
echo_info() {
    echo -e "\e[32m[INFO]\e[0m $1"
}

echo_warn() {
    echo -e "\e[33m[WARN]\e[0m $1"
}

echo_error() {
    echo -e "\e[31m[ERROR]\e[0m $1"
}

# ============================
# Check for Root Privileges
# ============================
if [[ "$EUID" -ne 0 ]]; then
   echo_error "Please run this script as root or use sudo."
   exit 1
fi

# ============================
# Step 1: Update System and Install Build Tools
# ============================
# Logo
sleep 1 && curl -s https://raw.githubusercontent.com/vnbnode/binaries/main/Logo/logo.sh | bash && sleep 1
echo_info "Updating system and installing build tools..."
apt update && apt list --upgradable && apt upgrade -y

# ============================
# Step 2: Install Additional Packages
# ============================
echo_info "Installing additional packages..."
apt install -y curl tar wget clang pkg-config libssl-dev jq build-essential git make ncdu net-tools expect

# ============================
# Step 3: Install Go
# ============================
echo_info "Installing Go..."
rm -rf /usr/local/go
GO_VERSION="1.22.2"
wget "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -O /tmp/go${GO_VERSION}.linux-amd64.tar.gz
tar -xzf /tmp/go${GO_VERSION}.linux-amd64.tar.gz -C /usr/local
rm /tmp/go${GO_VERSION}.linux-amd64.tar.gz

# Configure PATH for Go
echo_info "Configuring PATH for Go..."
echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/golang.sh
chmod +x /etc/profile.d/golang.sh
source /etc/profile.d/golang.sh
echo 'export PATH=$PATH:$HOME/go/bin' >> $HOME/.profile
source $HOME/.profile

# Verify Go Installation
if ! command -v go &> /dev/null
then
    echo_error "Go was not installed correctly."
    exit 1
fi
echo_info "Go has been installed: $(go version)"

# ============================
# Step 4: Install and Build Pactus Binary
# ============================
echo_info "Cloning Pactus repository and building binaries..."
cd $HOME
git clone https://github.com/pactus-project/pactus.git .pactus
cd .pactus
make build

# Copy binaries to /usr/local/bin/
cp $HOME/.pactus/build/pactus-daemon /usr/local/bin/
cp $HOME/.pactus/build/pactus-wallet /usr/local/bin/

# Verify Pactus Daemon Installation
if ! command -v pactus-daemon &> /dev/null
then
    echo_error "Pactus-daemon was not installed correctly."
    exit 1
fi
echo_info "Pactus-daemon has been installed: $(pactus-daemon version)"

# ============================
# Step 5: Initialize or Restore Wallet
# ============================

echo_info "Setting up Pactus wallet..."

# Function to initialize wallet
initialize_wallet() {
    expect <<EOF
    spawn pactus-daemon init
    expect "Do you want to continue?"
    sleep 1
    send "y\r"
    expect "Enter a password for wallet"
    sleep 1
    send "$PACTUS_PASSWORD\r"
    expect "Confirm the password"
    sleep 1
    send "$PACTUS_PASSWORD\r"
    expect "How many validators do you want to create?"
    sleep 1
    send "$NUM_VALIDATORS\r"
    expect eof
EOF
}

# Function to restore wallet
restore_wallet() {
    expect <<EOF
    spawn pactus-daemon init --restore "$SEED_PHRASE"
    
    expect "Enter a password for wallet"
    sleep 1
    send "$PACTUS_PASSWORD\r"
    
    expect "Confirm password"
    sleep 1
    send "$PACTUS_PASSWORD\r"
   
    expect "How many validators do you want to create?"
    sleep 1
    send "$NUM_VALIDATORS\r"
    
    expect eof
EOF
}


# Execute initialization or restoration
if [[ "$ACTION" == "init" ]]; then
    echo_info "Initializing a new wallet with $NUM_VALIDATORS validators..."
    initialize_wallet
    echo_info "New wallet has been initialized successfully."
elif [[ "$ACTION" == "restore" ]]; then
    echo_info "Restoring wallet from seed phrase..."
    restore_wallet
    echo_info "Wallet has been restored successfully."
fi

# ============================
# Step 6: Create and Start Systemd Service
# ============================

echo_info "Creating and starting Pactus systemd service..."

# Create systemd service file
tee /etc/systemd/system/pactus.service > /dev/null << EOF
[Unit]
Description=Pactus Node
After=network-online.target
StartLimitIntervalSec=0

[Service]
User=root
ExecStart=/usr/local/bin/pactus-daemon start -w /root/pactus --password "$PACTUS_PASSWORD"
Restart=always
RestartSec=120

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start the Pactus service
systemctl daemon-reload
systemctl enable pactus
systemctl restart pactus

echo_info "Check logs using: journalctl -f -u pactus"
echo_info "Please save your seed phrase above"
