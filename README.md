**# P2Pool-XMR-Loggers**

**What?!?**

  A small suite of bash scripts to extend the available JSON data localed in /p2pool/data/local.
  
    launch_p2pool_tmux.sh
  1. Starts p2pool in a tmux session called "p2pterm".  Update relevant absolute paths, then run.
     
    payouts.sh
  2. Scrapes the log file (p2pool.log) every 2 minutes for new payouts, append to a structured json file with the last (10) payouts located in the data api folder, keeping payout (0) the latest each time, with debug feedback. uses some code and/or inspiration from https://github.com/OlMi1/p2poolio. Update relevant absolute paths at the top, then run.  

    status.sh  
  3. Sends "status" to the p2pool session to push outputs to the log, then scrape p2pool.log for the entire output of the "status" command every 5 minutes, structure into json, then save into a json file for further use located in the data api folder, with debug feedback.  Update relevant absolute paths at the top, then run.


reminders:
- be sure to make your .sh files executable in linux
- in your P2Pool/data/local folder, in a terminal run " python3 -m http.server 9000" to open up an http server on port 9000, so that you can access files like this:

      http://local.host.ip.address:9000/stratum
      http://local.host.ip.address:9000/lastpayout.json
      http://local.host.ip.address:9000/status.json

**Why?!?**

  P2Pool data api files miss some stuff that I wanted (uncle positions, share positions, share count, etc) and i wanted the info into JSON format, reported regularly for use in Node-Red.


**What about the tari script?!?**

    tari_loop_execute.sh
  The tari suite's minotari-node has a memory leak, and will gobble up swap and ram and then either crash Linux, or get killed by the OOM manager at length without notice.  This script simply kills any existing processes, restarts them in new terminals, and loops every 4 hours to dump the process memory and prevent whole system crashes or loss of node connectivity.

BUT YOUR CODE SUCKS!
  
  Yes, feel free to improve it. I write spaghetti code exclusively and it is never efficient or pretty. There is some GPT intervention here as well.
