# enable firewall
sudo ufw enable -y
sudo ufw allow 22
sudo ufw allow 80
sudo ufw allow 8545
sudo ufw allow 1888
sudo ufw allow 1111

# Setup config.yaml

tee /root/config.yaml  > /dev/null << EOF
ip: $fqn
id: $ID
genesisContracts:
  bootstrapContractsRegistryAddress: 0xDAFEA492D9c6733ae3d56b7Ed1ADB60692c98Bc5
consensusPort: 1888
grpcPort: 1111
privateKeyHex:$Privkey
poolConfig:
  initCap: 5
  maxCap: 30
  idleTimeout: 180
clientKeepAliveConfig:
  keepAliveTime: 1
  keepAliveTimeOut: 20
serverKeepAliveConfig:
  serverKeepAliveTime: 70
  serverKeepAliveTimeOut: 10
  minTime: 60
rpcPoolConfig:
  maxOpenCount: 1
  maxIdleCount: 1
  maxIdleTime: 30
EOF

cpath="/etc/letsencrypt/live/"$fqn"/fullchain.pem"
ppath="/etc/letsencrypt/live/"$fqn"/privkey.pem"
sleep 1
chmod +x config.yaml
chmod +x genesis.json

# Setup observe

tee /root/observe.sh > /dev/null << EOF
#!/bin/sh
# filename: observe.sh
if [ ! -d rbn ]; then
  echo "rbn doesnt exist. Initialising redbelly"
  mkdir -p rbn
  mkdir -p consensus
  cp config.yaml ./consensus

  ./binaries/rbbc init --datadir=rbn --standalone
  rm -rf ./rbn/database/chaindata
  rm -rf ./rbn/database/nodes
  cp genesis.json ./rbn/genesis
else
  echo "rbn already exists. continuing with existing setup"
  cp config.yaml ./consensus
fi

# Run EVM
rm -f log
./binaries/rbbc run --datadir=rbn --consensus.dir=consensus --tls --consensus.tls --tls.cert=$cpath --tls.key=$ppath --http --http.addr=0.0.0.0 --http.corsdomain=* --http.vhosts=* --http.port=8545 --http.api eth,net,web3,rbn --ws --ws.addr=0.0.0.0 --ws.port=8546 --ws.origins="*" --ws.api eth,net,web3,rbn --threshold=200 --timeout=500 --logging.level info --mode production --consensus.type dbft --config.file config.yaml --bootstrap.tries=10 --bootstrap.wait=10 --recovery.tries=10 --recovery.wait=10
EOF

#Create start-rbn.sh
tee /root/start-rbn.sh > /dev/null << EOF
#!/bin/sh
# filename: start-rbn.sh
mkdir -p binaries
mkdir -p consensus
chmod +x rbbc
cp rbbc binaries/rbbc
mkdir -p logs
nohup ./observe.sh > ./logs/rbbcLogs 2>&1 &
EOF

chmod +x observe.sh
chmod +x start-rbn.sh

#Run start file
./start-rbn.sh

# Logo
sleep 1 && curl -s https://raw.githubusercontent.com/vnbnode/binaries/main/Logo/logo.sh | bash && sleep 1
echo '====================================== SETUP FINISHED ========================================='
echo -e "\e[1;32m Check status: \e[0m\e[1;36m${CYAN} pgrep rbbc ${NC}\e[0m"
echo -e "\e[1;32m Check logs  : \e[0m\e[1;36m${CYAN} cat ./logs/rbbcLogs ${NC}\e[0m"
echo '===================================== SETUP FINISHED =========================================='
