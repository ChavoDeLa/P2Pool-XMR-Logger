#!/bin/bash

taridir="/path/to/your/tari" # path to your tari suite install files

# Command to run 
tarinode="./minotari_node --grpc-enabled --mining-enabled"
tariwallet="echo [walletpassphrase] | ./minotari_console_wallet"

while true
do
pkill -f minotari_node
sleep 5
pkill -f minotari_console_wallet
sleep 5
gnome-terminal --working-directory="$taridir" -- bash -c "$tarinode; exec bash" 
sleep 7
gnome-terminal --working-directory="$taridir" -- bash -c "$tariwallet; exec bash" 
echo "tari loop restarted to prevent memory leak"
sleep 4h
done
