# P2Pool-XMR-Loggers

What?

A small suite of bash scripts to extend the available JSON data localed in /p2pool/data/local.

  1. Start p2pool in a tmux session called "p2pterm" ( see: launch_p2pool_tmux.sh)
     
  2. Scrape the log file (p2pool.log) every 2 minutes for new payouts, append to a structured json file with the last (10) payouts located in the data api folder, keeping payout (0) the latest each time, with debug feedback. (see: payouts.sh)
     
  3. Send "status" to the p2pool session to push outputs to the log, then scrape p2pool.log for the entire output of the "status" command, structure into json, then save into a json file for further use located in the data api folder, with debug feedback. (see: status.sh)

Why?

P2Pool data api files miss some stuff that I wanted (uncle positions, share positions, share count, etc) and i wanted the info into JSON format, reported regularly for use in Node-Red.
