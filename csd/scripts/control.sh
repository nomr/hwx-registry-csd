#!/usr/bin/env bash

set -efu -o pipefail

. ${COMMON_SCRIPT}


envsubst_all() {
    shell_format="\$ZK_QUORUM"
    for i in ${!HWX_REGISTRY_*}; do
        shell_format="${shell_format},\$$i"
    done

    for i in $(find . -maxdepth 1 -type f -name '*.envsubst*'); do
        cat $i | envsubst $shell_format > ${i/\.envsubst/}
        rm -f $i
    done
}

locate_java_home
envsubst_all

export REGISTRY_OPTS=$CSD_JAVA_OPTS
exec ${HWX_REGISTRY_HOME}/bin/registry-server-start.sh ${CONF_DIR}/registry.yaml.final
