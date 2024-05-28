#!/bin/bash

# Set variables
MARKETPLACE="/var/www/privatemarket"
DB_USERNAME="marketuser"
DB_PASSWORD="marketpassword"


# Change to the desired directory
cd /var/www/$MARKETPLACE || { echo "Directory not found"; exit 1; }

# Install dependencies
composer install
npm install
npm run prod

# Set up environment file
cp .env.example .env
php artisan key:generate

# Update .env file with database connection details
sed -i "s/DB_CONNECTION=.*/DB_CONNECTION=mysql/" .env
sed -i "s/DB_HOST=.*/DB_HOST=127.0.0.1/" .env
sed -i "s/DB_PORT=.*/DB_PORT=3306/" .env
sed -i "s/DB_DATABASE=.*/DB_DATABASE=marketplace/" .env
sed -i "s/DB_USERNAME=.*/DB_USERNAME=$DB_USERNAME/" .env
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$DB_PASSWORD/" .env

# Update cache driver if redis is installed
if command -v redis-server &> /dev/null
then
    sed -i "s/CACHE_DRIVER=.*/CACHE_DRIVER=redis/" .env
fi

# Run database migrations and seed the database
php artisan migrate
php artisan db:seed

# If you want to remove dummy data, uncomment the next line
# php artisan migrate:fresh

# Link storage
php artisan storage:link

echo "Setup completed successfully."
