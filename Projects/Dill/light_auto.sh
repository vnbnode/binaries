#!/bin/bash

# Prompt user for the password
read -p "Enter your keystore password: " your_password

# Step 1: Install Logo
curl -s https://raw.githubusercontent.com/vnbnode/binaries/main/Logo/logo.sh

# Step 2: Download Light Validator Binary
curl -O https://dill-release.s3.ap-southeast-1.amazonaws.com/linux/dill.tar.gz

# Step 3: Extract the package
tar -xzvf dill.tar.gz && cd dill

# Step 4: Generate Validator Keys
./dill_validators_gen new-mnemonic --num_validators=1 --chain=andes --folder=./

# Step 5: Import Validator Keys
# During this process, set and save your keystore password.
./dill-node accounts import --andes --wallet-dir ./keystore --keys-dir validator_keys/ --accept-terms-of-use

# Step 6: Save Password to a File
echo "$your_password" > walletPw.txt

# Step 7: Start Light Validator Node
nohup ./start_light.sh -p walletPw.txt &

# Wait for a moment to ensure the process has started
sleep 2

# Navigate back to home directory
cd $HOME

# Display verification instructions
echo -e "\n\033[32mSetup complete!\033[0m"
echo -e "\n\033[33mTo check logs, use the following command:\033[0m"
echo -e "\033[32mtail -f \$HOME/dill/light_node/logs/dill.log\033[0m\n"
echo -e "\033[32mcurl -s localhost:3500/eth/v1/beacon/headers | jq\033[0m\n"
echo -e "\033[32mps -ef | grep dill\033[0m\n"
echo -e "\033[32m./health_check.sh -v\033[0m\n"
