#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Log file
LOG_FILE="/var/www/privatemarket/script.log"

# Redirect stdout and stderr to the log file
exec > >(tee -a "$LOG_FILE") 2>&1

# User-defined variables
SSUSER="marketuser"
SSPASSWORD="marketpassword"
DB_PASSWORD="newpassword"
DB_NAME="marketplace"
MARKETPLACE="/var/www/privatemarket"
DB_USER="marketuser"
DB_USER_PASSWORD="marketpassword"

# Log function
log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1"
}

# Function to add sudo user
add_sudo_user() {
    log "Adding sudo user $SSUSER"
    adduser "$SSUSER" --disabled-password --gecos "" && \
    echo "$SSUSER:$SSPASSWORD" | chpasswd
    adduser "$SSUSER" sudo
}

# Function to update and upgrade packages
update_and_upgrade() {
    log "Updating and upgrading packages"
    apt-get -o Acquire::ForceIPv4=true update -y
    sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o DPkg::options::="--force-confdef" -o DPkg::options::="--force-confold" install grub-pc
    apt-get -o Acquire::ForceIPv4=true update -y
    apt-get -o Dpkg::Options::="--force-confold" dist-upgrade -q -y
    apt-get install -y software-properties-common
}

# Function to install PHP and extensions
install_php() {
    log "Installing PHP and extensions"
    add-apt-repository -y ppa:ondrej/php
    apt-get update
    apt-get install -y php7.2-fpm php-mysql php7.2-mbstring php7.2-xml php7.2-xmlrpc php7.2-gmp php7.2-curl php7.2-gd php7.2-zip unzip composer

    # Configure PHP
    sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php/7.2/fpm/php.ini
    systemctl restart php7.2-fpm
}

# Function to install and configure Nginx
install_nginx() {
    log "Installing and configuring Nginx"
    apt-get install -y nginx
    sudo ufw allow 'Nginx HTTP'

    # Create the log directory
    mkdir -p "$MARKETPLACE/logs"
    chown -R www-data:www-data "$MARKETPLACE/logs"

    # Create Nginx configuration for the website
    cat <<END >/etc/nginx/sites-available/default
}

# Function to install MySQL Server
install_mysql() {
    log "Installing MySQL Server"
    echo "mysql-server mysql-server/root_password password $DB_PASSWORD" | sudo debconf-set-selections
    echo "mysql-server mysql-server/root_password_again password $DB_PASSWORD" | sudo debconf-set-selections
    apt-get -y install mysql-server
    mysql -uroot -p"$DB_PASSWORD" -e "CREATE DATABASE $DB_NAME DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
    mysql -uroot -p"$DB_PASSWORD" -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_USER_PASSWORD';"
    mysql -uroot -p"$DB_PASSWORD" -e "GRANT ALL PRIVILEGES ON *.* TO '$DB_USER'@'localhost';"
    mysql -uroot -p"$DB_PASSWORD" -e "FLUSH PRIVILEGES;"
    service mysql restart
}

# Function to install Elasticsearch
install_elasticsearch() {
    log "Elasticsearch"
    # Install Elasticsearch
    wget https://download.elastic.co/elasticsearch/release/org/elasticsearch/distribution/deb/elasticsearch/2.3.1/elasticsearch-2.3.1.deb
    sudo dpkg -i elasticsearch-2.3.1.deb
    sudo service elasticsearch start
}

# Function to install and configure Redis
install_redis() {
    log "Installing and configuring Redis"
    apt-get install -y redis-server
    sed -i 's/supervised no/supervised systemd/' /etc/redis/redis.conf
    systemctl restart redis.service
}

# Function to install Node.js and NPM
install_node() {
    log "Installing Node.js and NPM"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install 18
    nvm use 18
}

# Function to set permissions for Marketplace files
set_permissions() {
    log "Setting permissions for Marketplace files"
    chown -R www-data:www-data "$MARKETPLACE/public"
    chmod 755 /var/www
    chmod -R 755 "$MARKETPLACE/bootstrap/cache"
    chmod -R 755 "$MARKETPLACE/storage"
    sudo chown -R $USER:www-data $MARKETPLACE/storage
    sudo chown -R $USER:www-data $MARKETPLACE/bootstrap/cache
    sudo -u www-data php "$MARKETPLACE/artisan" storage:link
    mkdir -p "$MARKETPLACE/storage/public/"
    mkdir -p "$MARKETPLACE/storage/public/products"
    sudo chmod -R 755 $MARKETPLACE/storage/public/products
    sudo chgrp -R www-data $MARKETPLACE/storage/public/products
    sudo chmod -R ug+rwx $MARKETPLACE/storage/public/products
    
}

install_nginx_config(){
server {
    listen 80;
    listen [::]:80;
    root $MARKETPLACE/public;
    index index.php index.html index.htm index.nginx-debian.html;
    server_name domain.com;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php7.2-fpm.sock;
    }

    error_log $MARKETPLACE/logs/error.log;
    access_log $MARKETPLACE/logs/access.log;
}
END
    ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/
    
    log "Checking Nginx configuration"
    nginx -t

    log "Reloading Nginx"
    systemctl reload nginx

    log "Restarting Nginx"
    systemctl restart nginx
}


# Function to install Composer dependencies
install_composer_dependencies() {
    log "Installing Composer dependencies"
    sudo -u "$SSUSER" -H sh -c "cd $MARKETPLACE && \
    php -r \"copy('https://getcomposer.org/installer', 'composer-setup.php');\" && \
    HASH=\$(wget -q -O - https://composer.github.io/installer.sig) && \
    php -r \"if (hash_file('sha384', 'composer-setup.php') === '\$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;\" && \
    php composer-setup.php && \
    php -r \"unlink('composer-setup.php');\" && \
    php composer.phar install"
}

# Function to install Node packages and build assets
install_node_packages() {
    log "Installing Node packages and building assets"
    sudo -u "$SSUSER" -H sh -c "cd $MARKETPLACE && npm install && npm run prod"
}

# Function to set up environment configuration
#setup_environment() {
#    log "Setting up environment configuration"
#    cp "$MARKETPLACE/.env.example" "$MARKETPLACE/.env"
#    php "$MARKETPLACE/artisan" key:generate
#}

# Function to migrate the database
#migrate_database() {
#    log "Migrating the database"
#    php "$MARKETPLACE/artisan" migrate
#}

# Main script execution
main() {
    log "Starting setup"
    add_sudo_user
    update_and_upgrade
    install_php
    install_nginx
    install_mysql
    install_elasticsearch
    install_redis
    install_node
    set_permissions
    install_composer_dependencies
    install_node_packages
    log "Setup completed! Please make sure to update the .env file with correct database connection details and restart your server."
}

# Execute main function
main
