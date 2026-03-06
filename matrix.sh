#!/usr/bin/env bash

# Matrix-style falling character rain for your terminal

# Ensure UTF-8 locale for multibyte character handling
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

VERSION="1.0.0"
CODE_MODE=0
REPO_PATH="."

usage() {
    cat <<'USAGE'
Usage: matrix [options] [path]

Options:
  --code    Use characters from repository source files instead of random characters
  -h        Show help

Arguments:
  path      Path to repository (default: current directory)

Controls:
  Any key   Exit

Examples:
  matrix                    # Random chars, current directory
  matrix --code             # Repo source chars from current directory
  matrix --code ~/myproject # Repo source chars from specific repo
USAGE
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --code)
            CODE_MODE=1
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            REPO_PATH="$1"
            shift
            ;;
    esac
done

# Validate path
if [[ ! -d "$REPO_PATH" ]]; then
    echo "Error: '$REPO_PATH' is not a valid directory" >&2
    exit 1
fi

# --- Character Pool ---
CHAR_POOL=""

build_random_pool() {
    # Katakana-inspired chars, digits, symbols
    CHAR_POOL='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789@#$%^&*()_+-=[]{}|;:<>?/~ｦｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ'
}

build_code_pool() {
    local repo="$1"
    local files=""

    # Get file list: prefer git ls-files, fallback to find
    if git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        files=$(git -C "$repo" ls-files --cached --others --exclude-standard 2>/dev/null)
    else
        files=$(find "$repo" -type f \
            ! -path '*/\.*' \
            ! -name '*.png' ! -name '*.jpg' ! -name '*.jpeg' ! -name '*.gif' \
            ! -name '*.ico' ! -name '*.svg' ! -name '*.woff' ! -name '*.woff2' \
            ! -name '*.ttf' ! -name '*.eot' ! -name '*.mp3' ! -name '*.mp4' \
            ! -name '*.zip' ! -name '*.tar' ! -name '*.gz' ! -name '*.bin' \
            ! -name '*.exe' ! -name '*.dll' ! -name '*.so' ! -name '*.dylib' \
            ! -name '*.pdf' ! -name '*.lock' \
            2>/dev/null)
    fi

    # Read file contents (capped at ~500KB total), extract unique printable chars
    local max_size=500000
    CHAR_POOL=$(
        printf '%s\n' "$files" | head -200 | while IFS= read -r file; do
            [[ -z "$file" ]] && continue
            local full_path="$repo/$file"
            [[ -f "$full_path" ]] && head -c 5000 "$full_path" 2>/dev/null
        done | head -c "$max_size" | LC_ALL=C tr -dc '!-~' | grep -o . | sort -u | tr -d '\n'
    )

    # Fallback if pool is empty
    if [[ -z "$CHAR_POOL" ]]; then
        echo "Warning: No source characters found, falling back to random mode" >&2
        build_random_pool
    fi
}

# Split pool into array for safe multibyte indexing
declare -a CHAR_ARRAY=()
POOL_SIZE=0

build_char_array() {
    CHAR_ARRAY=()
    local i
    for (( i=0; i<${#CHAR_POOL}; i++ )); do
        CHAR_ARRAY+=("${CHAR_POOL:$i:1}")
    done
    POOL_SIZE=${#CHAR_ARRAY[@]}
}

# Get a random character from the pool (sets RCHAR variable, no subshell)
random_char() {
    RCHAR="${CHAR_ARRAY[RANDOM % POOL_SIZE]}"
}

if [[ "$CODE_MODE" -eq 1 ]]; then
    build_code_pool "$REPO_PATH"
else
    build_random_pool
fi

build_char_array

# --- Terminal Setup ---
COLS=0
LINES_COUNT=0
ORIG_STTY=""

get_dimensions() {
    COLS=$(tput cols)
    LINES_COUNT=$(tput lines)
}

KEY_READER_PID=""

cleanup() {
    # Kill background key reader if running
    [[ -n "$KEY_READER_PID" ]] && kill "$KEY_READER_PID" 2>/dev/null
    # Restore terminal
    tput cnorm          # Show cursor
    tput sgr0           # Reset colors
    printf '\033[2J'    # Clear screen
    printf '\033[H'     # Move to top-left
    if [[ -n "$ORIG_STTY" ]]; then
        stty "$ORIG_STTY" 2>/dev/null
    fi
    exit 0
}

init_terminal() {
    ORIG_STTY=$(stty -g 2>/dev/null)
    stty -echo          # Disable echo (we handle display ourselves)
    tput civis          # Hide cursor
    printf '\033[2J'    # Clear screen
    printf '\033[H'     # Move to top-left
    get_dimensions
}

# Trap signals for clean exit
trap cleanup EXIT INT TERM
trap 'get_dimensions; init_streams' WINCH

# --- Stream State ---
# Each column has: position (head row), length, speed counter, speed threshold, active flag, pause counter
declare -a STREAM_POS        # Current head position (row)
declare -a STREAM_LEN        # Trail length
declare -a STREAM_SPEED      # Speed counter (increments each frame)
declare -a STREAM_THRESHOLD  # Frames between advances
declare -a STREAM_ACTIVE     # 1=active, 0=paused
declare -a STREAM_PAUSE      # Pause frames remaining before respawn

init_stream() {
    local col=$1
    STREAM_POS[$col]=$(( (RANDOM % LINES_COUNT) * -1 ))  # Start above screen
    STREAM_LEN[$col]=$(( RANDOM % 5 + 4 ))               # Length 4-8
    STREAM_SPEED[$col]=0
    STREAM_THRESHOLD[$col]=$(( RANDOM % 3 + 2 ))          # Speed 2-4
    STREAM_ACTIVE[$col]=1
    STREAM_PAUSE[$col]=0
}

init_streams() {
    for (( col=0; col<COLS; col++ )); do
        if (( RANDOM % 3 == 0 )); then
            # Start some columns paused for staggered effect
            STREAM_ACTIVE[$col]=0
            STREAM_PAUSE[$col]=$(( RANDOM % 30 + 5 ))
            STREAM_POS[$col]=0
            STREAM_LEN[$col]=0
            STREAM_SPEED[$col]=0
            STREAM_THRESHOLD[$col]=1
        else
            init_stream "$col"
            STREAM_POS[$col]=$(( (RANDOM % LINES_COUNT) * -1 ))
        fi
    done
}

# --- Rendering ---

# Frame buffer — accumulate all output, flush once per frame
FRAME_BUF=""

# Move cursor and print a colored character at (row, col)
put_char() {
    local row=$1 col=$2 char=$3 color=$4
    # Only draw within bounds
    if (( row >= 0 && row < LINES_COUNT && col >= 0 && col < COLS )); then
        FRAME_BUF+="\033[$((row + 1));$((col + 1))H${color}${char}"
    fi
}

# Clear a cell
clear_cell() {
    local row=$1 col=$2
    if (( row >= 0 && row < LINES_COUNT )); then
        FRAME_BUF+="\033[$((row + 1));$((col + 1))H "
    fi
}

# Color codes for trail gradient
COLOR_HEAD='\033[1;97m'        # Bright white (head)
COLOR_NEAR='\033[1;32m'        # Bright green
COLOR_MID='\033[0;32m'         # Normal green
COLOR_DIM='\033[2;32m'         # Dim green

render_frame() {
    for (( col=0; col<COLS; col++ )); do
        # Handle paused streams
        if [[ ${STREAM_ACTIVE[$col]} -eq 0 ]]; then
            STREAM_PAUSE[$col]=$(( STREAM_PAUSE[$col] - 1 ))
            if [[ ${STREAM_PAUSE[$col]} -le 0 ]]; then
                init_stream "$col"
            fi
            continue
        fi

        # Speed control: only advance when counter reaches threshold
        STREAM_SPEED[$col]=$(( STREAM_SPEED[$col] + 1 ))
        if [[ ${STREAM_SPEED[$col]} -lt ${STREAM_THRESHOLD[$col]} ]]; then
            continue
        fi
        STREAM_SPEED[$col]=0

        local pos=${STREAM_POS[$col]}
        local len=${STREAM_LEN[$col]}

        # Draw head (bright white)
        random_char; put_char "$pos" "$col" "$RCHAR" "$COLOR_HEAD"

        # Recolor previous head position to bright green
        random_char; put_char $((pos - 1)) "$col" "$RCHAR" "$COLOR_NEAR"

        # Mid trail
        random_char; put_char $((pos - 2)) "$col" "$RCHAR" "$COLOR_MID"

        # Dim trail
        for (( t=3; t<=len; t++ )); do
            random_char; put_char $((pos - t)) "$col" "$RCHAR" "$COLOR_DIM"
        done

        # Clear tail (character falling off the trail)
        clear_cell $((pos - len - 1)) "$col"

        # Advance position
        STREAM_POS[$col]=$(( pos + 1 ))

        # Check if stream has fully exited the screen
        if (( pos - len > LINES_COUNT )); then
            STREAM_ACTIVE[$col]=0
            STREAM_PAUSE[$col]=$(( RANDOM % 20 + 5 ))  # Pause 5-24 frames
        fi
    done

    FRAME_BUF+="\033[0m"
    printf '%b' "$FRAME_BUF"
    FRAME_BUF=""
}

# --- Main Loop ---

main() {
    init_terminal

    if (( COLS < 2 || LINES_COUNT < 2 )); then
        echo "Terminal too small" >&2
        exit 1
    fi

    init_streams

    # Background process: wait for any keypress, then signal main process
    GOT_KEY=0
    trap 'GOT_KEY=1' USR1
    ( read -rsn1 _ < /dev/tty 2>/dev/null; kill -USR1 $$ 2>/dev/null ) &
    KEY_READER_PID=$!

    while true; do
        render_frame
        sleep 0.05

        # Check if background reader caught a keypress
        if (( GOT_KEY )); then
            break
        fi
    done
}

main
