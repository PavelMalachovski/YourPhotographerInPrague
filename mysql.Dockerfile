FROM mysql:5.7
    ENV MYSQL_ROOT_PASSWORD=rootPassword\
        MYSQL_DATABASE=wordpress\
        MYSQL_USER=wp-user\
        MYSQL_PASSWORD=wp-pass
COPY  wordpress_static_data/schema/Your_Photographer_in_Prague_2022_12_21_1671638379_5fe8e37_wpdb.sql /docker-entrypoint-initdb.d
