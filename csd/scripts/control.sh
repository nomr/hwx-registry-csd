#!/usr/bin/env bash

set -efu -o pipefail

. ${COMMON_SCRIPT}

locate_java_home

exec ${HWX_REGISTRY_HOME}/bin/registry-server-start.sh ${CONF_DIR}/registry.yaml
