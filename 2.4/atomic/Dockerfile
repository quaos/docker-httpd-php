FROM registry.access.redhat.com/rhel7-atomic:latest
MAINTAINER chakrit_w@icloud.com

USER 0

RUN microdnf update
# && microdnf check-update --security

# Install repos & tools
RUN microdnf --enablerepo=rhel-7-server-rpms \
    install -y sudo gcc-c++ gcc libstdc++ libgcc make \
    gnupg tar curl wget openssl \
    && wget http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
    && rpm -ivh epel-release-latest-7.noarch.rpm \
    && microdnf --enablerepo=rhel-7-server-rpms \
    install -y sudo nano vim curl net-tools traceroute python

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

#TODO:   
#COPY httpd-config/* /etc/httpd/
    
# }

# Install PHP 7.2 {

WORKDIR /

RUN wget http://rpms.remirepo.net/enterprise/remi-release-7.rpm \
    && rpm -ivh remi-release-7.rpm \
    && microdnf --enablerepo=remi-php72 \
    install -y php72 php72-php-fpm
 
#TODO:   
#COPY php-config/* /etc/php72/

# }

RUN microdnf clean all

COPY httpd-foreground /usr/local/bin/

WORKDIR ${HTTPD_PREFIX}

EXPOSE 80

USER docker

CMD ["httpd-foreground"]
