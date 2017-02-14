#!/bin/bash
#
# https://docs.mattermost.com/install/prod-debian.html
#

readonly CONFIG='/mattermost/config/config.json'
readonly CONFIG_TMPLATE='/config.template.json'
readonly DB_HOST=${DB_HOST:-db}
readonly DB_PORT=${DB_PORT:-3306}
readonly DB_USERNAME=${DB_USERNAME:-mmuser}
readonly DB_PASSWORD=${DB_PASSWORD:-mmuser_password}
readonly DB_NAME=${DB_NAME:-mattermost}


validate() {
    local i val

    for i in \
            PUBLIC_LINK_SALT \
            INVITE_SALT \
            PWD_RESET_SALT \
            AT_REST_ENCRYPT_KEY \
                ; do
        val="$(eval echo "\$$i")"
        [[ -z "$val" ]] && fail "[$i] env var is not defined"
    done
}


setup_config() {
    check_is_file "$CONFIG_TMPLATE"
    echo -e "Configure database connection..."

    cp "$CONFIG_TMPLATE" "$CONFIG" || fail "copying config template failed"

    sed -Ei "s/DB_HOST/$DB_HOST/" "$CONFIG" || fail
    sed -Ei "s/DB_PORT/$DB_PORT/" "$CONFIG" || fail
    sed -Ei "s/DB_USERNAME/$DB_USERNAME/" "$CONFIG" || fail
    sed -Ei "s/DB_PASSWORD/$DB_PASSWORD/" "$CONFIG" || fail
    sed -Ei "s/DB_NAME/$DB_NAME/" "$CONFIG" || fail

    sed -Ei "s/PUBLIC_LINK_SALT/$PUBLIC_LINK_SALT/" "$CONFIG" || fail
    sed -Ei "s/INVITE_SALT/$INVITE_SALT/" "$CONFIG" || fail
    sed -Ei "s/PWD_RESET_SALT/$PWD_RESET_SALT/" "$CONFIG" || fail
    sed -Ei "s/AT_REST_ENCRYPT_KEY/$AT_REST_ENCRYPT_KEY/" "$CONFIG" || fail
}


setup_service_runfile() {
    local file

    readonly file=/etc/service/mattermost/run

    check_is_file "$file"

    sed -Ei "s/DB_HOST/$DB_HOST/" "$file" || fail
    sed -Ei "s/DB_PORT/$DB_PORT/" "$file" || fail
}


create_dirs() {

    mkdir -p /mattermost/{data,config} || fail "dirs creation failed"
}


check_is_file() {
    local file
    readonly file="$1"
    [[ -f "$file" ]] || fail "${FUNCNAME[1]}: [$file] is not a valid file"
}


fail() {
    local msg
    readonly msg="$1"
    echo -e "\n\n    ERROR: $msg\n\n"
    exit 1
}

validate
create_dirs
setup_config
setup_service_runfile

exit 0
