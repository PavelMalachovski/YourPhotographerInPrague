FROM wordpress:latest
    ENV WORDPRESS_DB_HOST=db\
        WORDPRESS_DB_USER=wp-user\
        WORDPRESS_DB_PASSWORD=wp-pass
COPY wordpress_static_data/wordpress/wp-content/ /var/www/html/wp-content/
RUN --network=wordpress-network
EXPOSE 80 443

FROM mysql:5.7
    ENV MYSQL_ROOT_PASSWORD=rootPassword\
        MYSQL_DATABASE=wordpress\
        MYSQL_USER=wp-user\
        MYSQL_PASSWORD=wp-pass
COPY wordpress_static_data/wordpress/wp-schema/ /docker-entrypoint-initdb.d
RUN --network=wordpress-network
EXPOSE 3306