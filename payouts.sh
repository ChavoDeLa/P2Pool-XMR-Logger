#!/bin/bash

file="/path/to/your/P2Pool/data/local/lastpayout.json" #edit /path/to/your/P2Pool to match your P2Pool install folder where /data/local (api folder) is located
logfile="/path/to/your/P2Pool/p2pool.log" #edit /path/to/your/P2Pool to match your P2Pool install folder where p2pool.log is located.

p2poolio() {
    local log_path="$1"
    local starttime=$(date +%s)

    if [[ ! -f "$log_path" ]]; then
        echo '{"error": "Log file not found"}'
        return
    fi

    declare -a lines=()
    local payout='{}'

    # Read last 50 lines in reverse order and parse
    mapfile -t raw_lines < <(tac "$log_path" | head -n 50)

    for line in "${raw_lines[@]}"; do
        line="${line//$'\n'/}" # remove newlines just in case
        while [[ "$line" == *"  "* ]]; do
            line="${line//  / }"
        done

        # Split line into parts: type, date, time, module, rest
        read -r type date time module rest <<<"$line"
        # Only process lines with valid tags
        case "$type" in
            INFO|WARN|ERROR|FATAL|DEBUG|TRACE|NOTICE) ;;
            *) continue ;;
        esac

        # Parse timestamp to epoch
        ts_str="$date $time"
        # Remove fractional seconds for parsing
        ts_str="${ts_str%.*}"
        timestamp=$(date -d "$ts_str" +%s 2>/dev/null)
        if [[ -z "$timestamp" ]]; then
            timestamp=0
        fi

        line_lc="${line,,}" # lowercase line

        payout_data='{"payout": false}'

        if [[ "$line_lc" == *"your wallet"* && "$line_lc" == *"got a payout of"* && "$line_lc" == *"in block"* ]]; then
            amount=$(echo "$line" | grep -oP 'got a payout of \K[\d\.]+')
            block=$(echo "$line" | grep -oP 'block \K\d+')
            payout_data="{\"amount\": \"$amount\", \"timestamp\": $timestamp, \"block\": $block}"
            payout="$payout_data"
        fi

        # Compose JSON line object
        content=$(echo "$line" | jq -Rs .)
        line_json=$(jq -n \
            --arg type "$type" \
            --argjson timestamp "$timestamp" \
            --arg module "$module" \
            --argjson payout "$payout_data" \
            --arg content "$content" \
            '{type: $type, timestamp: $timestamp, module: $module, payout: $payout, content: $content}')

        lines+=("$line_json")
    done

    exectime=$(echo "$(date +%s.%N) - $starttime" | bc)

    # Build final JSON output
    jq -n \
      --argjson payout "$payout" \
      --argjson exectime "$exectime" \
      --argjson lines "$(printf '%s\n' "${lines[@]}" | jq -s '.')" \
      '{payout: $payout, exectime: $exectime, lines: $lines}'
}

while true; do
    echo "⏳ Running payout parsing subroutine..."
    raw_output=$(p2poolio "$logfile")

    if echo "$raw_output" | jq -e . >/dev/null 2>&1; then
        payout_present=$(echo "$raw_output" | jq '.payout | length > 0')

        if [ "$payout_present" = "true" ]; then
            new_block=$(echo "$raw_output" | jq '.payout.block')

            if [ -f "$file" ]; then
                current_log=$(cat "$file")
                if [ -z "$current_log" ]; then
                    current_log="[]"
                fi
            else
                current_log="[]"
            fi

            echo "DEBUG: Current log content:"
            echo "$current_log"
            echo "DEBUG: New payout entry:"
            echo "$raw_output"

            block_exists=$(echo "$current_log" | jq --argjson b "$new_block" 'map(.payout.block) | index($b) != null')

            if [ "$block_exists" = "true" ]; then
                echo "ℹ️ Payout block $new_block already logged, skipping."
            else
                updated_log=$(jq --argjson new_entry "$raw_output" '
                    [$new_entry] + . | .[:10]
                ' <<< "$current_log")

                echo "DEBUG: Resulting updated log:"
                echo "$updated_log"

                if echo "$updated_log" | jq -e . >/dev/null 2>&1 && [ -n "$updated_log" ]; then
                    if touch "$file" 2>/dev/null; then
                        echo "$updated_log" > "$file"
                        echo "✅ Logged structured payout block $new_block."
                    else
                        echo "❌ Cannot write to file $file. Check permissions."
                    fi
                else
                    echo "❌ Failed to generate valid updated log JSON."
                fi
            fi
        else
            echo "⚠️ No payout found in output, skipping logging."
        fi
    else
        echo "⚠️ Invalid JSON output from subroutine, skipping..."
    fi

    echo "⏳ Sleeping for 2 minutes..."
    sleep 2m
done
