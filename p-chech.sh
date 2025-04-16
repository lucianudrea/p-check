#!/bin/bash

verbose=0
log_file=""

# ✅ Funcție help
usage() {
  echo "Utilizare: $0 [-v|--verbose] fisier_log"
  echo ""
  echo "  -v, --verbose     Afișează secvențele lipsă individuale (ex: 'Lipsă între 45 și 49')"
  echo "  -h, --help        Afișează acest mesaj de ajutor"
  echo ""
  echo "Exemplu:"
  echo "  $0 -v my.isp.log"
  exit 0
}

# ✅ Parsare argumente
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
      echo "Eroare: Opțiune necunoscută: $1"
      usage
      ;;
    *)
      log_file="$1"
      shift
      ;;
  esac
done

if [[ -z "$log_file" ]]; then
  echo "❌ Eroare: Nu ai specificat fișierul de log."
  usage
fi

if [[ ! -f "$log_file" ]]; then
  echo "❌ Fișierul '$log_file' nu există."
  exit 2
fi

# ✅ Variabile
total_expected=0
total_received=0
prev_seq=
missing=0
log_size=$(stat --format="%s" "$log_file")
processed_size=0

# ✅ Loop prin log
while read -r line; do
  seq=$(echo "$line" | grep -oP 'icmp_seq=\K[0-9]+')
  if [[ -n "$seq" ]]; then
    ((total_received++))

    if [[ -n "$prev_seq" ]]; then
      if (( seq == 0 && prev_seq == 65535 )); then
        # Wrap normal, ignorăm
        :
      elif (( seq > prev_seq )); then
        gap=$((seq - prev_seq - 1))
        if (( gap > 0 )); then
          ((missing += gap))
          if (( verbose )); then
            echo "Pachete lipsă între $prev_seq și $seq"
          fi
        fi
      elif (( seq < prev_seq )); then
        gap=$(( (65535 - prev_seq) + seq ))
        if (( gap > 0 )); then
          ((missing += gap))
          if (( verbose )); then
            echo "Pachete lipsă între $prev_seq și $seq (wraparound)"
          fi
        fi
      fi
    fi

    prev_seq=$seq
  fi

  # Afișează progresul
  ((processed_size+=${#line}))
  progress=$((processed_size * 100 / log_size))
  echo -ne "Analyzing: $progress% completed
"
done < "$log_file"

total_expected=$((total_received + missing))

# ✅ Rezumat
echo -e "
📄 Fișier analizat : $log_file"
echo "✅ Pachete primite  : $total_received"
echo "❌ Pachete pierdute : $missing"
echo "📦 Total așteptate  : $total_expected"

if (( total_expected > 0 )); then
  loss_percent=$(awk "BEGIN { printf "%.2f", ($missing / $total_expected) * 100 }")
  echo "📉 Pierdere         : $loss_percent %"
else
  echo "⚠️ Nu s-au găsit pachete valide în log."
fi
