#!/usr/bin/env bash
set -euo pipefail

cpu_temp=""

if command -v osx-cpu-temp >/dev/null 2>&1; then
  cpu_temp="$(osx-cpu-temp 2>/dev/null | awk '
    match($0, /[0-9]+([.][0-9]+)?/) {
      value = substr($0, RSTART, RLENGTH)
      if (value + 0 > 0) {
        printf "%.1f°F", (value * 9 / 5) + 32
      }
    }
  ')"
fi

if [[ -n "$cpu_temp" ]]; then
  printf "%s\n" "$cpu_temp"
  exit 0
fi

ioreg -r -n AppleSmartBattery -d 1 2>/dev/null | awk '
  /"Temperature" =/ {
    printf "%.1f°F\n", (($3 / 100) * 9 / 5) + 32
    found = 1
    exit
  }
  END {
    if (!found) {
      printf "--°F\n"
    }
  }
'
