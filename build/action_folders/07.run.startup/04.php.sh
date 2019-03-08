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