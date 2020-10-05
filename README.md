# Mattermost docker installation

[Mattermost](https://mattermost.com/) is an open source, self-hosted Slack-alternative.

## Setup

### MySql/Mariadb

Assumes accessible mysql/maria db is already installed.

Log in to the docker/machine hosting the database and create the user & databases:

```
mysql -uroot -p${DB_ROOT_PW} <<'EOF'
DROP DATABASE IF EXISTS `mattermost`;
CREATE DATABASE `mattermost` CHARACTER SET = 'utf8';
CREATE USER IF NOT EXISTS 'mmuser'@'%' IDENTIFIED BY 'mm_db_password';
GRANT ALL PRIVILEGES ON `mattermost`.* TO `mmuser`@'%';
FLUSH PRIVILEGES;
EOF
```

Note you need to link mattermost docker to the mariadb/mysql docker by `--link`ing it.

### Mattermost

The embedded `setup-mattermost.sh` script is executed when running the image for the
first time, which configures mattermost with the values you provide.
If you're using this docker on unraid, this means running the `docker run` command
below from command line, not from template.

Run the image in a container, exposing ports as needed and making `/mattermost` volume permanent.

For example, you could use following command to setup (note the db data must
match the one you used when creating the db table & user above)

(note you can generate salts w/ `tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 48 | head -n 1`)

    docker run -it --rm \
      -e DB_HOST=db \
      -e DB_PORT=3306 \
      -e DB_USERNAME=mmuser \
      -e DB_PASSWORD=mm_db_password \
      -e DB_NAME=mattermost \
      -e PUBLIC_LINK_SALT=OVERRIDE_ME \
      -e AT_REST_ENCRYPT_KEY=OVERRIDE_ME \
      -v /path/on/host/to-data-dir:/mattermost \
      --link db \
      layr/mattermost setup-mattermost.sh

## Running

Run the image again, this time you probably want to give it a name.
**The image will autostart the `mattermost` process if the environment
variable `AUTOSTART=true` is set.** A reasonable docker command would be

    docker run -d \
      --name mattermost \
      -p 8065:8065 \
      -v /path/on/host/to-data-dir:/mattermost \
      -e AUTOSTART=true \
      --link db \
      layr/mattermost

For unraid users: this is the command that should to be converted into a Docker template.
