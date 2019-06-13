
ARG   PHP_VERSION="${PHP_VERSION:-7.3.3}"
FROM  php:${PHP_VERSION}-fpm-alpine

ADD     http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz /tmp/

RUN     apk update                       && \
        \
        apk upgrade                      && \
        \
        docker-php-source extract        && \
        \
        apk add --no-cache                  \
            --virtual .build-dependencies   \
                $PHPIZE_DEPS                \
                zlib-dev                    \
                cyrus-sasl-dev              \
                git                         \
                autoconf                    \
                g++                         \
                libtool                     \
                make                        \
                pcre-dev                 && \
        \
        apk add --no-cache                  \
            tini                            \
            libintl                         \
            icu                             \
            icu-dev                         \
            libxml2-dev                     \
            postgresql-dev                  \
            freetype-dev                    \
            libjpeg-turbo-dev               \
            libpng-dev                      \
            gmp                             \
            gmp-dev                         \
            imagemagick-dev                 \
            libzip-dev                      \
            libssh2                         \
            libssh2-dev                     \
            libxslt-dev                  && \
        \
        docker-php-ext-configure gd                 \
            --with-freetype-dir=/usr/include/       \
            --with-jpeg-dir=/usr/include/       &&  \
        \
        docker-php-ext-install -j"$(getconf _NPROCESSORS_ONLN)" \
            intl                                                \
            bcmath                                              \
            xsl                                                 \
            zip                                                 \
            soap                                                \
            mysqli                                              \
            pdo                                                 \
            pdo_mysql                                           \
            pdo_pgsql                                           \
            gmp                                                 \
            iconv                                               \
            sockets                                             \
            gd                                              &&  \
        \
        tar -xvzf                                                       \
            /tmp/ioncube_loaders_lin_x86-64.tar.gz                      \
            -C /tmp/                                                &&  \
        \
        mkdir -p /usr/local/php/ext/ioncube                         &&  \
        \
        cp -a /tmp/ioncube/ioncube_loader_lin_${PHP_VERSION%.*}.so      \
            /usr/local/php/ext/ioncube/ioncube_loader.so            &&  \
        \
        pecl install                                                    \
            apcu imagick                                            &&  \
        \
        docker-php-ext-enable                                           \
            apcu imagick                                            &&  \
        \
        pecl install swoole && \
        docker-php-ext-enable swoole && \
        \
        pecl install seaslog && \
        docker-php-ext-enable seaslog && \
        \
        pecl install -o -f redis && \
        docker-php-ext-enable redis && \
        \
        apk del .build-dependencies                                 &&  \
        \
        docker-php-source delete                                    &&  \
        \
        rm -rf /tmp/* /var/cache/apk/*

# Register the COMPOSER_HOME environment variable
ENV COMPOSER_HOME /composer

# Add global binary directory to PATH and make sure to re-export it
ENV PATH /composer/vendor/bin:$PATH

# Allow Composer to be run as root
ENV COMPOSER_ALLOW_SUPERUSER 1

# Setup the Composer installer
RUN curl -o /tmp/composer-setup.php https://getcomposer.org/installer \
  && curl -o /tmp/composer-setup.sig https://composer.github.io/installer.sig \
  && php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }"

# Set up the volumes and working directory
VOLUME ["/app"]
WORKDIR /app

# Set up the command arguments
CMD ["-"]
ENTRYPOINT ["composer", "--ansi"]
