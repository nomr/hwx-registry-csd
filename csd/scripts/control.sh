#!/usr/bin/env bash

set -efu -o pipefail

. ${COMMON_SCRIPT}

envsubst_all() {
    local shell_format="\$CONF_DIR,\$ZK_QUORUM"
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
    if [ -e $1 ]; then
      mv $1 $2
    fi
}

move_aux_files() {
    local in=aux/registry-sp-${HWX_REGISTRY_SP}.envsubst.yaml 
    local out=${CONF_DIR}/registry-sp.envsubst.yaml
    mv_if_exists $in $out

    if [ ! -z ${ZK_QUORUM+x} ]; then
      mv_if_exists aux/registry-ha.envsubst.yaml ${CONF_DIR}/registry-ha.envsubst.yaml
    fi
}

get_property() {
    local file=$1
    local key=$2
    local line=$(grep "$key=" ${file}.properties | tail -1)
    echo "${line/$key=/}"
}

load_variables() {
    HWX_REGISTRY_SP_DB_PORT=":${HWX_REGISTRY_SP_DB_PORT}"
    if [ "${HWX_REGISTRY_SP_DB_PORT}" == ":0" ]; then
        HWX_REGISTRY_SP_DB_PORT=""
    fi

    # Logging Variables
    export HWX_REGISTRY_LOG_THRESHOLD=$(get_property log4j log.threshold)
    export HWX_REGISTRY_LOG_FILE=$(get_property log4j log.file)
    export HWX_REGISTRY_LOG_FILE_COUNT=$(get_property log4j max.log.file.backup.index)
    export HWX_REGISTRY_LOG_FILE_SIZE=$(get_property log4j max.log.file.size)
    export HWX_REGISTRY_LOG_FILE_FORMAT=$(get_property log4j log4j.appender.RFA.layout.ConversionPattern)
    export HWX_REGISTRY_LOG_CONSOLE_FORMAT=$(get_property log4j log4j.appender.console.layout.ConversionPattern)
    rm -f log4j.properties

}

create_registry_yaml() {
    load_variables
    move_aux_files

    envsubst_all

    append_and_delete ${CONF_DIR}/registry-sp.yaml ${CONF_DIR}/registry.yaml
    append_and_delete ${CONF_DIR}/registry-ha.yaml ${CONF_DIR}/registry.yaml
}

registry_main() {
    create_registry_yaml

    locate_java_home
    export REGISTRY_OPTS=$CSD_JAVA_OPTS
    exec ${HWX_REGISTRY_HOME}/bin/registry-server-start.sh ${CONF_DIR}/registry.yaml
}

bootstrap_main() {
    create_registry_yaml
    locate_java_home

    JAVA=${JAVA_HOME}/bin/java
    BOOTSTRAP_DIR=${HWX_REGISTRY_HOME}/bootstrap
    CONFIG_FILE_PATH=${CONF_DIR}/registry.yaml
    SCRIPT_ROOT_DIR=${BOOTSTRAP_DIR}/sql
    CLASSPATH="${BOOTSTRAP_DIR}/lib/*"
    TABLE_INITIALIZER_MAIN_CLASS=com.hortonworks.registries.storage.tool.TablesInitializer

    for cmd in $@; do
      ${JAVA} -Dbootstrap.dir=$BOOTSTRAP_DIR  -cp ${CLASSPATH} ${TABLE_INITIALIZER_MAIN_CLASS} -c ${CONFIG_FILE_PATH} -s ${SCRIPT_ROOT_DIR} --$cmd
    done
}

program=$1
shift
case "$program" in
    registry)
      registry_main $@
      ;;
    bootstrap)
      bootstrap_main $@
      ;;
    *)
      echo "Usage: control.sh <registry|bootstrap>"
      exit 127
      ;;
esac
