# Refer to https://hub.docker.com/_/wordpress/ for the latest
FROM wordpress:5.8.1-php8.0-apache

# Inject the default production php configurations
USER root:root
RUN mv /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini

# Copy the pre-configured .htaccess from the repo into the image
USER www-data:www-data
COPY --chown=www-data:www-data apache/.htaccess /var/www/html/

# Copy the base Wordpress install from the repo into the image volume
USER www-data:www-data
COPY --chown=www-data:www-data wordpress-core/wordpress /var/www/html/

# Copy the custom themes and plugins from the repo into the image volume
USER www-data:www-data
COPY --chown=www-data:www-data wordpress-themes /var/www/html/wp-content/themes/
COPY --chown=www-data:www-data wordpress-plugins /var/www/html/wp-content/plugins/

# Configure port 8080 for Apache
USER root:root
RUN sed -i 's/80/8080/g' /etc/apache2/sites-available/000-default.conf /etc/apache2/ports.conf

# Configure the Servername directive for Apache
USER root:root
RUN echo "ServerName 127.0.0.1" >> /etc/apache2/apache2.conf

# Copy the Docker Secrets
USER root:root
RUN mkdir /run/secrets
COPY --chown=root:root run/secrets /run/secrets

# Hardcode extra non-sensitive wp-config.php parameters
# until I figure out how to escape multiple character types within a Cloud Build YAML
ENV WORDPRESS_CONFIG_EXTRA=define(\'WP_STATELESS_MEDIA_CACHE_BUSTING\',true);define(\'JETPACK_SIGNATURE__HTTPS_PORT\',8080);define(\'WP_MEMORY_LIMIT\',\'512M\');define(\'MYSQL_CLIENT_FLAGS\',MYSQLI_CLIENT_SSL);define(\'AUTOMATIC_UPDATER_DISABLED\',true);define(\'WP_POST_REVISIONS\',3);

# Expose port 8080 for Cloud Run
EXPOSE 8080

# Continue
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
