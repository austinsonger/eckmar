# Base image for PHP with necessary extensions
FROM php:7.2-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    nginx \
    mysql-server \
    unzip \
    git \
    curl \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zlib1g-dev \
    libicu-dev \
    g++ \
    zip \
    vim \
    default-jdk

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip intl

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install Node.js and npm
RUN apt-get install -y nodejs npm

# Install Elasticsearch
RUN wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.9.3-amd64.deb && \
    dpkg -i elasticsearch-7.9.3-amd64.deb && \
    systemctl enable elasticsearch

# Install Redis
RUN apt-get install -y redis-server

# Copy the application files
COPY . /var/www/eckmar

# Set working directory
WORKDIR /var/www/eckmar

# Set permissions
RUN chown -R www-data:www-data /var/www/market
RUN chmod -R 755 /var/www/market/bootstrap/cache
RUN chmod -R 755 /var/www/market/storage

# Install PHP dependencies
RUN composer install

# Install Node.js dependencies
RUN npm install
RUN npm run prod

# Expose port 80
EXPOSE 80

# Copy nginx configuration
COPY docker/nginx/default /etc/nginx/sites-available/default

# Run services
CMD service nginx start && service mysql start && service redis-server start && service elasticsearch start && php-fpm
