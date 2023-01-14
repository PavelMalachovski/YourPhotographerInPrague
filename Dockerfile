FROM wordpress:latest
    ENV WORDPRESS_DB_HOST=db\
        WORDPRESS_DB_USER=wp-user\
        WORDPRESS_DB_PASSWORD=wp-pass
COPY wordpress_static_data/wordpress/wp-content/ /var/www/html/wp-content/
