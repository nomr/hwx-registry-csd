#!/usr/bin/env bash

set -efu -o pipefail

. ${COMMON_SCRIPT}

locate_java_home

shell_format=""
for i in ${!HWX_REGISTRY_*}; do
  shell_format="${shell_format},\$$i"
done

cat ${CONF_DIR}/registry.yaml | envsubst $shell_format > ${CONF_DIR}/registry.yaml.final

exec ${HWX_REGISTRY_HOME}/bin/registry-server-start.sh ${CONF_DIR}/registry.yaml.final
