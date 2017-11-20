#!/usr/bin/env bash

set -efu -o pipefail

hadoop_xml_to_json()
{
  local file=tls-service
  xsltproc $CDH_NIFI_XSLT/hadoop2element-value.xslt ${file}.hadoop_xml > ${file}.xml
  rm -f ${file}.hadoop_xml

  xsltproc $CDH_NIFI_XSLT/xml2json.xslt ${file}.xml | ${CDH_NIFI_JQ} '
    .configuration |
    .port=(.port| tonumber) |
    .days=(.days | tonumber) |
    .keySize=(.keySize | tonumber) |
    .reorderDn=(.reorderDn == "true")' > ${file}.json
  rm -f ${file}.xml
}

deploy() {
    # Parse master.properties
    caHostname=`grep port tls-service.properties | head -1 | cut -f 1 -d ':'`
    caPort=`grep port tls-service.properties | head -1 | cut -f 2 -d '='`
    rm -f ca-server.properties

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
