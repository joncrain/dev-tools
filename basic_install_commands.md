# Assorted Commands to Do Stuff

```sh
# download release and install
curl -LJO https://github.com/munkireport/munkireport-php/releases/download/v5.4.1/munkireport-php-v5.4.1.zip
unzip ./munkireport-php-v5.4.1.zip -d munkireport-php
cd munkireport-php
echo 'AUTH_METHODS="NOAUTH"' > .env
php database/migrate.php
php -S localhost:8080 -t public
```

```sh
# clone from github install
git clone https://github.com/munkireport/munkireport-php.git
cd munkireport-php
git checkout wip
echo 'AUTH_METHODS="NOAUTH"' > .env
./build/setup_composer.sh
./composer update
php database/migrate.php
php -S localhost:8080 -t public
```

```sh
# install client locally
sudo /bin/bash -c "$(curl -s http://localhost:8080/index.php?/install)"
```

```sh
# submit the client data
sudo /usr/local/munkireport/munkireport-runner
```

```sh
# enable more modules
echo "MODULES='applications, ard, bluetooth, caching, certificate, disk_report, displays_info, extensions, filevault_status, findmymac, firewall, gpu, ibridge, inventory, mdm_status, munkireport, munkireportinfo, network, network_shares, power, printer, profile, security, softwareupdate, supported_os, timemachine, usb, users, user_sessions, warranty, wifi, event, managedinstalls, munki_facts, munkiinfo'" >> .env
```
