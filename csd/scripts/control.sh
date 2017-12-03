#!/usr/bin/env bash

set -efu -o pipefail

. ${COMMON_SCRIPT}

envsubst_all() {
    local shell_format="\$ZK_QUORUM"
    for i in ${!HWX_REGISTRY_*}; do
        shell_format="${shell_format},\$$i"
    done

    for i in $(find . -maxdepth 1 -type f -name '*.envsubst*'); do
        cat $i | envsubst $shell_format > ${i/\.envsubst/}
        rm -f $i
    done
}

append_and_delete() {
    local in=$1
    local out=$2
    if [ -e $in ]; then
      cat $in >> $out
      rm -f $in
    fi
}

mv_if_exists() {
    if [ -e ${in} ]; then
      mv $1 $2
    fi
}

move_aux_files() {
    local in=aux/registry-sp-${HWX_REGISTRY_SP}.envsubst.yaml 
    local out=${CONF_DIR}/registry-sp.envsubst.yaml
    mv_if_exists $in $out
}

edit_variables() {
    HWX_REGISTRY_SP_DB_PORT=":${HWX_REGISTRY_SP_DB_PORT}"
    if [ "${HWX_REGISTRY_SP_DB_PORT}" == ":0" ]; then
        HWX_REGISTRY_SP_DB_PORT=""
    fi
}



edit_variables
move_aux_files
envsubst_all
append_and_delete ${CONF_DIR}/registry-sp.yaml ${CONF_DIR}/registry.yaml

locate_java_home
export REGISTRY_OPTS=$CSD_JAVA_OPTS
exec ${HWX_REGISTRY_HOME}/bin/registry-server-start.sh ${CONF_DIR}/registry.yaml
