#!/bin/bash
# jdb-session.sh - Manage a persistent JDB debugging session via screen
# Usage: jdb-session.sh <command> [args]
#
# Commands:
#   start [host] [port]  - Start a new jdb session (default: localhost:5005)
#   stop                  - Stop the current jdb session
#   status                - Check if jdb session is active
#   send <command>        - Send a jdb command to the active session
#   output [lines]        - Show recent jdb output (default: 30 lines)
#   clear                 - Clear the output log
#   breakpoints           - List all active breakpoints
#   bp <class>:<line>     - Set breakpoint at class:line
#   bp <class>.<method>   - Set breakpoint at class.method
#   rb <class>:<line>     - Remove breakpoint at class:line
#   resume                - Resume all threads
#   step                  - Step into
#   next                  - Step over
#   locals                - Show local variables
#   dump <expr>           - Dump object contents
#   print <expr>          - Print expression value
#   threads               - List all threads
#   quit                  - Quit jdb and end session

set -euo pipefail

SESSION_NAME="jdb_session"
JDB_LOG="/tmp/jdb_screen.log"
JDB_LOCK="/tmp/jdb_session.lock"

usage() {
    echo "Usage: $0 <command> [args]"
    echo ""
    echo "Commands:"
    echo "  start [host] [port]  Start jdb session (default: localhost:5005)"
    echo "  stop                 Stop the active session"
    echo "  status               Check if session is active"
    echo "  send <command>       Send raw jdb command"
    echo "  output [lines]       Show recent output"
    echo "  clear                Clear output log"
    echo "  breakpoints          List active breakpoints"
    echo "  bp <target>          Set breakpoint (e.g. com.foo.Bar:42 or com.foo.Bar.method)"
    echo "  rb <target>          Remove breakpoint"
    echo "  resume               Resume all threads"
    echo "  step                 Step into"
    echo "  next                 Step over"
    echo "  locals               Show local variables"
    echo "  dump <expr>          Dump object contents"
    echo "  print <expr>         Print expression value"
    echo "  threads              List all threads"
    echo "  quit                 End session"
    exit 1
}

# Check if screen session exists and is alive
session_alive() {
    screen -list 2>/dev/null | grep -q "$SESSION_NAME"
}

# Send command to jdb via screen
send_cmd() {
    local cmd="$1"
    screen -S "$SESSION_NAME" -X stuff "${cmd}\n"
    sleep 0.8
}

# Wait for jdb output (peek at log)
peek_output() {
    local lines="${1:-5}"
    tail -n "$lines" "$JDB_LOG" 2>/dev/null || echo "(no output)"
}

# Start jdb session
cmd_start() {
    local host="${1:-localhost}"
    local port="${2:-5005}"

    if session_alive; then
        echo "Session already active. Use 'stop' first or 'status' to check."
        exit 1
    fi

    echo "Starting jdb session targeting ${host}:${port}..."

    # Clear old log
    > "$JDB_LOG"

    # Start screen with jdb
    screen -dmS "$SESSION_NAME" bash -c "jdb -attach ${host}:${port} > ${JDB_LOG} 2>&1"
    sleep 3

    if ! session_alive; then
        echo "ERROR: Failed to start jdb session. Check JDWP is running on ${host}:${port}."
        exit 1
    fi

    # Mark as active
    echo "${host}:${port}" > "$JDB_LOCK"

    echo "jdb session started (screen: ${SESSION_NAME})"
    peek_output 5
}

# Stop jdb session
cmd_stop() {
    if ! session_alive; then
        echo "No active session."
        exit 0
    fi

    send_cmd "quit"
    sleep 1
    screen -S "$SESSION_NAME" -X quit 2>/dev/null || true
    rm -f "$JDB_LOCK"
    echo "Session stopped."
}

# Show session status
cmd_status() {
    if session_alive; then
        local target="(unknown)"
        [ -f "$JDB_LOCK" ] && target=$(cat "$JDB_LOCK")
        echo "Session: ACTIVE"
        echo "Target:  ${target}"
        echo "Log:     ${JDB_LOG}"
        echo ""
        peek_output 3
    else
        echo "Session: INACTIVE"
    fi
}

# Send raw jdb command
cmd_send() {
    local cmd="$*"
    if ! session_alive; then
        echo "No active session. Run 'start' first."
        exit 1
    fi
    send_cmd "$cmd"
    peek_output 5
}

# Show output
cmd_output() {
    local lines="${1:-30}"
    peek_output "$lines"
}

# Clear log
cmd_clear() {
    > "$JDB_LOG"
    echo "Log cleared."
}

# List breakpoints
cmd_breakpoints() {
    cmd_send "clear"
}

# Set breakpoint
cmd_bp() {
    local target="$1"
    # Determine format: has colon → line number, has dot → method
    if [[ "$target" == *:* ]]; then
        cmd_send "stop at $target"
    elif [[ "$target" == *.* ]]; then
        cmd_send "stop in $target"
    else
        echo "Invalid target: $target"
        echo "Use: class:line (e.g. com.foo.Bar:42) or class.method (e.g. com.foo.Bar.main)"
        exit 1
    fi
}

# Remove breakpoint
cmd_rb() {
    local target="$1"
    if [[ "$target" == *:* ]]; then
        cmd_send "clear $target"
    elif [[ "$target" == *.* ]]; then
        cmd_send "clear $target"
    else
        echo "Invalid target: $target"
        exit 1
    fi
}

# Command dispatch
case "${1:-help}" in
    start)     shift; cmd_start "$@" ;;
    stop)      cmd_stop ;;
    status)    cmd_status ;;
    send)      shift; cmd_send "$@" ;;
    output)    shift; cmd_output "$@" ;;
    clear)     cmd_clear ;;
    breakpoints) cmd_breakpoints ;;
    bp)        shift; cmd_bp "$@" ;;
    rb)        shift; cmd_rb "$@" ;;
    resume)    cmd_send "resume" ;;
    step)      cmd_send "step" ;;
    next)      cmd_send "next" ;;
    locals)    cmd_send "locals" ;;
    dump)      shift; cmd_send "dump $*" ;;
    print)     shift; cmd_send "print $*" ;;
    threads)   cmd_send "threads" ;;
    quit)      cmd_stop ;;
    help|-h|--help) usage ;;
    *)         echo "Unknown command: $1"; usage ;;
esac
