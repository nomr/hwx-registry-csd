#!/usr/bin/env bash

set -efu -o pipefail

. ${COMMON_SCRIPT}


hadoop_xml_to_json()
{
  xsltproc ${CDH_NIFI_XSLT}/hadoop2element-value.xslt server.hadoop_xml > server.xml
  xsltproc ${CDH_NIFI_XSLT}/xml2json.xslt server.xml | ${CDH_NIFI_JQ} '
    .configuration |
    .port=(.port| tonumber) |
    .days=(.days | tonumber) |
    .keySize=(.keySize | tonumber) |
    .reorderDn=(.reorderDn == "true")' > server.json
}

locate_java8_home() {
    if [ -z "${JAVA_HOME}" ]; then
        BIGTOP_JAVA_MAJOR=8
        locate_java_home
    fi

    JAVA="${JAVA_HOME}/bin/java"
    TOOLS_JAR=""

    # if command is env, attempt to add more to the classpath
    if [ "$1" = "env" ]; then
        [ "x${TOOLS_JAR}" =  "x" ] && [ -n "${JAVA_HOME}" ] && TOOLS_JAR=$(find -H "${JAVA_HOME}" -name "tools.jar")
        [ "x${TOOLS_JAR}" =  "x" ] && [ -n "${JAVA_HOME}" ] && TOOLS_JAR=$(find -H "${JAVA_HOME}" -name "classes.jar")
        if [ "x${TOOLS_JAR}" =  "x" ]; then
             warn "Could not locate tools.jar or classes.jar. Please set manually to avail all command features."
        fi
    fi
}

init() {
    # NiFi 1.4.0 was compiled with 1.8.0
    locate_java8_home $1

    # Simulate NIFI_TOOLKIT_HOME
    NIFI_TOOLKIT_HOME=$(pwd)
    [ -e lib ] || ln -s ${CDH_NIFI_TOOLKIT_HOME}/lib .

    hadoop_xml_to_json
}

run() {
    LIBS="${NIFI_TOOLKIT_HOME}/lib/*"

    CLASSPATH=".:${LIBS}"

    export JAVA_HOME="$JAVA_HOME"
    export NIFI_TOOLKIT_HOME="$NIFI_TOOLKIT_HOME"

    umask 0077
    exec "${JAVA}" -cp "${CLASSPATH}" ${JAVA_OPTS:--Xms12m -Xmx24m} ${CSD_JAVA_OPTS} org.apache.nifi.toolkit.tls.TlsToolkitMain server --configJsonIn server.json -F
}


main() {
    init "$1"
    run "$@"
}

case "$1" in
    run)
        main "$@"
        ;;
    deploy)
        ;;
    *)
        echo "Usage nifi {stop|run|status|dump|env}"
        ;;
esac
