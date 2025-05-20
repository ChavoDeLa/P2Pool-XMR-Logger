#!/bin/bash
#this script only works if P2Pool is running in a tmux session called "p2pterm"!!!!
#this script pulls all data from the last occurence of the word "SideChain" until 6 lines after "MergeMiningClientTari" and should be compatible in most cases with P2pool 4.6 and above, or 4.5 and above if merger mining tari.
#this script may fail if you are on an older version of P2Pool (pre-4.6) and are not merge mining tari.
#some fields, such as uncle positions, will pop in and out of the json depending on whether "status" returns anything.

LOG_FILE="/path/to/your/P2Pool/p2pool.log" # edit to match path to your P2Pool install where p2pool.log is located
OUTPUT_FILE="/path/to/your/P2Pool/data/local/status.json" # edit to match path to your P2Pool local data api folder.
CLEAN_FILE="/tmp/p2pool_status_block.txt"
JSON_TMP="/tmp/p2pool_status_parsed.json"
session_name="p2pterm"

while true; do
  echo "$(date '+%Y-%m-%d %H:%M:%S') Running P2Pool status fetch..."

  # Send "status" command to the tmux session
  tmux send-keys -t "$session_name" "status" C-m
  sleep 2  # Give it time to write to the log

  # Extract last occurrence of 'SideChain' and collect through 6 lines after 'MergeMiningClientTari'
  start_line=$(grep -n "SideChain status" "$LOG_FILE" | tail -n 1 | cut -d: -f1)
  mmc_line=$(tail -n +"$start_line" "$LOG_FILE" | grep -n "MergeMiningClientTari status" | head -n 1 | cut -d: -f1)

  if [[ -z "$start_line" || -z "$mmc_line" ]]; then
    echo '{"error": "Could not locate required status sections"}' > "$OUTPUT_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') Error: Could not locate required status sections."
    sleep 300
    continue
  fi

  mmc_absolute_line=$((start_line + mmc_line - 1))
  end_line=$((mmc_absolute_line + 6))

  sed -n "${start_line},${end_line}p" "$LOG_FILE" > "$CLEAN_FILE"

  # Initialize JSON output
  echo "{" > "$JSON_TMP"
  timestamp=""
  current_section=""
  declare -a section_values

  emit_section() {
    local name="$1"
    local -n values_ref=$2
    echo "  \"${name}\": {" >> "$JSON_TMP"
    echo "    \"values\": [" >> "$JSON_TMP"
    local count=${#values_ref[@]}
    for ((i=0; i<count; i++)); do
      echo "${values_ref[i]}" | sed 's/^/      /' >> "$JSON_TMP"
      [[ $i -lt $((count - 1)) ]] && echo "," >> "$JSON_TMP"
    done
    echo "    ]" >> "$JSON_TMP"
    echo "  }," >> "$JSON_TMP"
  }

  while IFS= read -r line; do
    # Match section headers: NOTICE  YYYY-MM-DD HH:MM:SS.sss SECTION status
    if [[ "$line" =~ ^NOTICE[[:space:]]+([0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]][0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]+)[[:space:]]+(.+)[[:space:]]status ]]; then
      [[ -z "$timestamp" ]] && timestamp="${BASH_REMATCH[1]}"
      if [[ -n "$current_section" ]]; then
        emit_section "$current_section" section_values
      fi
      current_section="${BASH_REMATCH[2]// /_}"
      section_values=()
      continue
    fi

    # Match key-value lines
    if [[ "$line" =~ ^[[:space:]]*([^=:\ ]+.*?)\s*[:=]\s*(.+)$ ]]; then
      key="${BASH_REMATCH[1]}"
      value="${BASH_REMATCH[2]}"
      jq_key=$(printf '%s' "$key" | jq -R .)
      jq_value=$(printf '%s' "$value" | jq -R .)
      section_values+=("{${jq_key}: ${jq_value}}")
    fi
  done < "$CLEAN_FILE"

  if [[ -n "$current_section" ]]; then
    emit_section "$current_section" section_values
  fi

  # Add timestamp and close JSON
  sed -i "1a \  \"timestamp\": \"${timestamp}\"," "$JSON_TMP"
  sed -i '$ s/},$/}/' "$JSON_TMP"
  echo "}" >> "$JSON_TMP"

  mv "$JSON_TMP" "$OUTPUT_FILE"

  echo "$(date '+%Y-%m-%d %H:%M:%S') Status JSON updated at $OUTPUT_FILE"

  sleep 300
done
