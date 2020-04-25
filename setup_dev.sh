#!/bin/bash

# working directory
script_directory="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# check for git
git_version=$(/usr/bin/git --version)

if [[ ! $git_version ]]; then
    echo "Please make sure that the command line developer tools are installed"
    exit
fi

# check for composer
composer_path=$(/usr/bin/which composer)

if [[ ! "$composer_path" ]]; then 
    ./setup_composer.sh
    composer_path="$script_directory/composer"
fi

if [[ ! "$1" ]]; then
    echo "No argument given, we will use ./development for our dev environment."
    dev_path="$script_directory/development"
else
    echo "Our dev env will be built at $1"
    dev_path="$1"
fi

if [[ ! -d "$dev_path" ]]; then
    echo "Making directory"
    mkdir "$dev_path"
fi

############# Clone the repo!

munkireport_dev_name="munkireport_dev"
munkireport_dev_path="$dev_path"/"$munkireport_dev_name"

if [[ ! -d "$munkireport_dev_path" ]]; then
    echo "Repo does not exist, cloning into $munkireport_dev_name"
    git clone https://github.com/munkireport/munkireport-php.git "$munkireport_dev_path"
fi

############# add a thing here to pass an arg for what branch -b or --branch

cd "$munkireport_dev_path" || return

# git checkout tags/v2.7.1
# git checkout master
git checkout wip

git pull

# check if version is less than whatever uses config
# cp ./config_default.php ./config.php

############# setup .env

# look for a argument for .env template -e or --env

cd "$munkireport_dev_path" || return

env=$(/Users/crain1jp/Projects/munkireport/dev.env)

if [[ $env ]]; then
    cp "$env" ./.env
else
    echo 'AUTH_METHODS="NOAUTH"' > .env
fi

############# Run composer

cd "$munkireport_dev_path" || return

"$composer_path" update --no-dev
# "$composer_path" install --no-dev --no-suggest --optimize-autoloader
# "$composer_path" dumpautoload --optimize --no-dev

############# Look for module dev arg and bring those in -m or --module

module_path="$dev_path/modules"

if [[ ! -d "$module_path" ]]; then
    echo "Making modules directory"
    mkdir "$dev_path/modules"
fi

cd "$module_path" || return

# Clone all modules that are in core
for i in "$munkireport_dev_path"/vendor/munkireport/*; do
    module="$(basename $i)"
    if [[ ! -d "$module_path/$module" ]]; then
        echo "$module does not exist"
        git clone https://github.com/munkireport/"$module"
    else
        echo "$module exists, pull latest"
        cd "$module_path/$module"
        git pull || echo "error with pulling, you may have local commits"
        cd ../
    fi
done
echo "MODULE_SEARCH_PATHS=$module_path" >> "$munkireport_dev_path"/.env

############# Run database migrations

cd "$munkireport_dev_path" || return

php database/migrate.php
# again in case we missed something
php database/migrate.php
# one more time won't hurt anything :) 
php database/migrate.php

############# check for explicit port -p or --port

cd "$munkireport_dev_path" || return

server_name="localhost"
port=8080

############# check for autostart -s or --start
# may want to run in background

cd "$munkireport_dev_path" || return

php -S "$server_name":"$port" -t public

############# Install client locally if running in background
# munkireport_url="http://"$server_name":"$port"/index.php?"
# elevate to root?
# /bin/bash -c "$(curl -s $munkireport_url/install)"
# /usr/local/munkireport/munkireport-runner