FROM alpine:3.7

# ensure www-data user exists
RUN set -x \
	&& addgroup -g 82 -S www-data \
	&& adduser -u 82 -D -S -G www-data www-data
# 82 is the standard uid/gid for "www-data" in Alpine
# http://git.alpinelinux.org/cgit/aports/tree/main/apache2/apache2.pre-install?h=v3.3.2
# http://git.alpinelinux.org/cgit/aports/tree/main/lighttpd/lighttpd.pre-install?h=v3.3.2
# http://git.alpinelinux.org/cgit/aports/tree/main/nginx-initscripts/nginx-initscripts.pre-install?h=v3.3.2

WORKDIR /usr/src

ENV HTTPD_VERSION 2.4.33
ENV HTTPD_SHA256 de02511859b00d17845b9abdd1f975d5ccb5d0b280c567da5bf2ad4b70846f05

#ENV HTTPD_PREFIX /usr/local/apache2
ENV HTTPD_PREFIX /opt/apache/httpd-${HTTPD_VERSION}
ENV PATH $HTTPD_PREFIX/bin:$PATH
RUN mkdir -p "$HTTPD_PREFIX" \
	&& chown www-data:www-data "$HTTPD_PREFIX"
    
# https://httpd.apache.org/security/vulnerabilities_24.html
ENV HTTPD_PATCHES=""

ENV APACHE_DIST_URLS \
# https://issues.apache.org/jira/browse/INFRA-8753?focusedCommentId=14735394#comment-14735394
	https://www.apache.org/dyn/closer.cgi?action=download&filename= \
# if the version is outdated (or we're grabbing the .asc file), we might have to pull from the dist/archive :/
	https://www-us.apache.org/dist/ \
	https://www.apache.org/dist/ \
	https://archive.apache.org/dist/

# see https://httpd.apache.org/docs/2.4/install.html#requirements
RUN set -eux; \
	\
	runDeps=' \
		apr-dev \
		apr-util-dev \
		apr-util-ldap \
		tar bzip2 perl \
                wget curl nano vim \
	'; \
	apk add --no-cache --virtual .build-deps \
		$runDeps \
		ca-certificates \
		coreutils \
		dpkg-dev dpkg \
		gcc g++ autoconf make patch \
		gnupg \
		libc-dev \
		# mod_session_crypto
		libressl \
		libressl-dev \
		# mod_proxy_html mod_xml2enc
		libxml2-dev \
		# mod_lua
		lua-dev \
		make \
		# mod_http2
		nghttp2-dev \
		pcre-dev \
		bzip2-dev \
		# mod_deflate
		zlib-dev \
	; \
	\
	ddist() { \
		local f="$1"; shift; \
		local distFile="$1"; shift; \
		local success=; \
		local distUrl=; \
		for distUrl in $APACHE_DIST_URLS; do \
			if wget -O "$f" "$distUrl$distFile" && [ -s "$f" ]; then \
				success=1; \
				break; \
			fi; \
		done; \
		[ -n "$success" ]; \
	}; \
	\
	ddist 'httpd.tar.bz2' "httpd/httpd-$HTTPD_VERSION.tar.bz2"; \
	echo "$HTTPD_SHA256 *httpd.tar.bz2" | sha256sum -c -; \
	\
# see https://httpd.apache.org/download.cgi#verify
	ddist 'httpd.tar.bz2.asc' "httpd/httpd-$HTTPD_VERSION.tar.bz2.asc"; \
	export GNUPGHOME="$(mktemp -d)"; \
	for key in \
# gpg: key 791485A8: public key "Jim Jagielski (Release Signing Key) <jim@apache.org>" imported
		A93D62ECC3C8EA12DB220EC934EA76E6791485A8 \
# gpg: key 995E35221AD84DFF: public key "Daniel Ruggeri (http://home.apache.org/~druggeri/) <druggeri@apache.org>" imported
		B9E8213AEFB861AF35A41F2C995E35221AD84DFF \
	; do \
            # Workaround for keyserver issue {
            ( gpg --keyserver p80.pool.sks-keyservers.net:80 --recv-keys "$key" \
              || gpg --keyserver pgp.mit.edu --recv-keys "$key" \
              || gpg --keyserver keyserver.pgp.com --recv-keys "$key" ) \
            # }
	done; \
	gpg --batch --verify httpd.tar.bz2.asc httpd.tar.bz2; \
	rm -rf "$GNUPGHOME" httpd.tar.bz2.asc; \
	mkdir -p httpd-${HTTPD_VERSION}; \
	tar -xf httpd.tar.bz2 -C httpd-${HTTPD_VERSION} --strip-components=1; \
	rm httpd.tar.bz2; \
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
	\
	gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
	./configure \
		--build="$gnuArch" \
		--prefix="$HTTPD_PREFIX" \
		--enable-mods-shared=reallyall \
		--enable-mpms-shared=all \
	; \
	make -j "$(nproc)"; \
	make install; \
	\
	cd ..; \
	#rm -r src man manual; \
	\
	sed -ri \
		-e 's!^(\s*CustomLog)\s+\S+!\1 /proc/self/fd/1!g' \
		-e 's!^(\s*ErrorLog)\s+\S+!\1 /proc/self/fd/2!g' \
		"$HTTPD_PREFIX/conf/httpd.conf"; \
	\
	runDeps="$runDeps $( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)"; \
	apk add --virtual .httpd-rundeps $runDeps;
	# apk del .build-deps

COPY httpd-foreground /usr/local/bin/

# Install PHP7 from source {
#WORKDIR /usr/src

ENV PHP_VERSION 7.2.7
ENV PHP_MIRROR "ca1.php.net"
ENV PHP_BUILD_CONFIG "--prefix=/opt/php-${PHP_VERSION} --with-pdo-pgsql --with-zlib-dir --with-freetype-dir --enable-mbstring --with-libxml-dir=/usr --enable-soap --enable-calendar --with-curl --with-zlib --with-gd --with-pgsql --disable-rpath --enable-inline-optimization --with-bz2 --with-zlib --enable-sockets --enable-sysvsem --enable-sysvshm --enable-pcntl --enable-mbregex --enable-exif --enable-bcmath --with-mhash --enable-zip --with-pcre-regex --with-pdo-mysql --with-mysqli --with-mysql-sock=/var/run/mysqld/mysqld.sock --with-jpeg-dir=/usr --with-png-dir=/usr --with-openssl --with-fpm-user=www-data --with-fpm-group=www-data --with-libdir=/lib/x86_64-linux-gnu --enable-ftp --with-imap --with-imap-ssl --with-kerberos --with-gettext --with-xmlrpc --with-xsl --enable-opcache --enable-fpm"

RUN wget http://${PHP_MIRROR}/get/php-${PHP_VERSION}.tar.gz/from/this/mirror -O php-${PHP_VERSION}.tar.gz \
    && tar -xzvf php-${PHP_VERSION}.tar.gz \
    && cd php-${PHP_VERSION} \
    && ./configure ${PHP_BUILD_CONFIG} \
    && make && make install \
    && cp php.ini-production /opt/php-${PHP_VERSION}/lib/php.ini \
    && cp /opt/php-${PHP_VERSION}/etc/php-fpm.conf.default /opt/php-${PHP_VERSION}/etc/php-fpm.conf \
    && cp /opt/php-${PHP_VERSION}/etc/php-fpm.d/www.conf.default /opt/php-${PHP_VERSION}/etc/php-fpm.d/www.conf
    
# }

RUN apk del .build-deps

WORKDIR ${HTTPD_PREFIX}

EXPOSE 80

USER www-data

CMD ["httpd-foreground"]
