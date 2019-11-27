FROM httpd:2.4-alpine
MAINTAINER Chakrit W <quaos.qrz@gmail.com>

#Reference dockerfile: https://github.com/docker-library/httpd/blob/82fd968fb7cfe496a0f87888777e834530dd9154/2.4/alpine/Dockerfile

LABEL name=httpd-2.4-php7-alpine
LABEL version=1.1.0
LABEL author="Chakrit W <quaos.qrz@gmail.com>"

ARG WWWDATA_UID=82
ARG WWWDATA_GID=82
#ARG HTTPD_EXTRA_CONFIGURE_ARGS=""
ARG PHP_VERSION=7.3.12
ARG PHP_BASE_URL="https://secure.php.net"
# http://php.net/downloads.php
# SHA for .tar.gz :
ARG PHP_SHA256="a0cb9bf2f78498fc090eb553df03cdacc198785dec0818efa7a1804c2b7a8722"
ARG PHP_EXTRA_CONFIGURE_ARGS=""
ARG MY_SRC_PATH_PREFIX="2.4/php7.3.12-alpine/"
#"2.4/alpine/"
ARG HTTP_PORT=8080

# Install prerequisite tools {
RUN echo "## Installing prerequisites {"; \
    set -x; \
    apk update; \
    apk add --no-cache \
    wget tar bzip2 xz perl openssl libressl gnupg tree \
    ca-certificates coreutils dpkg tzdata\
    libedit libxml2 pcre; \
    set +x; \
    echo "## }"
    
# }

# Check&reconfigure Apache HTTPD installation {

#TEST {
RUN echo "## HTTPD installed files {"; \
	tree  -a -F -L 4 "${HTTPD_PREFIX}"; \
    echo "## }"
# }

COPY "${MY_SRC_PATH_PREFIX}httpd-foreground" "/usr/local/bin/"
ENV HTTPD_CONF_DIR "${HTTPD_PREFIX}/conf"
ENV HTTPD_CONF_D_DIR "${HTTPD_PREFIX}/conf.d"
ENV HTTPD_PID_DIR "${HTTPD_PREFIX}/logs"
#"/var/run/httpd"
ENV HTTPD_LOG_DIR "${HTTPD_PREFIX}/logs"
# "/var/log/httpd"
ENV HTTPD_ORIG_WWW_ROOT "${HTTPD_PREFIX}/htdocs"
ENV WWW_ROOT "/var/www/html"

RUN echo "## Checking&Configuring HTTPD v${HTTPD_VERSION} {"; \
    set -x; \
    set |grep HTTPD; \
    sed -ri \
        -e "s/^(\\s*Listen)\\s+(.+)$/\\1 ${HTTP_PORT}/g" \
        -e 's!^(\s*User)\s+(.+)$!\1 www-data!g' \
        -e 's!^(\s*Group)\s+(.+)$!\1 www-data!g' \
        -e "s|^(\\s*DocumentRoot)\\s+(.+)$|\\1 ${WWW_ROOT}|g" \
        -e "s|^(\\s*<Directory)\\s+\\\"${HTTPD_ORIG_WWW_ROOT}\\\">$|\\1 \\\"${WWW_ROOT}\\\">|g" \
        -e 's!^(\s*)#(\s*LoadModule)\s+((rewrite|proxy|proxy_http|proxy_http2|proxy_fcgi|session|session_cookie|session_crypto)_module)\s+(.+)$!\1\2 \3 \5!g' \
        "${HTTPD_CONF_DIR}/httpd.conf"; \
    \
    echo "Include ${HTTPD_CONF_D_DIR}/*.conf" >>"${HTTPD_CONF_DIR}/httpd.conf"; \
    mkdir -p "${HTTPD_CONF_D_DIR}"; \
    chown -v www-data:root /usr/local/bin/httpd-foreground; \
    chmod -v 755 /usr/local/bin/httpd-foreground; \
    chown -R www-data:root ${HTTPD_PREFIX}; \
    chmod -v 775 "${HTTPD_PREFIX}"; \
    mkdir -p "${HTTPD_PID_DIR}"; \
    chown -R www-data:root "${HTTPD_PID_DIR}"; \
    chmod -v 775 "${HTTPD_PID_DIR}"; \
    mkdir -p "${HTTPD_LOG_DIR}"; \
    chown -R www-data:root "${HTTPD_LOG_DIR}"; \
    chmod -v 775 "${HTTPD_LOG_DIR}"; \
    mkdir -p "${WWW_ROOT}"; \
    if [ "${HTTPD_ORIG_WWW_ROOT}" != "${WWW_ROOT}" ]; then \
        cp -vR "${HTTPD_ORIG_WWW_ROOT}"/* "${WWW_ROOT}/"; \
    fi; \
    chown -R www-data:root "${WWW_ROOT}"; \
    chmod -v 775 "${WWW_ROOT}"; \
    httpd -t; \
    set +x; \
    echo "## }"
#TEST {
RUN echo "## HTTPD Config files {"; \
    tree -a -F -L 4 "${HTTPD_CONF_DIR}"; \
    tree -a -F -L 4 "${HTTPD_CONF_D_DIR}"; \
    echo "## }"; \
    echo "## HTTPD config summary {"; \
    HTTPD_MAIN_CONF="${HTTPD_CONF_DIR}/httpd.conf"; \
    cat "${HTTPD_MAIN_CONF}" |grep -iE '^(\s*Listen)\s+'; \
    cat "${HTTPD_MAIN_CONF}" |grep -iE  '^(\s*ServerName)\s+'; \
    cat "${HTTPD_MAIN_CONF}" |grep -iE  '^(\s*ServerRoot)\s+'; \
    cat "${HTTPD_MAIN_CONF}" |grep -iE  '^(\s*DocumentRoot)\s+'; \
    cat "${HTTPD_MAIN_CONF}" |grep -iE  '^(\s*User)\s+'; \
    cat "${HTTPD_MAIN_CONF}" |grep -iE  '^(\s*Group)\s+'; \
    cat "${HTTPD_MAIN_CONF}" |grep -iE  '^(\s*Proxy)\s+'; \
    cat "${HTTPD_MAIN_CONF}" |grep -iE  '^(\s*CustomLog)\s+'; \
    cat "${HTTPD_MAIN_CONF}" |grep -iE  '^(\s*ErrorLog)\s+'; \
    cat "${HTTPD_MAIN_CONF}" |grep -iE  '^(\s*LoadModule)\s+'; \
    cat "${HTTPD_MAIN_CONF}" |grep -iE  '^(\s*Include)\s+'; \
    echo "## }"
# }

RUN set -x; \
    id www-data; \
    #addgroup -g 82 -S www-data; \
    #adduser -u 82 -D -S -G www-data www-data; \
    echo '%www-data ALL=(ALL) NOPASSWD:ALL' >>/etc/sudoers

# }

# Build&Install PHP

# References: 
# - https://github.com/docker-library/php/blob/3cb02a21164bc2bdb8b25ec48886ffcb7e195510/7.0/alpine/Dockerfile
# - https://github.com/docker-library/php/blob/85af0c14e3f23689f0851d3164ab3b630e7f016f/7.2/alpine3.7/fpm/Dockerfile


RUN mkdir -p /usr/src

WORKDIR /usr/src

# Install build tools {

RUN echo "## Installing build tools {"; \
    buildDeps=' \
        gcc g++ autoconf make patch \
        libc-dev \
        dpkg-dev \
        # mod_session_crypto \
        libressl \
        libressl-dev \
        # mod_proxy_html mod_xml2enc \
        libxml2-dev \
        # mod_lua \
        lua-dev \
        # mod_http2 \
        # mod_deflate \
        nghttp2-dev \
        pcre-dev libedit-dev \
        bzip2-dev zlib-dev curl-dev \
        libressl-dev \
        libsodium-dev \
        apr-dev \
        apr-util-dev \
    '; \
    echo "buildDeps: ${buildDeps}"; \
    set -x; \
    apk add --no-cache --virtual .build-deps $buildDeps; \
    set +x; \
    echo "## }"
    
# }


# Install PHP7 from source {

#WORKDIR /usr/src

# SHA for .tar.xz :
# "53ba0708be8a7db44256e3ae9fcecc91b811e5b5119e6080c951ffe7910ffb0f"
ENV PHP_MD5=""

ENV PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O2"
ENV PHP_CPPFLAGS="$PHP_CFLAGS"
ENV PHP_LDFLAGS="-Wl,-O1 -Wl,--hash-style=both -pie"
ENV PHP_GPG_KEYS 1729F83938DA44E27BA0F4D3DBDB397470D12172 B1B44D8F021E4E2D6021E995DC9FF8D3EE5AF27F

ENV PHP_BASE_DIR "/opt/php-${PHP_VERSION}"
ENV PHP_CONF_DIR "${PHP_BASE_DIR}/etc"
ENV PHP_CONF_D_DIR "${PHP_BASE_DIR}/etc/conf.d"
ENV PHP_PID_DIR "${PHP_BASE_DIR}/var/run"
ENV PHP_LOG_DIR "${PHP_BASE_DIR}/var/log"
ENV PHP_SESSIONS_DIR="/var/lib/php/session"
#ENV PHP_INI_DIR "${PHP_BASE_DIR}/lib"
ENV PHP_BIN_DIR "${PHP_BASE_DIR}/bin"
ENV PHPFPM_BIN_DIR "${PHP_BASE_DIR}/sbin"

RUN echo "## Downloading sources: PHP v${PHP_VERSION} {"; \
    set -ex; \
    wget "${PHP_BASE_URL}/get/php-${PHP_VERSION}.tar.gz/from/this/mirror" -O "php-${PHP_VERSION}.tar.gz"; \
    if [ -n "$PHP_SHA256" ]; then \
        echo "$PHP_SHA256 *php-${PHP_VERSION}.tar.gz" | sha256sum -c -; \
    fi; \
    if [ -n "$PHP_MD5" ]; then \
        echo "$PHP_MD5 *php-${PHP_VERSION}.tar.gz" | md5sum -c -; \
    fi; \
    if [ -n "$PHP_ASC_URL" ]; then \
        wget "${PHP_BASE_URL}/get/php-${PHP_VERSION}.tar.gz.asc/from/this/mirror" -O "php-${PHP_VERSION}.tar.gz.asc" && \
	export GNUPGHOME="$(mktemp -d)"; \
        for key in $PHP_GPG_KEYS; do \
            gpg --keyserver p80.pool.sks-keyservers.net:80 --recv-keys "$key"; \
        done; \
        gpg --batch --verify php-${PHP_VERSION}.tar.gz.asc php-${PHP_VERSION}.tar.gz; \
        command -v gpgconf > /dev/null && gpgconf --kill all; \
        rm -fR "$GNUPGHOME"; \
    fi; \
    tar -xzf php-${PHP_VERSION}.tar.gz; \
    mkdir -p ${PHP_BASE_DIR}; \
    mkdir -p "${PHP_CONF_DIR}"; \
    mkdir -p "${PHP_CONF_D_DIR}"; \
    #mkdir -p ${PHP_PID_DIR}; \
    #mkdir -p ${PHP_LOG_DIR}; \
    set +x; \
    echo "## }"

RUN echo "## Building: PHP v${PHP_VERSION} {"; \
    runDeps=' \
        libedit \
        libxml2 \
    '; \
    gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
    export CFLAGS="$PHP_CFLAGS" \
        CPPFLAGS="$PHP_CPPFLAGS" \
        LDFLAGS="$PHP_LDFLAGS"; \
    set -x; \
    apk add --virtual $runDeps; \
    cd php-${PHP_VERSION}; \
    ./configure \
        --prefix="${PHP_BASE_DIR}" \
        --build="$gnuArch" \
        --with-config-file-path="${PHP_CONF_DIR}" \
	--with-config-file-scan-dir="${PHP_CONF_D_DIR}" \
        --enable-option-checking=fatal \
        --disable-cgi \
# https://github.com/docker-library/php/issues/439
        --with-mhash \
# --enable-ftp is included here because ftp_ssl_connect() needs ftp to be compiled statically (see https://github.com/docker-library/php/issues/236)
        --enable-ftp \
# --enable-mbstring is included here because otherwise there's no way to get pecl to use it properly (see https://github.com/docker-library/php/issues/195)
        --enable-mbstring \
# --enable-mysqlnd is included here because it's harder to compile after the fact than extensions are (since it's a plugin for several extensions, not an extension in itself)
        --enable-mysqlnd \
# https://wiki.php.net/rfc/libsodium
        --with-sodium=shared \
	--with-curl \
	--with-libedit \
	--with-openssl \
	--with-zlib \
        --enable-fpm  --with-fpm-user=www-data --with-fpm-group=www-data \
        --enable-opcache \
# bundled pcre does not support JIT on s390x
# https://manpages.debian.org/stretch/libpcre3-dev/pcrejit.3.en.html#AVAILABILITY_OF_JIT_SUPPORT
        $(test "$gnuArch" = 's390x-linux-gnu' && echo '--without-pcre-jit') \
	${PHP_EXTRA_CONFIGURE_ARGS} && \
    make -j "$(getconf _NPROCESSORS_ONLN)" && \
    make install; \
    { find /usr/local/bin /usr/local/sbin -type f -perm +0111 -exec strip --strip-all '{}' + || true; }; \
    make clean; \
    runDeps="${runDeps} $( \
        scanelf --needed --nobanner --recursive /usr/local \
            | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
            | sort -u \
            | xargs -r apk info --installed \
            | sort -u \
    )"; \
    apk add --no-cache --virtual .php-rundeps $runDeps; \
    set +x; \
    echo "## }"
    
#TEST {
RUN echo "## PHP installed files {"; \
    tree -a -F -L 4 "${PHP_BASE_DIR}"; \
    echo "## }"
# }
   
# Set configurations for Apache HTTPD & PHP/FPM {
# Reference: https://github.com/smrutiranjantripathy/alpine-apache-php-fpm
 
COPY ${MY_SRC_PATH_PREFIX}00-httpd-fpm.conf "${HTTPD_CONF_D_DIR}/"
COPY ${MY_SRC_PATH_PREFIX}www.conf "${PHP_CONF_DIR}/php-fpm.d/"

RUN echo "## Post-build: PHP v${PHP_VERSION} {"; \
    set -x; \
    cd php-${PHP_VERSION}; \
    # { find /usr/local/bin /usr/local/sbin -type f -perm +0111 -exec strip --strip-all '{}' + || true; } \
    cp -v php.ini-production ${PHP_CONF_DIR}/php.ini; \
    cp -v ${PHP_CONF_DIR}/php-fpm.conf.default "${PHP_CONF_DIR}/php-fpm.conf"; \
    #cp -v ${PHP_CONF_DIR}/php-fpm.d/www.conf.default "${PHP_CONF_DIR}/php-fpm.d/www.conf"; \
    make clean; \
    #cd ..; \
    sed -ri \
        -e 's!^;\s*error_log\s*=\s*(.+)$!error_log = /proc/self/fd/2!g' \
        "${PHP_CONF_DIR}/php-fpm.conf"; \
    \
    chown -vR www-data:root "${PHP_BIN_DIR}"; \
    chmod -v 755 "${PHP_BIN_DIR}"/*; \
    chown -vR www-data:root "${PHPFPM_BIN_DIR}"; \
    chmod -v 755 "${PHPFPM_BIN_DIR}/php-fpm"; \
    chown -R www-data:root "${PHP_BASE_DIR}"; \
    chown -R www-data:root "${PHP_PID_DIR}"; \
    chmod -v 775 "${PHP_PID_DIR}"; \
    chown -R www-data:root "${PHP_LOG_DIR}"; \
    chmod -v 775 "${PHP_LOG_DIR}"; \
    mkdir -p "${PHP_SESSIONS_DIR}"; \
    chown -R www-data:root "${PHP_SESSIONS_DIR}"; \
    chmod -v 777 "${PHP_SESSIONS_DIR}"; \
    set +x; \
    echo "## }"

# }
#TEST {

RUN echo "## PHP config files {"; \
    tree -a -F -L 4 "${PHP_CONF_DIR}"; \
    tree -a -F -L 4 "${PHP_CONF_D_DIR}"; \
    echo "## }"; \
    echo "## PHP config summary {"; \
    PHP_INI_CONF="${PHP_CONF_DIR}/php.ini"; \
    echo "[${PHP_INI_CONF}]"; \
        cat "${PHP_INI_CONF}" |grep -iE '^(\s*display_errors)\s*\='; \
        cat "${PHP_INI_CONF}" |grep -iE '^(\s*error_reporting)\s*\='; \
        cat "${PHP_INI_CONF}" |grep -iE '^(\s*log_error)\s*\='; \
        cat "${PHP_INI_CONF}" |grep -iE '^(\s*error_log)\s*\='; \
        cat "${PHP_INI_CONF}" |grep -iE '^(\s*extension)\s*\='; \
    PHPFPM_MAIN_CONF="${PHP_CONF_DIR}/php-fpm.conf"; \
    echo "[${PHPFPM_MAIN_CONF}]"; \
        cat "${PHPFPM_MAIN_CONF}" |grep -iE '^(\s*error_log)\s*\='; \
        cat "${PHPFPM_MAIN_CONF}" |grep -iE '^(\s*user)\s*\='; \
        cat "${PHPFPM_MAIN_CONF}" |grep -iE '^(\s*group)\s*\='; \
    PHPFPM_WWW_CONF="${PHP_CONF_DIR}/php-fpm.d/www.conf"; \
    echo "[${PHPFPM_WWW_CONF}]"; \
        cat "${PHPFPM_WWW_CONF}" |grep -iE '^(\s*access\.log)\s*\='; \
        cat "${PHPFPM_WWW_CONF}" |grep -iE '^(\s*slowlog)\s*\='; \
    echo "## }"

# }

RUN echo "## Cleaning up {"; \
    set -x; \
    rm -fR php-${PHP_VERSION}; \
    rm -f php-${PHP_VERSION}.tar.gz; \
    apk del .build-deps; \
    set +x; \
    echo "## }"
    
# Install additional tools {
# traceroute for Alpine is in package: iputils
RUN echo "## Installing extra tools {"; \
    set -x; \
    apk add --no-cache \
    curl nano vim net-tools iputils; \
    set +x; \
    echo "## }"
    
# }

ENV PATH "${PHP_BIN_DIR}:${PHPFPM_BIN_DIR}:${PATH}"

WORKDIR ${HTTPD_PREFIX}

EXPOSE ${HTTP_PORT}

#USER www-data

CMD ["httpd-foreground"]
