#!/bin/bash

if [ $# -eq 0 ]
  then
    no_args="True"
fi

# working directory
script_directory="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

######## Default Variables
dev_path_variable="$script_directory/development"
env_template=""

# check for git
git_version=$(/usr/bin/git --version)

if [[ ! $git_version ]]; then
    echo "Please make sure that the command line developer tools are installed"
    exit
fi

# check for composer
composer_path=$(/usr/bin/which composer)

if [[ ! "$composer_path" ]]; then 
    EXPECTED_CHECKSUM="$(curl --silent https://composer.github.io/installer.sig)"
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

    if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]
    then
        >&2 echo 'ERROR: Invalid installer checksum'
        exit 1
    fi

    php composer-setup.php --filename composer
    RESULT=$?
    rm composer-setup.php
    composer_path="$script_directory/composer"
fi

if [[ "$no_args" = "True" ]]; then
    while [ ! -d "$dev_path" ];
        do
            echo -e "Please specific the directory to where MunkiReport should be installed:"
            read dev_path
            if [ ! -d "$dev_path" ]; then
	            read -p "$dev_path does not exist. Create inside current directory (y/N)? " create_path
                case ${create_path:0:1} in
	            [yY]) mkdir -p "$dev_path"
                echo "Directory created at $script_directory/$dev_path";;
                *) echo ;;
                esac
            fi
        done
    dev_path="$script_directory/$dev_path"
else
    echo "We will use $dev_path_variable for our dev environment."
    dev_path="$dev_path_variable"
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

echo -e "Please specific the branch to use (or press enter use master)" 
read branch

if [ -n "${branch}" ]; then 
    git checkout "$branch" || echo "Branch does not exist, staying on master."
else
    git checkout master
fi

git pull

# check if version is less than whatever uses config
# cp ./config_default.php ./config.php

############# setup .env

cd "$munkireport_dev_path" || return

current_env="$munkireport_dev_path/.env"

if [[ ! -f $current_env ]]; then
    echo "Creating a default .env file with NOAUTH"
    echo 'AUTH_METHODS="NOAUTH"' > .env
else
    echo ".env already exists, we will continue using."
fi

############# Run composer

cd "$munkireport_dev_path" || return

"$composer_path" update --no-dev
# "$composer_path" install --no-dev --no-suggest --optimize-autoloader
# "$composer_path" dumpautoload --optimize --no-dev

############# Look for module dev arg and bring those in -m or --module

cd "$dev_path" || return

if [[ "$no_args" = "True" ]]; then
    read -p "Would you like to clone existing core modules to work on (y/N)? " work_on_modules
    case ${work_on_modules:0:1} in
    [yY]) while [ ! -d "$module_path" ];
            do
                echo -e "Please specific the directory to where MunkiReport modules should be installed:"
                read module_path
                if [ ! -d "$module_path" ]; then
                    read -p "$module_path does not exist. Create inside $dev_path (y/N)? " create_path
                    case ${create_path:0:1} in
                    [yY]) mkdir -p "$dev_path/$module_path"
                    echo "Directory for modules created at $dev_path/$module_path"
                    module_path="$dev_path/$module_path";;
                    *) echo ;;
                    esac
                fi
            done

    cd "$dev_path" || return

    cd "$module_path" || return

    # Clone all modules that are in core
    for i in "$munkireport_dev_path"/vendor/munkireport/*; do
        module="$(basename $i)"
        if [[ ! -d "$module" ]]; then
            echo "$module does not exist"
            git clone https://github.com/munkireport/"$module"
        else
            echo "$module exists, pull latest"
            cd "$module"
            git pull || echo "error with pulling, you may have local commits"
            cd ../
        fi
    done
    echo "MODULE_SEARCH_PATHS=$module_path" >> "$munkireport_dev_path"/.env;;
    *) echo ;;
    esac
fi 

cd "$dev_path" || return

if [[ "$no_args" = "True" ]]; then
    read -p "Would you like to clone Tuxudo's modules to work on (y/N)? " work_on_tux
    case ${work_on_tux:0:1} in
    [yY]) while [ ! -d "$module_path" ];
            do
                echo -e "Please specific the directory to where MunkiReport modules should be installed:"
                read module_path
                if [ ! -d "$module_path" ]; then
                    read -p "$module_path does not exist. Create inside $dev_path (y/N)? " create_path
                    case ${create_path:0:1} in
                    [yY]) mkdir -p "$dev_path/$module_path"
                    echo "Directory for modules created at $dev_path/$module_path"
                    module_path="$dev_path/$module_path";;
                    *) echo ;;
                    esac
                fi
            done

    cd "$munkireport_dev_path" || return

    # load tux modules
    echo '''{
    "require": {
        "tuxudo/thunderbolt": "^1.0",
        "tuxudo/teamviewer": "^1.0",
        "tuxudo/ms_office": "^1.0",
        "tuxudo/memory": "^1.0",
        "tuxudo/launchdaemons": "^1.0",
        "tuxudo/kernel_panics": "^1.0",
        "tuxudo/ios_devices": "^1.0",
        "tuxudo/icloud": "^1.0",
        "tuxudo/system_version": "^1.0",
        "tuxudo/snowagent": "^1.0",
        "tuxudo/jamf": "^1.0",
        "tuxudo/firewall": "^1.0",
        "tuxudo/extension_attributes": "^1.0"
    }
}''' > "$munkireport_dev_path/composer.local.json"
    "$composer_path" update --no-dev

    cd "$dev_path" || return

    cd "$module_path" || return

    for i in "$munkireport_dev_path"/vendor/tuxudo/*; do
        module="$(basename $i)"
        if [[ ! -d "$module" ]]; then
            echo "$module does not exist"
            git clone https://github.com/tuxudo/"$module"
        else
            echo "$module exists, pull latest"
            cd "$module"
            git pull || echo "error with pulling, you may have local commits"
            cd ../
        fi
    done
    echo "MODULE_SEARCH_PATHS=$module_path" >> "$munkireport_dev_path"/.env;;
    *) echo ;;
    esac
fi 


################ Create a new module ?

if [[ "$no_args" = "True" ]]; then
    read -p "Would you like to create a new module to work on (y/N)? " new_module
    case ${new_module:0:1} in
    [yY]) while [ ! -d "$module_path" ];
            do
                echo -e "Please specific the directory to where MunkiReport modules should be installed:"
                read module_path
                if [ ! -d "$module_path" ]; then
                    read -p "$module_path does not exist. Create inside $dev_path (y/N)? " create_path
                    case ${create_path:0:1} in
                    [yY]) mkdir -p "$dev_path/$module_path"
                    echo "Directory for modules created at $dev_path/$module_path"
                    module_path="$dev_path/$module_path";;
                    *) echo ;;
                    esac
                fi
            done

    cd "$module_path" || return

    echo -e "Please specific the name for your new module:"
    read module_name
    "$munkireport_dev_path"/build/addmodule.sh "$module_name"
    echo "MODULE_SEARCH_PATHS=$module_path" >> "$munkireport_dev_path"/.env;;
    *) echo ;;
    esac
fi 

############# Run database migrations

cd "$munkireport_dev_path" || return

php database/migrate.php
# again in case we missed something
php database/migrate.php
# one more time won't hurt anything :) 
php database/migrate.php

############# enable all modules?

if [[ "$no_args" = "True" ]]; then
    read -p "Would you like to enable all modules (y/N)? " enable
    case ${enable:0:1} in
    [yY]) modules=""
    for i in "$munkireport_dev_path"/vendor/munkireport/*; do
        module="$(basename $i)"
        modules="$modules,$module"
    done
    if [ -d "$munkireport_dev_path/vendor/tuxudo" ]; then
        for i in "$munkireport_dev_path"/vendor/tuxudo/*; do
            module="$(basename $i)"
            modules="$modules,$module"
        done
    fi
    if [ -d "$module_path" ]; then
        for i in "$module_path"/*; do
            module="$(basename $i)"
            modules="$modules,$module"
        done
    fi  
    echo "MODULES=\"$modules\"" >> .env;;
    *) echo ;;
    esac
fi 


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