# WordPress image with the site's theme/plugins baked in.
# DB credentials are NOT baked into the image — they are injected at runtime
# (docker compose .env, Kubernetes Secret, etc.).
FROM wordpress:6-php8.3-apache

COPY --chown=www-data:www-data wordpress_static_data/wordpress/wp-content/ /var/www/html/wp-content/

# Harden: disable the in-dashboard theme/plugin code editor.
ENV WORDPRESS_CONFIG_EXTRA="define('DISALLOW_FILE_EDIT', true);"

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD curl -fsS -o /dev/null http://localhost/wp-login.php || exit 1
