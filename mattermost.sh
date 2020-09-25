#!/usr/bin/env bash

readonly LOG_TIMESTAMP_FORMAT='+%Y-%m-%d %H:%M'

readonly MM_CONFIG=${MM_CONFIG:-/mattermost/config/config.json}
readonly MM_EXEC=${MM_EXEC:-/opt/mattermost/bin/mattermost}


wait_for_db() {
    local db_host_and_port db_host db_port

    db_host_and_port="$(grep -Po '^\s*"DataSource":.*@tcp\(\K\w+:\d+(?=\).*$)' "$MM_CONFIG")" || fail "grepping db data from config file [$MM_CONFIG] failed"
    IFS=':' read -r db_host db_port <<< "$db_host_and_port"
    [[ -z "$db_host" || ! "$db_port" =~ ^[0-9]+$ ]] && fail "couldn't parse db hostname and/or port"

    log "Wait until database [$db_host:$db_port] is ready..."
    until nc -z "$db_host" "$db_port"; do
        sleep 2
    done

    log "Connection to db @ [$db_host:$db_port] established"

    return 0
}

# TODO: here trapping is not really necessary as MM is running in foreground via exec
stop_server() {
    pgrep -f mattermost | xargs kill
    exit 0
}

fail() {
    err "$1"
    exit 1
}


log() {
    local msg
    readonly msg="$1"
    echo -e "[$(date "$LOG_TIMESTAMP_FORMAT")]\tINFO  $msg" | tee -a "$LOG"
    return 0
}


err() {
    local msg
    readonly msg="$1"
    echo -e "\n\n    ERROR: $msg\n\n"  # do not pipe to $LOG
    echo -e "[$(date "$LOG_TIMESTAMP_FORMAT")]\t    ERROR  $msg" | tee -a "$LOG"
}

trap stop_server SIGINT SIGTERM

[[ -f "$MM_CONFIG" ]] || fail "[$MM_CONFIG] is not a valid file"
[[ "$AUTOSTART" =~ ^[Tt]rue$ && -x "$MM_EXEC" ]] || exit 0

# define logfile:
LOG="$(jq -r '.LogSettings.FileLocation' "$MM_CONFIG")"
[[ $? -ne 0 || -z "$LOG" || "$LOG" == null ]] && LOG=/mattermost/logs
LOG+='/stdout.log'


wait_for_db

cd "$(dirname -- "$MM_EXEC")" || fail "unable to cd to mattermost bin location"
sleep 2  # Wait to avoid "panic: Failed to open sql connection pq: the database system is starting up"
log '--> launching mattermost'
exec "$MM_EXEC" >> "$LOG" 2>&1

exit 0

