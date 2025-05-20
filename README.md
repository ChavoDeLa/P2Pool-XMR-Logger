**# P2Pool-XMR-Loggers**

**What?!?**

  A small suite of bash scripts to extend the available JSON data localed in /p2pool/data/local.
  
    launch_p2pool_tmux.sh
  1. Starts p2pool in a tmux session called "p2pterm".  Update relevant absolute paths, then run.
     
    payouts.sh
  2. Scrapes the log file (p2pool.log) every 2 minutes for new payouts, append to a structured json file with the last (10) payouts located in the data api folder, keeping payout (0) the latest each time, with debug feedback. uses some code and/or inspiration from https://github.com/OlMi1/p2poolio. Update relevant absolute paths at the top, then run.  

    status.sh  
  3. Sends "status" to the p2pool session to push outputs to the log, then scrape p2pool.log for the entire output of the "status" command every 5 minutes, structure into json, then save into a json file for further use located in the data api folder, with debug feedback.  Update relevant absolute paths at the top, then run.

Example Output of _lastpayout.json_ (actually holds last 10 payouts, one payout shown below in an array of (1) at index (0):
  ```json
      [
        {
          "payout": {
            "amount": "0.003784168055",
            "block": 3416010,
            "timestamp": 1747784540
          }
        }
        ]
  ``` 
Example Output of _status.json_ :     
  ```json
      {
        "timestamp": "2025-05-17 17:25:36.6680",
        "SideChain": {
          "values": [
            {"Monero node               = 127.0.0.1:RPC 18081": "ZMQ 18083"}
      ,
            {"Main chain height         ": " 3415350"}
      ,
            {"Main chain hashrate       ": " 5.170 GH/s"}
      ,
            {"Side chain ID             ": " mini"}
      ,
            {"Side chain height         ": " 10741465"}
      ,
            {"Side chain hashrate       ": " 19.637 MH/s"}
      ,
            {"Your hashrate (pool-side) ": " 145.391 KH/s"}
      ,
            {"PPLNS window              ": " 2160 blocks (+57 uncles, 0 orphans)"}
      ,
            {"PPLNS window duration     ": " 6h 17m 39s"}
      ,
            {"Your wallet address       ": " walletaddressofamainchainxmrwalletblahblah"}
      ,
            {"Your shares               ": " 11 blocks (+0 uncles, 0 orphans)"}
      ,
            {"Your shares position      ": " [.11...11......21.....1..1..2..]"}
      ,
            {"Block reward share        ": " 0.495% (0.003028016772 XMR)"}
          ]
        },
        "StratumServer": {
          "values": [
            {"Hashrate (15m est)   ": " 161.852 KH/s"}
      ,
            {"Hashrate (1h  est)   ": " 161.852 KH/s"}
      ,
            {"Hashrate (24h est)   ": " 161.852 KH/s"}
      ,
            {"Stratum hashes       ": " 106660527"}
      ,
            {"Stratum shares       ": " 230"}
      ,
            {"P2Pool shares found  ": " 0"}
      ,
            {"Average effort       ": " 180.012%"}
      ,
            {"Current effort       ": " 28.621%"}
      ,
            {"Connections          ": " 8 (8 incoming)"}
          ]
        },
        "P2PServer": {
          "values": [
            {"Connections    ": " 10 (0 incoming)"}
      ,
            {"Peer list size ": " 1279"}
      ,
            {"Uptime         ": " 0h 11m 4s"}
          ]
        },
        "MergeMiningClientTari": {
          "values": [
            {"Host       = tari://127.0.0.1": "18102"}
      ,
            {"Wallet     ": " tariwalletaddressinfoofamainchaintariwalletyouaremininginto"}
      ,
            {"Height     ": " 10712"}
      ,
            {"Difficulty ": " 549765052301"}
      ,
            {"Reward     ": " 13822.129817 Minotari"}
      ,
            {"Fees       ": " 0.000820 Minotari"}
          ]
        }
      }
  ```    
Reminders:
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
