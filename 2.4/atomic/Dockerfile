FROM registry.access.redhat.com/rhel7-atomic:latest
MAINTAINER chakrit_w@icloud.com

LABEL name=httpd-2.4-php7-atomic
LABEL version=1.0.0
LABEL author=chakrit_w@icloud.com

ARG HTTPD_EXTRA_CONFIGURE_ARGS=""
ARG PHP_EXTRA_CONFIGURE_ARGS=""
ARG SRC_PATH_PREFIX="2.4/atomic/"

USER 0

# Install prerequisite tools {

RUN microdnf update; \
    # microdnf check-update --security
    microdnf --enablerepo=rhel-7-server-rpms \
    install -y sudo wget tar bzip2 perl openssl gnupg;
    wget http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    # rpm -ivh epel-release-latest-7.noarch.rpm
    
# }

# Install build tools {

RUN set -eux; \
    buildDeps=' \
        gcc-c++ gcc libstdc++ libgcc glibc make python
    '; \
    microdnf --enablerepo=rhel-7-server-rpms \
    install -y $buildDeps \
    libselinux-utils systemd-sysv scl-utils policycoreutils-python \
    libedit libX11 tcl procps-ng

# }

RUN groupadd docker \
    && useradd -r -u 1001 -g docker docker \
    && echo '%docker ALL=(ALL) NOPASSWD:ALL' >>/etc/sudoers

# Install Apache HTTPD {

ENV HTTPD_PREFIX /usr/local/apache2
ENV PATH $HTTPD_PREFIX/bin:$PATH

RUN mkdir -p "${HTTPD_PREFIX}" \
    && chown docker:docker "$HTTPD_PREFIX"

WORKDIR ${HTTPD_PREFIX}
ENV HTTPD_VERSION 2.4.33
ENV HTTPD_SHA256 de02511859b00d17845b9abdd1f975d5ccb5d0b280c567da5bf2ad4b70846f05

# https://httpd.apache.org/security/vulnerabilities_24.html
ENV HTTPD_PATCHES=""
RUN microdnf --enablerepo=rhel-7-server-rpms \
    install -y httpd

COPY ${SRC_PATH_PREFIX}httpd-foreground /usr/local/bin/

RUN chown docker:docker /usr/local/bin/httpd-foreground; \
    chmod 755 /usr/local/bin/httpd-foreground; \
    chown -R docker:docker ${HTTPD_PREFIX}

# }

# Install PHP 7.2 {

WORKDIR /

RUN wget http://rpms.remirepo.net/enterprise/remi-release-7.rpm \
    && rpm -ivh remi-release-7.rpm \
    && microdnf --enablerepo=remi-php72 \
    install -y php72 php72-php-fpm

RUN sed -rie 's|;error_log = log/php7/error.log|error_log = /dev/stderr|g' ${PHP_BASE_DIR}/etc/php-fpm.conf
COPY ${SRC_PATH_PREFIX}www.conf ${PHP_BASE_DIR}/etc/php-fpm.d/

RUN chown docker:docker /usr/bin/php-fpm; \
    chmod 755 /usr/bin/php-fpm; \
    chown -R docker:docker ${PHP_BASE_DIR}

# }

RUN \
    #microdnf remove $buildDeps; \
    microdnf clean all

# Set configurations for Apache HTTPD & PHP/FPM {
# Reference: https://github.com/smrutiranjantripathy/alpine-apache-php-fpm

COPY ${SRC_PATH_PREFIX}00-httpd-fpm.conf ${HTTPD_PREFIX}/etc/conf.d/

# }

# Install additional tools {

RUN microdnf --enablerepo=rhel-7-server-rpms \
    install -y curl nano vim net-tools traceroute
    
# }

WORKDIR ${HTTPD_PREFIX}

EXPOSE 80

USER docker

CMD ["httpd-foreground"]
