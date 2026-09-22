#!/usr/bin/env bash
set -euo pipefail

cpu_temp=""
gpu_usage=""
metrics_cache="${TMPDIR:-/tmp}/tmux-macmon-metrics-$(id -u)"

if [[ "${1:-}" == "--gpu" ]]; then
  if [[ -r "$metrics_cache" ]]; then
    IFS=, read -r sampled_at _ cached_gpu <"$metrics_cache"
    if [[ "$sampled_at" =~ ^[0-9]+$ && "$cached_gpu" =~ ^[0-9]+([.][0-9]+)?$ ]] &&
       (( $(date +%s) - sampled_at <= 15 )); then
      awk -v value="$cached_gpu" 'BEGIN { printf "%.0f%%\n", value }'
      exit 0
    fi
  fi
  printf "--\n"
  exit 0
fi

# macOS 27 on this M4 Pro no longer exposes usable SMC values to the old
# osx-cpu-temp reader (it reports 0.0C). macmon uses current Apple Silicon
# telemetry and provides a JSON CPU average without sudo. Its instantaneous
# M4 sensor aggregate can jump between groups, so use a short average and a
# light rolling filter for a status-bar reading rather than a raw probe.
if command -v macmon >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
  if macmon_sample="$(macmon pipe -s 4 -i 250 2>/dev/null | jq -rs '
    {
      cpu_temp: ([.[].temp.cpu_temp_avg | select(. >= 25 and . <= 110)] |
        if length > 0 then add / length else empty end),
      gpu_usage: ([.[].gpu_active_ratio | select(. >= 0 and . <= 1)] |
        if length > 0 then (add / length) * 100 else empty end)
    } | [.cpu_temp, .gpu_usage] | @tsv
  ' 2>/dev/null)"; then
    IFS=$'\t' read -r macmon_temp macmon_gpu_usage <<<"$macmon_sample"
    if [[ "$macmon_temp" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
      cache="${TMPDIR:-/tmp}/tmux-cpu-temperature-$(id -u)"
      previous="$(cat "$cache" 2>/dev/null || true)"
      if [[ "$previous" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        macmon_temp="$(awk -v previous="$previous" -v current="$macmon_temp" 'BEGIN {
          printf "%.3f", (0.75 * previous) + (0.25 * current)
        }')"
      fi
      printf '%s\n' "$macmon_temp" >"$cache"
      cpu_temp="$(awk -v c="$macmon_temp" 'BEGIN {
        if (c > 0) printf "%.1f°F", (c * 9 / 5) + 32
      }')"
    fi
    if [[ "$macmon_gpu_usage" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
      gpu_usage="$(awk -v value="$macmon_gpu_usage" 'BEGIN { printf "GPU %.0f%%", value }')"
    fi
    if [[ -n "$cpu_temp" && "$macmon_gpu_usage" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
      printf '%s,%s,%s\n' "$(date +%s)" "$macmon_temp" "$macmon_gpu_usage" >"$metrics_cache"
    fi
  fi
fi

if command -v osx-cpu-temp >/dev/null 2>&1; then
  cpu_temp="${cpu_temp:-$(osx-cpu-temp 2>/dev/null | awk '
    match($0, /[0-9]+([.][0-9]+)?/) {
      value = substr($0, RSTART, RLENGTH)
      if (value + 0 > 0) {
        printf "%.1f°F", (value * 9 / 5) + 32
      }
    }
  ')}"
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
