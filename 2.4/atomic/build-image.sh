# Install prerequisites
installPreReqs() {
    microdnf update
    # microdnf check-update --security
    microdnf --enablerepo=rhel-7-server-rpms \
    install -y sudo libselinux-utils systemd-sysv scl-utils policycoreutils-python
        
    groupadd docker \
        && useradd -r -u 1001 -g docker docker \
        && echo '%docker ALL=(ALL) NOPASSWD:ALL' >>/etc/sudoers
}

# Install build tools
installBuildTools() {
    set -eux
    echo "Installing build tools ..."
    buildDeps=' \
        gcc-c++ gcc libstdc++ libgcc glibc make python \
    '
    echo "buildDeps: ${buildDeps}"
    microdnf --enablerepo=rhel-7-server-rpms \
    install -y $buildDeps \
    libselinux-utils systemd-sysv scl-utils policycoreutils-python \
    libedit libX11 tcl procps-ng
}
# Uninstall build tools
uninstallBuildTools() {
    set -eux
    echo "Uninstalling build tools ..."
    microdnf remove $buildDeps
    microdnf clean all
}

# Install Apache HTTPD
installHttpd() {
    export HTTPD_VERSION=2.4
    export HTTPD_PREFIX=${HTTPD_PREFIX:/usr/local/apache2}
    export HTTPD_CONF_DIR=${HTTPD_CONF_DIR:/etc/httpd/conf}
    export HTTPD_CONF_D_DIR=${HTTPD_CONF_D_DIR:/etc/httpd/conf.d}
    export HTTPD_PID_DIR=${HTTPD_PID_DIR:/var/run/httpd}
    export HTTPD_LOG_DIR=${HTTPD_LOG_DIR:/var/log/httpd}
    export WWW_ROOT=${WWW_ROOT:/var/www/html}

    mkdir -p "${HTTPD_PREFIX}" \
        && chown docker:docker "$HTTPD_PREFIX"

    cd "${HTTPD_PREFIX}"
    HTTPD_SHA256=de02511859b00d17845b9abdd1f975d5ccb5d0b280c567da5bf2ad4b70846f05

    # https://httpd.apache.org/security/vulnerabilities_24.html
    HTTPD_PATCHES=""
    
    echo "Installing: HTTPD v${HTTPD_VERSION} ..."
    microdnf --enablerepo=rhel-7-server-rpms \
    install -y httpd

    #COPY ${SRC_PATH_PREFIX}httpd-foreground /usr/local/bin/

    echo "Post-install: HTTPD v${HTTPD_VERSION} ..."
    tree -a -F -L 4 ${HTTPD_PREFIX}
    sed -ri \
        -e 's!^(\s*User)\s+(.+)$!\1 docker!g' \
        -e 's!^(\s*Group)\s+(.+)$!\1 docker!g' \
        # -e 's!^;\s*DocumentRoot\s*(.+)$!DocumentRoot ${WWW_ROOT}!g'
        "${HTTPD_CONF_DIR}/httpd.conf"
    chown docker:docker /usr/local/bin/httpd-foreground
    chmod 755 /usr/local/bin/httpd-foreground
    chown -R docker:docker ${HTTPD_PREFIX}
    chown -R docker:docker ${HTTPD_CONF_DIR}
    chown -R docker:docker ${HTTPD_CONF_D_DIR}
    chown -R docker:docker ${HTTPD_PID_DIR}
    chown -R docker:docker ${HTTPD_LOG_DIR}
    
    export PATH=${HTTPD_PREFIX}/bin:$PATH
}

# Install PHP 7.2
installPhp() {
    export PHP_VERSION=${PHP_VERSION:7.2}
    export PHP_BASE_DIR=${PHP_BASE_DIR:/opt/remi/php72}
    export PHP_CONF_DIR=${PHP_CONF_DIR:/etc/opt/remi/php72}
    export PHP_PID_DIR=${HP_PID_DIR:/var/opt/remi/php72/run}
    export PHP_LOG_DIR=${PHP_LOG_DIR:/var/opt/remi/php72/log}
    export PHP_INI_DIR=${PHP_INI_DIR:${PHP_CONF_DIR}}
    export PHPFPM_BIN_DIR=${PHP_BASE_DIR}/root/usr/sbin

    #WORKDIR /

    echo "Installing: PHP v${PHP_VERSION} ..."
    wget http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    rpm -ivh epel-release-latest-7.noarch.rpm
    wget http://rpms.remirepo.net/enterprise/remi-release-7.rpm
    rpm -ivh remi-release-7.rpm
    microdnf --enablerepo=remi-php72 \
    install -y php72 php72-php-fpm
    
    #COPY ${SRC_PATH_PREFIX}www.conf ${PHP_CONF_DIR}/php-fpm.d/

    echo "Post-install: PHP v${PHP_VERSION} ..."
    #TEST {
    tree -a -F -L 4 ${PHP_BASE_DIR}
    # }
    #sed -rie 's|;error_log = log/php7/error.log|error_log = /dev/stderr|g' ${PHP_CONF_DIR}/php-fpm.conf
    sed -ri \
        -e 's!^;(\s*error_log)\s*=\s*(.+)$!\1 = /dev/stderr!g' \
        "${PHP_CONF_DIR}/php-fpm.conf"
    chown docker:docker ${PHPFPM_BIN_DIR}/php-fpm
    chmod 755 ${PHPFPM_BIN_DIR}/php-fpm
    chown -R docker:docker ${PHP_BASE_DIR}
    chown -R docker:docker ${PHP_CONF_DIR}
    chown -R docker:docker ${PHP_PID_DIR}
    chown -R docker:docker ${PHP_LOG_DIR}
    cd ${PHP_BASE_DIR}
    chmod 755 enable
    ./enable
}


# Set configurations for Apache HTTPD & PHP/FPM {
# Reference: https://github.com/smrutiranjantripathy/alpine-apache-php-fpm
#COPY ${SRC_PATH_PREFIX}00-httpd-fpm.conf ${HTTPD_CONF_D_DIR}/
initConfig() {
}

# Install additional tools
installExtraTools() {
    microdnf --enablerepo=rhel-7-server-rpms \
        install -y curl nano vim net-tools traceroute
}

cleanup() {
    uninstallBuildTools()
}

case $1 in

all)
    installPreReqs()
    installBuildTools()
    installHttpd()
    installPhp()
    initConfig()
    installExtraTools()
    cleanup()
    ;;
prereqs)
    installPreReqs()
    ;;
build-tools)
    installBuildTools()
    ;;
httpd)
    installHttpd()
    ;;
php)
    installPhp()
    ;;
config)
    initConfig()
    ;;
extra-tools)
    installExtraTools()
    ;;
cleanup)
    cleanup()
    ;;
*)
    echo "usage: build-image.sh (all|prereqs|build-tools|httpd|php|config|extra-tools|cleanup)"
    exit -1;
esac
