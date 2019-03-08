#!/bin/bash

declare -ar env_php=(
    'PHP=php7'
    'SESSIONS_DIR="${SESSIONS_DIR:-/sessions}"'
    'RUN_DIR="${RUN_DIR:-/run/php}"'
)

crf.updateRuntimeEnvironment "${env_php[@]}"
