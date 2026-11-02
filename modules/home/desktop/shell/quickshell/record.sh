# Screen recorder, ported from hakuspace's record_ctl.sh (deps via writeShellApplication).

SAVE_DIR=${SCREENREC_SAVE_DIR:-"$HOME/Videos/Recordings"}
STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/haku-record"
PID_FILE="$STATE_DIR/pid"
TIME_FILE="$STATE_DIR/time"
MODE_FILE="$STATE_DIR/mode"
OUTPUT_FILE="$STATE_DIR/output"
SOURCE_FILE="$STATE_DIR/source"
AUDIO_MODULES_FILE="$STATE_DIR/audio-modules"
KEEPALIVE_PID_FILE="$STATE_DIR/keepalive-pid"
COMBINED_SINK_NAME="rec_combined_sink"
LOCKED_SAMPLE_RATE=48000
LOCKED_QUANTUM=1024
REC_OPTS=(--max-fps 60)

usage() {
  cat <<'EOF'
Usage: record <COMMAND> [ARGS]

Commands:
    status [--json]                 Show recorder state
    list-modes [--json]             List recording mode IDs
    list-sources [--json]           List physical microphone/source IDs
    start <MODE> [--source <ID>]    Start recording the focused output
    stop                            Stop the active recording
    toggle                          Stop if recording, else start system-audio

Modes:
    system-audio    Capture screen + system audio
    mic-system      Capture screen + microphone + system audio
    no-audio        Capture screen without audio
EOF
}

process_running() {
  local pid=$1 stat
  [[ "$pid" =~ ^[0-9]+$ ]] || return 1
  stat=$(ps -o stat= -p "$pid" 2>/dev/null | tr -d '[:space:]') || return 1
  [[ -n "$stat" && "$stat" != Z* ]]
}

read_state() {
  [[ -f "$1" ]] && cat "$1" 2>/dev/null || true
}

is_recording() {
  process_running "$(read_state "$PID_FILE")"
}

status_cmd() {
  local recording=false pid=null
  if is_recording; then
    recording=true
    pid=$(read_state "$PID_FILE")
  fi
  if [[ "${1:-}" == "--json" ]]; then
    jq -cn \
      --argjson recording "$recording" \
      --argjson pid "$pid" \
      --arg elapsed "$(read_state "$TIME_FILE")" \
      --arg mode "$(read_state "$MODE_FILE")" \
      --arg output "$(read_state "$OUTPUT_FILE")" \
      --arg source "$(read_state "$SOURCE_FILE")" \
      '$ARGS.named'
  elif [[ "$recording" == true ]]; then
    echo recording
  else
    echo idle
  fi
}

list_modes() {
  local modes=(system-audio mic-system no-audio)
  if [[ "${1:-}" == "--json" ]]; then
    printf '%s\n' "${modes[@]}" | jq -cR '{id: .}' | jq -cs .
  else
    printf '%s\n' "${modes[@]}"
  fi
}

sources() {
  pactl list short sources 2>/dev/null | awk '$2 !~ /\.monitor$/ {print $2}'
}

list_sources() {
  if [[ "${1:-}" == "--json" ]]; then
    sources | jq -cR '{id: .}' | jq -cs .
  else
    sources
  fi
}

setup_virtual_audio() {
  local mic=$1 sink=$2 id
  rm -f "$AUDIO_MODULES_FILE"

  id=$(pactl load-module module-null-sink \
    sink_name="$COMBINED_SINK_NAME" \
    sink_properties=device.description="RecordingCombinedAudio") || return 1
  echo "$id" >>"$AUDIO_MODULES_FILE"

  # Loading a null sink can steal the default; put the real one back.
  pactl set-default-sink "$sink" || true

  id=$(pactl load-module module-loopback \
    source="$mic" sink="$COMBINED_SINK_NAME" latency_msec=1) || return 1
  echo "$id" >>"$AUDIO_MODULES_FILE"

  id=$(pactl load-module module-loopback \
    source="$sink.monitor" sink="$COMBINED_SINK_NAME" latency_msec=1) || return 1
  echo "$id" >>"$AUDIO_MODULES_FILE"
}

teardown_virtual_audio() {
  if [[ -f "$AUDIO_MODULES_FILE" ]]; then
    tac "$AUDIO_MODULES_FILE" | while IFS= read -r id; do
      [[ -n "$id" ]] && pactl unload-module "$id" 2>/dev/null || true
    done
  fi
  rm -f "$AUDIO_MODULES_FILE"
}

# fixed rate + silent stream keep audio in sync when nothing plays
lock_pipewire_rate() {
  pw-metadata -n settings 0 clock.force-rate "$LOCKED_SAMPLE_RATE" >/dev/null 2>&1 || true
  pw-metadata -n settings 0 clock.force-quantum "$LOCKED_QUANTUM" >/dev/null 2>&1 || true
}

unlock_pipewire_rate() {
  pw-metadata -n settings 0 clock.force-rate 0 >/dev/null 2>&1 || true
  pw-metadata -n settings 0 clock.force-quantum 0 >/dev/null 2>&1 || true
}

start_keepalive() {
  pacat --device="$1" --raw --rate="$LOCKED_SAMPLE_RATE" --channels=2 --format=s16le </dev/zero 2>/dev/null &
  echo $! >"$KEEPALIVE_PID_FILE"
}

stop_keepalive() {
  local pid
  pid=$(read_state "$KEEPALIVE_PID_FILE")
  [[ "$pid" =~ ^[0-9]+$ ]] && kill "$pid" 2>/dev/null || true
  rm -f "$KEEPALIVE_PID_FILE"
}

cleanup_runtime() {
  rm -f "$PID_FILE" "$TIME_FILE" "$MODE_FILE" "$OUTPUT_FILE" "$SOURCE_FILE"
  teardown_virtual_audio
  stop_keepalive
  unlock_pipewire_rate
}

stop_recording() {
  if ! is_recording; then
    cleanup_runtime
    return 3
  fi
  local pid output
  pid=$(read_state "$PID_FILE")
  output=$(read_state "$OUTPUT_FILE")
  kill -INT "$pid" 2>/dev/null || true
  while process_running "$pid"; do sleep 0.1; done
  cleanup_runtime
  notify-send -a Recorder -i video-display "Recording saved" "${output/#"$HOME"/\~}"
}

start_recording() {
  local mode=${1:-} source=''
  shift || true
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --source)
        [[ $# -ge 2 ]] || { echo "record: --source requires an ID" >&2; return 2; }
        source=$2
        shift 2
        ;;
      *)
        echo "record: unknown start argument: $1" >&2
        return 2
        ;;
    esac
  done

  case "$mode" in
    system-audio | no-audio)
      [[ -z "$source" ]] || { echo "record: --source is only valid with mic-system" >&2; return 2; }
      ;;
    mic-system)
      [[ -n "$source" ]] || { echo "record: mic-system requires --source <ID>" >&2; return 2; }
      sources | grep -qxF -- "$source" || { echo "record: unknown source: $source" >&2; return 2; }
      ;;
    '') echo "record: start requires a mode" >&2; return 2 ;;
    *) echo "record: unknown mode: $mode" >&2; return 2 ;;
  esac

  if is_recording; then
    echo "record: a recording is already active" >&2
    return 4
  fi

  local sink=''
  if [[ "$mode" != no-audio ]]; then
    sink=$(pactl get-default-sink) || { echo "record: default sink not found" >&2; return 1; }
  fi

  local display
  display=$(niri msg --json focused-output | jq -r '.name')

  mkdir -p "$SAVE_DIR" "$STATE_DIR"
  local file
  file="$SAVE_DIR/recording_$(date +%Y-%m-%d_%H-%M-%S).mp4"
  local args=("${REC_OPTS[@]}" -o "$display" -f "$file")

  trap cleanup_runtime EXIT INT TERM

  local message
  case "$mode" in
    system-audio)
      lock_pipewire_rate
      start_keepalive "$sink"
      args+=(--audio --audio-device "$sink.monitor")
      message="System audio"
      ;;
    mic-system)
      lock_pipewire_rate
      start_keepalive "$sink"
      setup_virtual_audio "$source" "$sink" || return 1
      args+=(--audio --audio-device "$COMBINED_SINK_NAME.monitor")
      message="Microphone + system audio"
      ;;
    no-audio)
      message="No audio"
      ;;
  esac

  wl-screenrec "${args[@]}" &
  local pid=$!
  echo "$pid" >"$PID_FILE"
  echo "$mode" >"$MODE_FILE"
  echo "$file" >"$OUTPUT_FILE"
  if [[ -n "$source" ]]; then echo "$source" >"$SOURCE_FILE"; fi

  notify-send -a Recorder -i video-display -t 1000 "Recording $display" "$message"

  local sec=0
  while [[ -f "$PID_FILE" ]] && process_running "$pid"; do
    printf '%02d:%02d' $((sec / 60)) $((sec % 60)) >"$TIME_FILE"
    sleep 1
    sec=$((sec + 1))
  done

  cleanup_runtime
  trap - EXIT INT TERM
}

command=${1:-}
[[ $# -gt 0 ]] && shift

case "$command" in
  status) status_cmd "$@" ;;
  list-modes) list_modes "$@" ;;
  list-sources) list_sources "$@" ;;
  start) start_recording "$@" ;;
  stop) stop_recording ;;
  toggle)
    if is_recording; then stop_recording; else start_recording system-audio; fi
    ;;
  -h | --help) usage ;;
  *)
    usage >&2
    exit 2
    ;;
esac
