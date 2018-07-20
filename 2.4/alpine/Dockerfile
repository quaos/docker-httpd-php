FROM alpine:3.7
MAINTAINER chakrit_w@icloud.com

LABEL name=httpd-2.4-php7-alpine
LABEL version=1.0.0
LABEL author=chakrit_w@icloud.com

ARG HTTPD_EXTRA_CONFIGURE_ARGS=""
ARG PHP_EXTRA_CONFIGURE_ARGS=""
ARG SRC_PATH_PREFIX=""
#"2.4/alpine/"
ARG HTTP_PORT=8080

# ensure www-data user exists
RUN set -x; \
	addgroup -g 82 -S www-data; \
	adduser -u 82 -D -S -G www-data www-data; \
        echo '%www-data ALL=(ALL) NOPASSWD:ALL' >>/etc/sudoers
    
# 82 is the standard uid/gid for "www-data" in Alpine
# http://git.alpinelinux.org/cgit/aports/tree/main/apache2/apache2.pre-install?h=v3.3.2
# http://git.alpinelinux.org/cgit/aports/tree/main/lighttpd/lighttpd.pre-install?h=v3.3.2
# http://git.alpinelinux.org/cgit/aports/tree/main/nginx-initscripts/nginx-initscripts.pre-install?h=v3.3.2

# Install prerequisite tools {
RUN echo "## Installing prerequisites {"; \
    apk update; \
    apk add --no-cache \
    wget tar bzip2 perl openssl gnupg tree \
    ca-certificates coreutils dpkg; \
    echo "## }"
    
# }

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
        apr-dev \
        apr-util-dev \
    '; \
    echo "buildDeps: ${buildDeps}"; \
    apk add --no-cache --virtual .build-deps $buildDeps; \
    echo "## }"
    
# }

# Install Apache HTTPD {

ENV HTTPD_VERSION 2.4.33
ENV HTTPD_SHA256 de02511859b00d17845b9abdd1f975d5ccb5d0b280c567da5bf2ad4b70846f05

#ENV HTTPD_PREFIX /usr/local/apache2
ENV HTTPD_PREFIX /opt/apache/httpd-${HTTPD_VERSION}
ENV PATH $HTTPD_PREFIX/bin:$PATH
RUN mkdir -p "${HTTPD_PREFIX}" \
	&& chown www-data:root "${HTTPD_PREFIX}"
    
# https://httpd.apache.org/security/vulnerabilities_24.html
ENV HTTPD_PATCHES=""

# https://issues.apache.org/jira/browse/INFRA-8753?focusedCommentId=14735394#comment-14735394
ENV APACHE_DIST_URLS \
	https://www.apache.org/dyn/closer.cgi?action=download&filename= \
# if the version is outdated (or we're grabbing the .asc file), we might have to pull from the dist/archive :/
	https://www-us.apache.org/dist/ \
	https://www.apache.org/dist/ \
	https://archive.apache.org/dist/

# see https://httpd.apache.org/docs/2.4/install.html#requirements
RUN set -x; \
    echo "## Downloading sources: HTTPD v${HTTPD_VERSION} {"; \
    ddist() { \
            local f="$1"; shift; \
            local distFile="$1"; shift; \
            local success=""; \
            local distUrl=""; \
            echo "Downloading Apache HTTPD distribution from URLs: ${APACHE_DIST_URLS}"; \
            for distUrl in ${APACHE_DIST_URLS}; do \
                    if wget -O "$f" "$distUrl$distFile" && [ -s "$f" ]; then \
                            success=1; \
                            break; \
                    fi; \
            done; \
            [ -n "$success" ]; \
    }; \
    ddist "httpd-${HTTPD_VERSION}.tar.bz2" "httpd/httpd-${HTTPD_VERSION}.tar.bz2"; \
    echo "$HTTPD_SHA256 *httpd-${HTTPD_VERSION}.tar.bz2" | sha256sum -c -; \
# see https://httpd.apache.org/download.cgi#verify \
    ddist "httpd-${HTTPD_VERSION}.tar.bz2.asc" "httpd/httpd-${HTTPD_VERSION}.tar.bz2.asc"; \
    export GNUPGHOME="$(mktemp -d)"; \
    for key in \
# gpg: key 791485A8: public key "Jim Jagielski (Release Signing Key) <jim@apache.org>" imported
            A93D62ECC3C8EA12DB220EC934EA76E6791485A8 \
# gpg: key 995E35221AD84DFF: public key "Daniel Ruggeri (http://home.apache.org/~druggeri/) <druggeri@apache.org>" imported
            B9E8213AEFB861AF35A41F2C995E35221AD84DFF \
    ; do \
        # Workaround for keyserver issue { \
        ( gpg --keyserver p80.pool.sks-keyservers.net:80 --recv-keys "$key" \
          || gpg --keyserver pgp.mit.edu --recv-keys "$key" \
          || gpg --keyserver keyserver.pgp.com --recv-keys "$key" ) \
        # } \
    done; \
    gpg --batch --verify httpd-${HTTPD_VERSION}.tar.bz2.asc httpd-${HTTPD_VERSION}.tar.bz2; \
    rm -rf "$GNUPGHOME" httpd-${HTTPD_VERSION}.tar.bz2.asc; \
    \
    mkdir -p httpd-${HTTPD_VERSION} && \
    tar -xf httpd-${HTTPD_VERSION}.tar.bz2 -C httpd-${HTTPD_VERSION} --strip-components=1 && \
    rm httpd-${HTTPD_VERSION}.tar.bz2 && \
    cd httpd-${HTTPD_VERSION}; \
    patches() { \
            while [ "$#" -gt 0 ]; do \
                    local patchFile="$1"; shift; \
                    local patchSha256="$1"; shift; \
                    ddist "$patchFile" "httpd/patches/apply_to_$HTTPD_VERSION/$patchFile"; \
                    echo "$patchSha256 *$patchFile" | sha256sum -c -; \
                    patch -p0 < "$patchFile"; \
                    rm -f "$patchFile"; \
            done; \
    }; \
    patches $HTTPD_PATCHES; \
    echo "## }"
    
RUN echo "## Building: HTTPD v${HTTPD_VERSION} {"; \
    gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
    cd httpd-${HTTPD_VERSION}; \
    runDeps=' \
        apr-util \
        apr-util-ldap \
        perl \
    '; \
    apk add --virtual $runDeps; \
    ./configure \
        --build="$gnuArch" \
        --prefix="${HTTPD_PREFIX}" \
        --enable-mods-shared=reallyall \
        --enable-mpms-shared=all \
        --enable-proxy --enable-proxy-fcgi \
        ${HTTPD_EXTRA_CONFIGURE_ARGS} && \
    make -j "$(nproc)" && \
    make install; \
    runDeps="$runDeps $( \
        scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
            | tr ',' '\n' \
            | sort -u \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )"; \
    apk add --virtual .httpd-rundeps $runDeps; \
    echo "## }"
    
#TEST {
RUN echo "## HTTPD installed files {"; \
    tree -a -F -L 4 "${HTTPD_PREFIX}"; \
    echo "## }"
# }
    
COPY ${SRC_PATH_PREFIX}httpd-foreground /usr/local/bin/

ENV HTTPD_CONF_DIR "${HTTPD_PREFIX}/etc"
ENV HTTPD_CONF_D_DIR "${HTTPD_PREFIX}/etc/conf.d"
ENV HTTPD_PID_DIR "/var/run/httpd" 
ENV HTTPD_LOG_DIR "/var/log/httpd"

RUN echo "## Post-build: HTTPD v${HTTPD_VERSION} {"; \
    cd ..; \
    rm -r httpd-${HTTPD_VERSION}; \
    sed -ri \
            -e "s/^(\\s*Listen)\\s+(.+)$/\\1 ${HTTP_PORT}/g" \
            -e 's!^(\s*User)\s+(.+)$!\1 www-data!g' \
            -e 's!^(\s*Group)\s+(.+)$!\1 www-data!g' \
            -e 's!^(\s*CustomLog)\s+\S+!\1 /proc/self/fd/1!g' \
            -e 's!^(\s*ErrorLog)\s+\S+!\1 /proc/self/fd/2!g' \
            "${HTTPD_CONF_DIR}/httpd.conf"; \
    \
    chown -v www-data:root /usr/local/bin/httpd-foreground; \
    chmod -v 755 /usr/local/bin/httpd-foreground; \
    chown -vR www-data:root ${HTTPD_PREFIX}; \
    chmod -vR 775 "${HTTPD_PREFIX}"; \
    chown -vR www-data:root "${HTTPD_PID_DIR}"; \
    chmod -vR 775 "${HTTPD_PID_DIR}"; \
    chown -vR www-data:root "${HTTPD_LOG_DIR}"; \
    chmod -vR 775 "${HTTPD_LOG_DIR}"; \
    echo "## }"

# }

#TEST {
RUN echo "## HTTPD Config files {"; \
    tree -a -F -L 4 "${HTTPD_CONF_DIR}"; \
    tree -a -F -L 4 "${HTTPD_CONF_D_DIR}"; \
    echo "## }"
# }


# Install PHP7 from source {
# Reference: https://github.com/docker-library/php/blob/3cb02a21164bc2bdb8b25ec48886ffcb7e195510/7.0/alpine/Dockerfile

#WORKDIR /usr/src

ENV PHP_VERSION 7.2.7
ENV PHP_MIRROR "ca1.php.net"
ENV PHP_BASE_DIR "/opt/php-${PHP_VERSION}"
ENV PHP_CONF_DIR "${PHP_BASE_DIR}/etc"
ENV PHP_CONF_D_DIR "${PHP_BASE_DIR}/etc/conf.d"
ENV PHP_PID_DIR "${PHP_BASE_DIR}/var/run"
ENV PHP_LOG_DIR "${PHP_BASE_DIR}/var/log"
ENV PHP_SESSIONS_DIR="/var/lib/php/session"
#ENV PHP_INI_DIR "${PHP_BASE_DIR}/lib"
ENV PHPFPM_BIN_DIR "${PHP_BASE_DIR}/sbin"

RUN echo "## Downloading sources: PHP v${PHP_VERSION} {"; \
    wget http://${PHP_MIRROR}/get/php-${PHP_VERSION}.tar.gz/from/this/mirror -O php-${PHP_VERSION}.tar.gz && \
    tar -xzf php-${PHP_VERSION}.tar.gz; \
    mkdir -p ${PHP_BASE_DIR}; \
    #mkdir -p ${PHP_PID_DIR}; \
    #mkdir -p ${PHP_LOG_DIR}; \
    echo "## }"

RUN echo "## Building: PHP v${PHP_VERSION} {"; \
    cd php-${PHP_VERSION} && \
    ./configure \
        --prefix="${PHP_BASE_DIR}" \
        --with-config-file-path="${PHP_CONF_DIR}" \
	--with-config-file-scan-dir="${PHP_CONF_D_DIR}" \
        --disable-cgi \
    # --enable-ftp is included here because ftp_ssl_connect() needs ftp to be compiled statically (see https://github.com/docker-library/php/issues/236)
        --enable-ftp \
    # --enable-mbstring is included here because otherwise there's no way to get pecl to use it properly (see https://github.com/docker-library/php/issues/195)
        --enable-mbstring \
    # --enable-mysqlnd is included here because it's harder to compile after the fact than extensions are (since it's a plugin for several extensions, not an extension in itself)
        --enable-mysqlnd \
	--with-curl \
	--with-libedit \
	--with-openssl \
	--with-zlib \
        # --with-httpd24 \
        --enable-fpm  \
        --enable-opcache \
	${PHP_EXTRA_CONFIGURE_ARGS} && \
    make -j "$(getconf _NPROCESSORS_ONLN)" && \
    make install; \
    runDeps="$( \
        scanelf --needed --nobanner --recursive /usr/local \
            | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
            | sort -u \
            | xargs -r apk info --installed \
            | sort -u \
    )"; \
    apk add --no-cache --virtual .php-rundeps $runDeps; \
    echo "## }"
    

#TEST {
RUN echo "## PHP installed files {"; \
    tree -a -F -L 4 "${PHP_BASE_DIR}"; \
    echo "## }"
# }
    
COPY ${SRC_PATH_PREFIX}00-httpd-fpm.conf "${HTTPD_CONF_D_DIR}/"

RUN echo "## Post-build: PHP v${PHP_VERSION} {"; \
    cd php-${PHP_VERSION}; \
    # { find /usr/local/bin /usr/local/sbin -type f -perm +0111 -exec strip --strip-all '{}' + || true; } \
    cp -v php.ini-production ${PHP_CONF_DIR}/php.ini; \
    cp -v ${PHP_CONF_DIR}/php-fpm.conf.default "${PHP_CONF_DIR}/php-fpm.conf"; \
    cp -v ${PHP_CONF_DIR}/php-fpm.d/www.conf.default "${PHP_CONF_DIR}/php-fpm.d/www.conf"; \
    make clean; \
    cd ..; \
    rm -r php-${PHP_VERSION}; \
    sed -ri \
        -e 's!^;\s*error_log\s*=\s*(.+)$!error_log = /dev/stderr!g' \
        "${PHP_CONF_DIR}/php-fpm.conf"; \
    \
    chown -v www-data:root /usr/bin/php-fpm; \
    chmod -v 755 /usr/bin/php-fpm; \
    chown -vR www-data:root "${PHP_BASE_DIR}"; \
    chown -vR www-data:root "${PHP_PID_DIR}"; \
    chmod -vR 775 "${PHP_PID_DIR}"; \
    chown -vR www-data:root "${PHP_LOG_DIR}"; \
    chmod -vR 775 "${PHP_LOG_DIR}"; \
    mkdir -p "${PHP_SESSIONS_DIR}"; \
    chown -vR www-data:root "${PHP_SESSIONS_DIR}"; \
    chmod -vR 777 "${PHP_SESSIONS_DIR}"; \
    echo "## }"

# }

# Set configurations for Apache HTTPD & PHP/FPM {
# Reference: https://github.com/smrutiranjantripathy/alpine-apache-php-fpm

COPY ${SRC_PATH_PREFIX}www.conf ${PHP_BASE_DIR}/etc/php-fpm.d/

#TEST {
RUN echo "## PHP config files {"; \
    tree -a -F -L 4 "${PHP_CONF_DIR}"; \
    tree -a -F -L 4 "${PHP_CONF_D_DIR}"; \
    echo "## }"
# }
    

# }

RUN echo "## Uninstalling build tools {"; \
    apk del .build-deps; \
    echo "## }"
    
# Install additional tools {
# traceroute for Alpine is in package: iputils

RUN apk add --no-cache \
    curl nano vim net-tools iputils
    
# }

ENV PATH "${}:${PHPFPM_BIN_DIR}:${PATH}"

WORKDIR ${HTTPD_PREFIX}

EXPOSE ${HTTP_PORT}

#USER www-data

CMD ["httpd-foreground"]
