# Simple daily SMART report script - plain text version
# Only checks SMART attributes and sends report via Gotify
# Usage: daily-smart-report.sh <gotify_token>
# Drive list should be passed via SMART_DRIVES environment variable as "device:name" pairs

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GOTIFY_SCRIPT="${SCRIPT_DIR}/gotify-notify.sh"
LOG_FILE="/var/log/daily-smart-report.log"

# Get parameters
GOTIFY_TOKEN="${1:-}"

# Validate parameters
if [[ -z "$GOTIFY_TOKEN" ]]; then
    echo "Error: Gotify token not provided"
    echo "Usage: $0 <gotify_token>"
    echo "Drives should be in SMART_DRIVES environment variable"
    exit 1
fi

# Gotify configuration
GOTIFY_URL="https://notify.yanlincs.com"

# Parse drive configurations from environment variable
# SMART_DRIVES format: "device1:name1;device2:name2;..."
declare -A DRIVES=()

if [[ -n "${SMART_DRIVES:-}" ]]; then
    IFS=';' read -ra DRIVE_PAIRS <<< "$SMART_DRIVES"
    for pair in "${DRIVE_PAIRS[@]}"; do
        IFS=':' read -r device name <<< "$pair"
        if [[ -n "$device" && -n "$name" ]]; then
            DRIVES["$device"]="$name"
        fi
    done
else
    echo "Warning: No drives specified in SMART_DRIVES environment variable"
    echo "Format: SMART_DRIVES='device1:name1;device2:name2'"
    exit 1
fi

main() {
    local report=""
    local healthy_drives=0
    local total_drives=0
    
    echo "Starting daily SMART report"
    
    report="Daily SMART Report - $(date '+%Y-%m-%d')\n\n"
    report+="Drive SMART Status:\n"
    
    # Check each drive
    for device in "${!DRIVES[@]}"; do
        local device_name="${DRIVES[$device]}"
        total_drives=$((total_drives + 1))
        
        echo "Checking $device_name"
        
        # Quick device existence check
        if [[ ! -e "$device" ]]; then
            report+="[FAIL] $device_name: Device not found\n"
            continue
        fi
        
        # Detect drive type
        local drive_type="UNKNOWN"
        if [[ "$device" == *"nvme"* ]]; then
            drive_type="NVMe"
        else
            # Check if it's SSD or HDD based on rotation rate
            local smart_info
            smart_info=$(smartctl -i "$device" 2>/dev/null)
            if echo "$smart_info" | grep -q "Rotation Rate:.*Solid State Device\|Rotation Rate:.*0 rpm"; then
                drive_type="SSD"
            elif echo "$smart_info" | grep -q "Rotation Rate:.*[0-9][0-9][0-9][0-9] rpm"; then
                drive_type="HDD"
            fi
        fi
        
        # Get SMART health
        local health="UNKNOWN"
        if health=$(smartctl -H "$device" 2>/dev/null | grep -o "PASSED\|FAILED" | head -1); then
            echo "  Health: $health"
        else
            health="UNKNOWN"
            echo "  Health: $health"
        fi
        
        # Get enhanced SMART data
        local temp="N/A"
        local power_hours="N/A"
        local wear_info="N/A"
        local data_info=""
        local error_info=""
        
        if [[ "$health" == "PASSED" ]]; then
            local smart_data
            smart_data=$(smartctl -A "$device" 2>/dev/null)
            
            if [[ "$drive_type" == "NVMe" ]]; then
                # NVMe specific attributes
                temp=$(echo "$smart_data" | awk '/^Temperature:/ {print $2}' | head -1)
                if [[ -n "$temp" && "$temp" =~ ^[0-9]+$ ]]; then
                    temp="${temp}C"
                else
                    temp="N/A"
                fi
                
                power_hours=$(echo "$smart_data" | awk '/^Power On Hours:/ {print $4}' | sed 's/,//g')
                
                local percentage_used
                percentage_used=$(echo "$smart_data" | awk '/^Percentage Used:/ {print $3}' | tr -d '%')
                if [[ -n "$percentage_used" ]]; then
                    wear_info="Wear: ${percentage_used}%"
                fi
                
                local data_read data_written
                data_read=$(echo "$smart_data" | awk '/^Data Units Read:/ {match($0, /\[([^\]]+)\]/, arr); print arr[1]}')
                data_written=$(echo "$smart_data" | awk '/^Data Units Written:/ {match($0, /\[([^\]]+)\]/, arr); print arr[1]}')
                if [[ -n "$data_read" && -n "$data_written" ]]; then
                    data_info="Data: R:${data_read} W:${data_written}"
                fi
                
                local unsafe_shutdowns media_errors
                unsafe_shutdowns=$(echo "$smart_data" | awk '/^Unsafe Shutdowns:/ {print $3}')
                media_errors=$(echo "$smart_data" | awk '/^Media and Data Integrity Errors:/ {print $6}')
                
                local error_parts=()
                if [[ -n "$unsafe_shutdowns" && "$unsafe_shutdowns" -gt 0 ]]; then
                    error_parts+=("UnsafeShutdowns:$unsafe_shutdowns")
                fi
                if [[ -n "$media_errors" && "$media_errors" -gt 0 ]]; then
                    error_parts+=("MediaErrors:$media_errors")
                fi
                if [[ ${#error_parts[@]} -gt 0 ]]; then
                    error_info=$(IFS=' '; echo "${error_parts[*]}")
                fi
                
            elif [[ "$drive_type" == "SSD" ]]; then
                # SATA SSD - format similar to NVMe
                temp=$(echo "$smart_data" | awk '/Temperature_Celsius/ {print $10}' | head -1)
                if [[ -n "$temp" && "$temp" =~ ^[0-9]+$ ]]; then
                    temp="${temp}C"
                else
                    temp="N/A"
                fi
                
                power_hours=$(echo "$smart_data" | awk '/Power_On_Hours/ {print $10}' | head -1)
                
                # Wear indicator - convert to percentage used (inverse of wear level)
                local wear_level media_wearout percentage_used
                wear_level=$(echo "$smart_data" | awk '/Wear_Leveling_Count/ {print $4}' | head -1)
                media_wearout=$(echo "$smart_data" | awk '/Media_Wearout_Indicator/ {print $4}' | head -1)
                
                if [[ -n "$wear_level" ]]; then
                    # Wear_Leveling_Count: 100 = new, 0 = worn out
                    percentage_used=$((100 - wear_level))
                    wear_info="Wear: ${percentage_used}%"
                elif [[ -n "$media_wearout" ]]; then
                    # Media_Wearout_Indicator: 100 = new, 0 = worn out
                    percentage_used=$((100 - media_wearout))
                    wear_info="Wear: ${percentage_used}%"
                fi
                
                # Data read/written - convert LBAs to human readable
                local lbas_written lbas_read data_written data_read
                lbas_written=$(echo "$smart_data" | awk '/Total_LBAs_Written/ {print $10}' | head -1)
                lbas_read=$(echo "$smart_data" | awk '/Total_LBAs_Read/ {print $10}' | head -1)
                
                if [[ -n "$lbas_written" && -n "$lbas_read" ]]; then
                    # Convert LBAs to GB (1 LBA = 512 bytes)
                    # Using bash arithmetic (integer math) - divide by 2097152 to get GB (512 * LBAs / 1073741824)
                    local gb_written_int gb_read_int
                    gb_written_int=$((lbas_written / 2097152))  # LBAs * 512 / 1GB
                    gb_read_int=$((lbas_read / 2097152))
                    
                    # Format with appropriate units
                    if [[ $gb_written_int -gt 1000 ]]; then
                        # Convert to TB with one decimal place
                        local tb_written_int=$((gb_written_int / 1024))
                        local tb_written_dec=$(( (gb_written_int % 1024) * 10 / 1024 ))
                        data_written="${tb_written_int}.${tb_written_dec} TB"
                    else
                        data_written="${gb_written_int} GB"
                    fi
                    
                    if [[ $gb_read_int -gt 1000 ]]; then
                        # Convert to TB with one decimal place
                        local tb_read_int=$((gb_read_int / 1024))
                        local tb_read_dec=$(( (gb_read_int % 1024) * 10 / 1024 ))
                        data_read="${tb_read_int}.${tb_read_dec} TB"
                    else
                        data_read="${gb_read_int} GB"
                    fi
                    
                    data_info="Data: R:${data_read} W:${data_written}"
                fi
                
                # Check for errors (similar to NVMe's unsafe shutdowns and media errors)
                local program_fail erase_fail reallocated power_cycles
                program_fail=$(echo "$smart_data" | awk '/Program_Fail_Count/ {print $10}' | head -1)
                erase_fail=$(echo "$smart_data" | awk '/Erase_Fail_Count/ {print $10}' | head -1)
                reallocated=$(echo "$smart_data" | awk '/Reallocated_Sector_Ct/ {print $10}' | head -1)
                power_cycles=$(echo "$smart_data" | awk '/Power_Cycle_Count/ {print $10}' | head -1)
                
                local error_parts=()
                if [[ -n "$power_cycles" && "$power_cycles" -gt 0 ]]; then
                    error_parts+=("PowerCycles:$power_cycles")
                fi
                if [[ -n "$reallocated" && "$reallocated" -gt 0 ]]; then
                    error_parts+=("Reallocated:$reallocated")
                fi
                if [[ -n "$program_fail" && "$program_fail" -gt 0 ]]; then
                    error_parts+=("ProgramFails:$program_fail")
                fi
                if [[ -n "$erase_fail" && "$erase_fail" -gt 0 ]]; then
                    error_parts+=("EraseFails:$erase_fail")
                fi
                if [[ ${#error_parts[@]} -gt 0 ]]; then
                    error_info=$(IFS=' '; echo "${error_parts[*]}")
                fi
                
            elif [[ "$drive_type" == "HDD" ]]; then
                # HDD specific attributes
                temp=$(echo "$smart_data" | awk '/Temperature_Celsius/ {print $10}' | head -1)
                if [[ -n "$temp" && "$temp" =~ ^[0-9]+$ ]]; then
                    temp="${temp}C"
                else
                    temp="N/A"
                fi
                
                power_hours=$(echo "$smart_data" | awk '/Power_On_Hours/ {print $10}' | head -1)
                
                local reallocated
                reallocated=$(echo "$smart_data" | awk '/Reallocated_Sector_Ct/ {print $10}' | head -1)
                if [[ -n "$reallocated" ]]; then
                    wear_info="Reallocated:$reallocated"
                fi
                
                local power_cycles
                power_cycles=$(echo "$smart_data" | awk '/Power_Cycle_Count/ {print $10}' | head -1)
                if [[ -n "$power_cycles" ]]; then
                    data_info="PowerCycles:$power_cycles"
                fi
            fi
            
            echo "  Temperature: $temp"
            echo "  Power Hours: $power_hours"
            [[ -n "$wear_info" ]] && echo "  $wear_info"
            [[ -n "$data_info" ]] && echo "  $data_info"
            [[ -n "$error_info" ]] && echo "  $error_info"
        fi
        
        # Format output
        if [[ "$health" == "PASSED" ]]; then
            report+="[OK] $device_name ($drive_type): $health\\n"
            report+="    Temp: $temp"
            if [[ "$power_hours" != "N/A" ]]; then
                report+=", PowerOn: ${power_hours}h"
            fi
            if [[ -n "$wear_info" ]]; then
                report+=", $wear_info"
            fi
            report+="\\n"
            if [[ -n "$data_info" ]]; then
                report+="    $data_info\\n"
            fi
            if [[ -n "$error_info" ]]; then
                report+="    ⚠️ $error_info\\n"
            fi
            healthy_drives=$((healthy_drives + 1))
        else
            report+="[FAIL] $device_name ($drive_type): $health\\n"
            if [[ "$temp" != "N/A" ]]; then
                report+="    Temp: $temp\\n"
            fi
        fi
    done
    
    # Add summary
    report+="\nSummary:\n"
    if [[ $healthy_drives -eq $total_drives ]]; then
        report+="Status: All $total_drives drives healthy\n"
        report+="Next check: $(date -d 'tomorrow 08:00' '+%Y-%m-%d 08:00')"
        
        echo "Result: All drives healthy ($healthy_drives/$total_drives)"
        
        # Send notification
        if [[ -x "$GOTIFY_SCRIPT" ]]; then
            "$GOTIFY_SCRIPT" "$GOTIFY_URL" "$GOTIFY_TOKEN" "normal" "Daily SMART Report" "$report"
        fi
    else
        local issues=$((total_drives - healthy_drives))
        report+="Status: $issues of $total_drives drives have issues"
        
        echo "Result: Issues detected ($healthy_drives/$total_drives drives healthy)"
        
        # Send high priority notification for issues
        if [[ -x "$GOTIFY_SCRIPT" ]]; then
            "$GOTIFY_SCRIPT" "$GOTIFY_URL" "$GOTIFY_TOKEN" "high" "Daily SMART Report - Issues Detected" "$report"
        fi
    fi
    
    # Simple logging
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Daily SMART report: $healthy_drives/$total_drives drives healthy" >> "$LOG_FILE" 2>/dev/null || true
    
    echo "Daily SMART report completed"
}

main "$@"
