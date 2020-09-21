#!/usr/bin/env bash

readonly MM_EXEC=/opt/mattermost/bin/platform
readonly LOG=/var/log/mattermost.log


wait_for_db() {
    local db_host db_port

    __parse_db_connection_details() {
        local db_host_and_port config

        readonly config='/mattermost/config/config.json'

        [[ -f "$config" ]] || fail "[$config] is not a valid file"
        db_host_and_port="$(grep -Po '^\s*"DataSource":.*@tcp\(\K\w+:\d+(?=\).*$)' "$config")" || fail "grepping db data from config file [$config] failed"
        IFS=':' read -r db_host db_port <<< "$db_host_and_port"
        [[ -z "$db_host" || -z "$db_port" ]] && fail "couldn't parse either db hostname or port"
    }

    __parse_db_connection_details
    echo "Wait until database [$db_host:$db_port] is ready..."
    until nc -z "$db_host" "$db_port"; do
        sleep 2
    done

    return 0
}

stop_server() {
    pgrep -f mattermost | xargs kill
    exit 0
}

fail() {
    local msg
    readonly msg="    ERROR: $1"

    echo -e "\n\n${msg}\n\n"
    echo -e "$msg" >> "$LOG"
    exit 1
}

trap stop_server SIGINT SIGTERM

[[ "$AUTOSTART" =~ ^[Tt]rue && -x "$MM_EXEC" ]] || exit 0

wait_for_db

cd "$(dirname -- "$MM_EXEC")" || fail "unable to cd to mattermost bin"
sleep 2  # Wait to avoid "panic: Failed to open sql connection pq: the database system is starting up"
{
    echo '----------------------------------------'
    printf -- "--> launching mattermost at [%s]\n" "$(date)"
} >> "$LOG"
"$MM_EXEC" >> "$LOG" 2>&1

exit 0

