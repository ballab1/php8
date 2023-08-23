#!/bin/bash

declare -ar env_php=(
    'PHP=php82'
    'SESSIONS_DIR="${SESSIONS_DIR:-/sessions}"'
    'RUN_DIR="${RUN_DIR:-/run/php82}"'
)

crf.updateRuntimeEnvironment "${env_php[@]}"
