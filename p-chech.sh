#!/bin/bash

verbose=0
log_file=""

# ✅ Help function
usage() {
  echo "Usage: $0 [-v|--verbose] log_file"
  echo ""
  echo "  -v, --verbose     Show missing sequences individually (e.g. 'Missing packets between 45 and 49')"
  echo "  -h, --help        Show this help message"
  echo ""
  echo "Example:"
  echo "  $0 -v my.isp.log"
  exit 0
}

# ✅ Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -v|--verbose)
      verbose=1
      shift
      ;;
    -h|--help)
      usage
      ;;
    -*)
      echo "Error: Unknown option: $1"
      usage
      ;;
    *)
      log_file="$1"
      shift
      ;;
  esac
done

if [[ -z "$log_file" ]]; then
  echo "❌ Error: You must specify the log file."
  usage
fi

if [[ ! -f "$log_file" ]]; then
  echo "❌ File '$log_file' not found."
  exit 2
fi

# ✅ Variables
total_expected=0
total_received=0
prev_seq=
missing=0
										  
				

file_size=$(stat -c%s "$log_file")
bytes_read=0
last_percent_shown=0

# ✅ Process log line-by-line
while IFS= read -r line; do
  # Update read byte count
  ((bytes_read += ${#line} + 1))

  seq=$(echo "$line" | grep -oP 'icmp_seq=\K[0-9]+')
  if [[ -n "$seq" ]]; then
    ((total_received++))

    if [[ -n "$prev_seq" ]]; then
      if (( seq == 0 && prev_seq == 65535 )); then
        # Normal wraparound, skip
        :
      elif (( seq > prev_seq )); then
        gap=$((seq - prev_seq - 1))
        if (( gap > 0 )); then
          ((missing += gap))
          if (( verbose )); then
            echo "Missing packets between $prev_seq and $seq"
          fi
        fi
      elif (( seq < prev_seq )); then
        gap=$(( (65535 - prev_seq) + seq ))
        if (( gap > 0 )); then
          ((missing += gap))
          if (( verbose )); then
            echo "Missing packets between $prev_seq and $seq (wraparound)"
          fi
        fi
      fi
    fi

    prev_seq=$seq
  fi

  # ✅ Progress update
  if (( file_size > 0 )); then
    percent=$((bytes_read * 100 / file_size))
    if (( percent > last_percent_shown )); then
      tput sc
      tput cup $(($(tput lines)-1)) 0
      echo -ne "🔍 Analyzing: $percent% complete     "
      tput rc
      last_percent_shown=$percent
    fi
  fi
done < "$log_file"

# ✅ Final stats
total_expected=$((total_received + missing))
tput cup $(($(tput lines)-1)) 0  # move to last line
			 
		 
								  
											 
									  
											   

if (( total_expected > 0 )); then
  loss_percent=$(awk "BEGIN { printf \"%.2f\", ($missing / $total_expected) * 100 }")
  echo -ne "📄 File analyzed    : $log_file\n"
  echo "✅ Packets received : $total_received"
  echo "❌ Packets lost     : $missing"
  echo "📦 Total expected   : $total_expected"
  echo "📉 Packet loss      : $loss_percent %"
else
  echo -e "\n⚠️ No valid packets found in the log."
fi

