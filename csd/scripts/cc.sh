#!/usr/bin/env bash

set -efu -o pipefail

hadoop_xml_to_json()
{
  xsltproc ../aux/hadoop2element-value.xslt client.hadoop_xml > client.xml 
  rm -f client.hadoop_xml

  xsltproc ../aux/xml2json.xslt client.xml | jq '
    .configuration |
    .port=(.port| tonumber) |
    .days=(.days | tonumber) |
    .keySize=(.keySize | tonumber) |
    .reorderDn=(.reorderDn == "true")' > client.json
  rm -f client.xml
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
    caHostname=`grep port server.properties | head -1 | cut -f 1 -d ':'`
    caPort=`grep port server.properties | head -1 | cut -f 2 -d '='`
    rm -f server.properties 

    # Fix hadoop_xml file
    sed -i "s/@@CA_HOSTNAME@@/${caHostname}/" client.hadoop_xml
    sed -i "s/@@CA_PORT@@/${caPort}/" client.hadoop_xml
    sed -i "s/@@HOSTNAME@@/$(hostname)/" client.hadoop_xml

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
