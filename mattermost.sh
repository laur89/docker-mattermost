#!/usr/bin/env bash

readonly LOG_TIMESTAMP_FORMAT='+%Y-%m-%d %H:%M'

MM_CONFIG=${MM_CONFIG:-/mattermost/config/config.json}
readonly MM_EXEC=/opt/mattermost/bin/mattermost

LOG="$(jq -r '.LogSettings.FileLocation' "$MM_CONFIG")"
[[ -z "$LOG" || "$LOG" == null ]] && LOG=/mattermost/logs
LOG+='/stdout.log'


wait_for_db() {
    local db_host db_port

    __parse_db_connection_details() {
        local db_host_and_port config

        readonly config='/mattermost/config/config.json'

        [[ -f "$config" ]] || fail "[$config] is not a valid file"
        db_host_and_port="$(grep -Po '^\s*"DataSource":.*@tcp\(\K\w+:\d+(?=\).*$)' "$config")" || fail "grepping db data from config file [$config] failed"
        IFS=':' read -r db_host db_port <<< "$db_host_and_port"
        [[ -z "$db_host" || -z "$db_port" ]] && fail "couldn't parse db hostname and/or port"
    }

    __parse_db_connection_details
    log "Wait until database [$db_host:$db_port] is ready..."
    until nc -z "$db_host" "$db_port"; do
        sleep 2
    done

    log "Connection to db @ [$db_host:$db_port] established"

    return 0
}

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
    echo -e "[$(date "$LOG_TIMESTAMP_FORMAT")]\tINFO  $msg" | tee --append "$LOG"
    return 0
}


err() {
    local msg
    readonly msg="$1"
    echo -e "\n\n    ERROR: $msg\n\n"  # do not pipe to $LOG
    echo -e "[$(date "$LOG_TIMESTAMP_FORMAT")]\t    ERROR  $msg" | tee --append "$LOG"
}

trap stop_server SIGINT SIGTERM

[[ "$AUTOSTART" =~ ^[Tt]rue$ && -x "$MM_EXEC" ]] || exit 0

wait_for_db

cd "$(dirname -- "$MM_EXEC")" || fail "unable to cd to mattermost bin location"
sleep 2  # Wait to avoid "panic: Failed to open sql connection pq: the database system is starting up"
log '--> launching mattermost'
exec "$MM_EXEC" >> "$LOG" 2>&1

exit 0

