#!/usr/bin/env bash

set -efu -o pipefail

hadoop_xml_to_json()
{
  local file=tls-service
  xsltproc ../aux/hadoop2element-value.xslt ${file}.hadoop_xml > ${file}.xml
  rm -f ${file}.hadoop_xml

  xsltproc ../aux/xml2json.xslt ${file}.xml | jq '
    .configuration |
    .port=(.port| tonumber) |
    .days=(.days | tonumber) |
    .keySize=(.keySize | tonumber) |
    .reorderDn=(.reorderDn == "true")' > ${file}.json
  rm -f ${file}.xml
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

deploy() {
    # Parse master.properties
    caHostname=`grep port tls-server.properties | head -1 | cut -f 1 -d ':'`
    caPort=`grep port tls-server.properties | head -1 | cut -f 2 -d '='`
    rm -f tls-server.properties

    # Fix hadoop_xml file
    sed -i "s/@@CA_HOSTNAME@@/${caHostname}/" tls-service.hadoop_xml
    sed -i "s/@@CA_PORT@@/${caPort}/" tls-service.hadoop_xml
    sed -i "s/@@HOSTNAME@@/$(hostname -f)/" tls-service.hadoop_xml

    # Convert to json
    hadoop_xml_to_json
}

case "$1" in
    deploy)
        deploy $@
        ;;
    *)
        echo "Usage cc {deploy}"
        ;;
esac
