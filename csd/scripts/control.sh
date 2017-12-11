#!/usr/bin/env bash
set -efu -o pipefail
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

. ${DIR}/common.sh
HWX_REGISTRY_SERVER_APP=https
pki_init() {
    HWX_REGISTRY_SERVER_APP=http
    return 0
}
[ -f pki-conf/init.sh ] && . pki-conf/init.sh


move_aux_files() {
    local in=aux/registry-sp-${HWX_REGISTRY_SP}.envsubst.yaml
    local out=${CONF_DIR}/registry-sp.envsubst.yaml
    mv_if_exists $in $out

    in=aux/registry-sf-auth-${HWX_REGISTRY_AUTH}.envsubst.yaml
    out=${CONF_DIR}/registry-sf-auth.envsubst.yaml
    mv_if_exists $in $out

    in=aux/registry-s-app[${HWX_REGISTRY_SERVER_APP}].envsubst.yaml
    out=${CONF_DIR}/registry-s-app.envsubst.yaml
    mv_if_exists $in $out

    if [ ! -z ${ZK_QUORUM+x} ]; then
      mv_if_exists aux/registry-ha.envsubst.yaml ${CONF_DIR}/registry-ha.envsubst.yaml
    fi
}


load_variables() {
    HWX_REGISTRY_SP_DB_PORT=":${HWX_REGISTRY_SP_DB_PORT}"
    if [ "${HWX_REGISTRY_SP_DB_PORT}" == ":0" ]; then
        HWX_REGISTRY_SP_DB_PORT=""
    fi

    # Pickup the TRUSTSTORE and KEYSTORE Locations
    load_vars HWX_REGISTRY pki-conf/client-csr

    # Kerberos Variables
    export HWX_REGISTRY_KEYTAB=${CONF_DIR}/${HWX_REGISTRY_USER/-/_}.keytab

    # Logging Variables
    if [ -e log4j.properties ]; then
        export HWX_REGISTRY_LOG_THRESHOLD=$(get_property log4j log.threshold)
        export HWX_REGISTRY_LOG_FILE=$(get_property log4j log.file)
        export HWX_REGISTRY_LOG_FILE_COUNT=$(get_property log4j max.log.file.backup.index)
        export HWX_REGISTRY_LOG_FILE_SIZE=$(get_property log4j max.log.file.size)
        export HWX_REGISTRY_LOG_FILE_FORMAT=$(get_property log4j log4j.appender.RFA.layout.ConversionPattern)
        export HWX_REGISTRY_LOG_CONSOLE_FORMAT=$(get_property log4j log4j.appender.console.layout.ConversionPattern)
    fi

}

create_registry_certificates() {
    pki_init
}

create_registry_yaml() {
    load_variables
    move_aux_files

    envsubst_all HWX_REGISTRY

    append_and_delete ${CONF_DIR}/registry-sf-auth.yaml ${CONF_DIR}/registry-sf.yaml
    append_and_delete ${CONF_DIR}/registry-s-app.yaml ${CONF_DIR}/registry-s.yaml

    append_and_delete ${CONF_DIR}/registry-sp.yaml ${CONF_DIR}/registry.yaml
    append_and_delete ${CONF_DIR}/registry-ha.yaml ${CONF_DIR}/registry.yaml
    append_and_delete ${CONF_DIR}/registry-sf.yaml ${CONF_DIR}/registry.yaml
    append_and_delete ${CONF_DIR}/registry-s.yaml ${CONF_DIR}/registry.yaml
}

registry_main() {
    create_registry_certificates
    create_registry_yaml

    locate_java_home
    export REGISTRY_OPTS=$CSD_JAVA_OPTS

    if [ -e ${HWX_REGISTRY_KEYTAB} ]; then
        REGISTRY_OPTS="${REGISTRY_OPTS} -Djava.security.auth.login.config=jaas.conf"
    fi

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

zookeeper_main() {
    if [ -z ${ZK_QUORUM+x} ]; then
        return 127
    fi

    create_registry_yaml
    locate_java_home

    export CLIENT_JVMFLAGS=""
    ZK_ACL="world:anyone:cdrwa"
    if [ -e ${HWX_REGISTRY_KEYTAB} ]; then
        CLIENT_JVMFLAGS="$CLIENT_JVMFLAGS -Djava.security.auth.login.config=jaas.conf"
        ZK_ACL="sasl:${HWX_REGISTRY_USER}:cdrwa,world:anyone:r"
    fi
    case "$1" in
        create)
            zookeeper-client -server $ZK_QUORUM create ${HWX_REGISTRY_ZK_ROOT} "Created by Cloudera Manager" $ZK_ACL
            ;;
        drop)
            zookeeper-client -server $ZK_QUORUM rmr ${HWX_REGISTRY_ZK_ROOT}
            ;;
    esac
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
    zookeeper)
      zookeeper_main $@
      ;;
    *)
      echo "Usage: control.sh <registry|bootstrap|zookeeper>"
      exit 127
      ;;
esac
