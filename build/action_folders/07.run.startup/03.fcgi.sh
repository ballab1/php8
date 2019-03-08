#!/bin/bash

: ${WWW_UID:?"Environment variable 'WWW_UID' not defined in '${BASH_SOURCE[0]}'"}

sed -i "s|^socket=.*$|socket=unix://${RUN_DIR}/fcgiwrap.sock|"         /etc/supervisor.d/fcgiwrap.ini
sed -i "s|^\s*server\s+.*$|    server unix:${RUN_DIR}/fcgiwrap.sock;|" /etc/nginx/conf.d/fcgi.upstream

crf.fixupDirectory "$RUN_DIR" "$WWW_UID"
