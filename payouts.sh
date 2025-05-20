#!/bin/bash

p2pool_log="/path/to/your/P2Pool/p2pool.log" #edit /path/to/your/P2Pool to match your P2Pool install folder where p2pool.log is located.
logfile="/path/to/your/P2Pool/data/local/lastpayout.json" #edit /path/to/your/P2Pool to match your P2Pool install folder where /data/local (api folder) is located

p2poolio() {
    local path="$1"
    local linelimit=20
    local payout_found=false
    local payout_amount=""
    local payout_block=""
    local payout_timestamp=""

    if [[ ! -f "$path" ]]; then
        echo '{"error":"Log file not found"}'
        return
    fi

    mapfile -t all_lines < <(tac "$path")

    for line in "${all_lines[@]}"; do
        if (( linelimit-- <= 0 )); then
            break
        fi

        # Normalize spacing
        while [[ "$line" =~ "  " ]]; do
            line="${line//  / }"
        done

        type=$(echo "$line" | cut -d' ' -f1)
        possibleTags=("INFO" "WARN" "ERROR" "FATAL" "DEBUG" "TRACE" "NOTICE")
        if [[ ! " ${possibleTags[*]} " =~ " $type " ]]; then
            continue
        fi

        timestamp_str=$(echo "$line" | awk '{print $2" "$3}' | cut -d'.' -f1)
        timestamp_epoch=$(date -d "$timestamp_str" +%s 2>/dev/null)
        [[ $? -ne 0 ]] && continue

        content=$(echo "$line" | cut -d' ' -f5-)
        lc_content=$(echo "$content" | tr '[:upper:]' '[:lower:]')

        if [[ "$lc_content" == *"your wallet"* && "$lc_content" == *"got a payout of"* && "$lc_content" == *"in block"* ]]; then
            payout_found=true
            payout_amount=$(echo "$content" | grep -oP 'got a payout of \K[0-9.]+' || echo "")
            payout_block=$(echo "$content" | grep -oP 'block \K[0-9]+' || echo "")
            payout_timestamp="$timestamp_epoch"
            break
        fi
    done

    if $payout_found && [[ -n "$payout_amount" && -n "$payout_block" && -n "$payout_timestamp" ]]; then
        echo "{\"payout\":{\"amount\":\"$payout_amount\",\"block\":$payout_block,\"timestamp\":$payout_timestamp}}"
    else
        echo '{"payout":{}}'
    fi
}

while true; do
    echo "⏳ Running payout parser function..."
    raw_output=$(p2poolio "$p2pool_log")

    if echo "$raw_output" | jq -e . >/dev/null 2>&1; then
        payout_present=$(echo "$raw_output" | jq '.payout | length > 0')

        if [ "$payout_present" = "true" ]; then
            new_block=$(echo "$raw_output" | jq '.payout.block')

            if [ -f "$logfile" ]; then
                current_log=$(cat "$logfile")
                [ -z "$current_log" ] && current_log="[]"
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
                updated_log=$(jq --argjson new_entry "$raw_output" '[$new_entry] + . | .[:10]' <<< "$current_log")

                echo "DEBUG: Resulting updated log:"
                echo "$updated_log"

                if echo "$updated_log" | jq -e . >/dev/null 2>&1 && [ -n "$updated_log" ]; then
                    if touch "$logfile" 2>/dev/null; then
                        echo "$updated_log" > "$logfile"
                        echo "✅ Logged structured payout block $new_block."
                    else
                        echo "❌ Cannot write to file $logfile. Check permissions."
                    fi
                else
                    echo "❌ Failed to generate valid updated log JSON."
                fi
            fi
        else
            echo "⚠️ No payout found in output, skipping logging."
        fi
    else
        echo "⚠️ Invalid JSON output from payout parser, skipping..."
    fi

    echo "⏳ Sleeping for 2 minutes..."
    sleep 2m
done
