#!/bin/bash

readonly MM_EXEC=/opt/mattermost/bin/platform
readonly LOG=/var/log/mattermost.log
DB_HOST=''  # will be parsed from config
DB_PORT=''  # will be parsed from config

define_db_connection_details() {
    local db_host_and_port config

    readonly config='/mattermost/config/config.json'

    db_host_and_port="$(grep -Po '^\s*"DataSource":.*@tcp\(\K\w+:\d+(?=\).*$)' "$config")" || fail "grepping db data from config file [$config] failed"
    IFS=':' read -r DB_HOST DB_PORT <<< "$db_host_and_port"
    [[ -z "$DB_HOST" || -z "$DB_PORT" ]] && fail "couldn't parse either db hostname or port"
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

define_db_connection_details

echo "Wait until database [$DB_HOST:$DB_PORT] is ready..."
until nc -z "$DB_HOST" "$DB_PORT"; do
    sleep 2
done

cd "$(dirname -- "$MM_EXEC")" || fail "unable to cd to mattermost bin"
sleep 2  # Wait to avoid "panic: Failed to open sql connection pq: the database system is starting up"
{
    echo '----------------------------------------'
    printf -- "--> launching mattermost at [%s]\n" "$(date)"
} >> "$LOG"
"$MM_EXEC" >> "$LOG" 2>&1

exit 0





