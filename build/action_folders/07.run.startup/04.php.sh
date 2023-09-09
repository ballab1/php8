#!/bin/bash

: ${WWW_UID:?"Environment variable 'WWW_UID' not defined in '${BASH_SOURCE[0]}'"}

declare iniFile="/etc/${PHP}/php.ini"
term.log "    updating '$iniFile' with 'open_basedir = ${WWW}'\n" 'white'
sed -i -e "s|^.*date.timezone\s*=.*$|date.timezone = ${TZ}|" \
       -e "s|^.*session.save_path\s*=.*$|session.save_path = \"${SESSIONS_DIR}\"|" \
       -e "s|^.*open_basedir\s*=.*$|open_basedir = ${WWW}/:/tmp/:/etc/phpmyadmin/|" "$iniFile"


declare cnfFile="/etc/${PHP}/php-fpm.conf"
term.log "    updating '$cnfFile' with 'chdir = ${WWW}'\n" 'white'
sed -i -e "s|^listen\s*=.*$|listen=${RUN_DIR}/php-fpm.sock|"  \
       -e "s|^.*user\s*=.*$|user = ${WWW_USER}|" \
       -e "s|^.*group\s*=.*$|group = ${WWW_GROUP}|" \
       -e "s|^.*chdir\s*=.*$|chdir = ${WWW}|" \
       -e "s|^.*error_log\s*=.*$|error_log = /var/log/php82-fpm.log|" \
          "$cnfFile"

cnfFile="/etc/supervisor.d/php-fpm.ini"
term.log "    updating '$cnfFile' with 'chdir = ${WWW}'\n" 'white'
sed -i -e "s|^stdout_logfile\s*=.*$|stdout_logfile=/var/log/php82-fpm.log|"  \
          "$cnfFile"

cnfFile="/etc/supervisord/fcgiwrap.ini"
term.log "    updating '$cnfFile' with 'server = socket=unix:${RUN_DIR}/fcgiwrap.sock'\n" 'white'
sed -i -e "s|^server\s*=\s*unix:.*$|server=unix:${RUN_DIR}/fcgiwrap.sock|"  \
          "$cnfFile"


sed -i "s|^\s*server\s+.*$|    server unix:${RUN_DIR}/php-fpm.sock;|"  /etc/nginx/conf.d/php_fpm.upstream

# move the phpinfo.php to new WWW folder so we can access it
if [ "$WWW" != /var/www ] && [ -d /var/www/phpinfo ]; then
    mv /var/www/phpinfo "$WWW"
    chown -R "$WWW_UID" "${WWW}/phpinfo"
fi

crf.fixupDirectory "$RUN_DIR" "$WWW_UID"
crf.fixupDirectory "$SESSIONS_DIR" "$WWW_UID"


cnfFile="/etc/${PHP}/conf/xdebug.ini"
if [ -f /var/log/.nginx.debug ] &&  [ -e "$cnfFile" ] ; then
    term.log "    updating '${__file}' to run DEBUG version of '${PHP^^}'\n" 'white'
    sed -Ei \
        -e "s|^.*zend_extension=xdebug.so$|zend_extension=xdebug.so|" \
           "$__file"
fi

if [ "${PHP_LOGGING:-}" ];then
    declare cfgFile='/etc/php82/php.ini'
    term.log "    updating '${cfgFile}' with provided 'LOG_LEVEL'"'\n' 'white'

    if [ "$PHP_LOGGING" = 0 ]; then
        sed -i -E -e "s|^(error_reporting\s*=\s*).*$|\E_ALL & ~E_DEPRECATED & ~E_STRICT|g" \
                  -e "s|^(display_errors\s*=\s*).*$|\1Off|g" \
                  -e "s|^(display_startup_errors\s*=\s*).*$|\1Off|g" \
                  -e "s|^(log_errors\s*=\s*).*$|\1Off|g" \
                  -e "s|^(track_errors\s*=\s*).*$|\1Off|g" \
                  -e "s|^(html_errors\s*=\s*).*$|\1Off|g" \
                     "$cfgFile"
    else
        sed -i -E -e "s|^(error_reporting\s*=\s*).*$|\1E_ALL|g" \
                  -e "s|^(display_errors\s*=\s*).*$|\1On|g" \
                  -e "s|^(display_startup_errors\s*=\s*).*$|\1On|g" \
                  -e "s|^(log_errors\s*=\s*).*$|\1On|g" \
                  -e "s|^(track_errors\s*=\s*).*$|\1On|g" \
                  -e "s|^(html_errors\s*=\s*).*$|\1On|g" \
                     "$cfgFile"

    fi

    cfgFile='/etc/php82/php-fpm.conf'
    term.log "    updating '${cfgFile}' with provided 'LOG_LEVEL'"'\n' 'white'

    if [ "$PHP_LOGGING" = 0 ]; then
        sed -i -E -e "s|^(log_level\s*=\s*).*$|\1warning|" \
                  -e "s|^;?(access.log.*)$|;\1|" \
                     "$cfgFile"
    else
        sed -i -E -e "s|^(log_level\s*=\s*).*$|\1debug|" \
                  -e "s|^;?(access.log\s*=\s*).*$|\1/var/log/php-fpm82.access.log|" \
                     "$cfgFile"
        touch /var/log/php-fpm82.access.log
    fi
fi

