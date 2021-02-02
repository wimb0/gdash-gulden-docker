FROM alpine:3.13
LABEL maintainer="Wim <info@wimbo.nl>"

ENV GULDEN_VERSION=2.3.5
ENV GDASH_VERSION=1.2

# Install packages and remove default server definition
RUN apk --no-cache add php7 php7-fpm php7-opcache php7-mysqli php7-json php7-openssl php7-curl \
    php7-zlib php7-xml php7-phar php7-intl php7-dom php7-xmlreader php7-ctype php7-session \
    php7-mbstring php7-gd nginx supervisor curl wget tar nano bash && \
    rm /etc/nginx/conf.d/default.conf

# Configure nginx
COPY config/nginx.conf /etc/nginx/nginx.conf

# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/php7/php-fpm.d/www.conf
COPY config/php.ini /etc/php7/conf.d/custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Setup document root
RUN mkdir -p /var/www/html

# create the gulden server directory
RUN mkdir -p /opt/gulden/datadir \
    && mkdir -p /opt/gulden/gulden

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody.nobody /var/www/html && \
  chown -R nobody.nobody /run && \
  chown -R nobody.nobody /var/lib/nginx && \
  chown -R nobody.nobody /var/log/nginx && \
  chown -R nobody.nobody /opt/gulden/datadir && \
  chown -R nobody.nobody /opt/gulden/gulden

# download and configure the Gulden node software
RUN wget https://github.com/Gulden/gulden-official/releases/download/v${GULDEN_VERSION}/Gulden-${GULDEN_VERSION}-x64-linux.tar.gz -P /opt/gulden/ \
    && tar -xvf /opt/gulden/Gulden-${GULDEN_VERSION}-x64-linux.tar.gz -C /opt/gulden/gulden \
    && rm /opt/gulden/Gulden-${GULDEN_VERSION}-x64-linux.tar.gz

# download and configure the G-DASH software
RUN wget https://g-dash.nl/download/G-DASH-${GDASH_VERSION}.tar.gz -P /var/www \
    && tar -xvf /var/www/G-DASH-${GDASH_VERSION}.tar.gz --directory /var/www/html \
    && rm /var/www/G-DASH-${GDASH_VERSION}.tar.gz

# Switch to use a non-root user from here on
USER nobody

# Add application
WORKDIR /var/www/html

# Expose the port nginx is reachable on
EXPOSE 8080 9231

ADD docker-entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD [""]

