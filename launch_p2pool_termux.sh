#!/bin/bash

session_name="p2pterm"
p2pooldir="/path/to/your/P2Pool" # path to your P2Pool install location
p2pool_cmd="./p2pool --data-api /path/to/your/P2Pool/data  --loglevel 1 --[other+arguments]" # edit /path/to/your p2pool data api folder, use --loglevel 1 to reduce log verbosity. add other arguments as necessary

# Check if tmux session exists
if ! tmux has-session -t "$session_name" 2>/dev/null; then
    # Create new detached tmux session with working directory and start command
    tmux new-session -d -s "$session_name" -c "$p2pooldir" "$p2pool_cmd"
    # Set scrollback buffer size for the session
    tmux set-option -t "$session_name" history-limit 1000
    echo "Started tmux session '$session_name' with scrollback 1000 lines."
else
    echo "Tmux session '$session_name' already exists."
fi

# Open a new gnome-terminal attached to the tmux session
gnome-terminal -- bash -c "tmux attach-session -t $session_name"
