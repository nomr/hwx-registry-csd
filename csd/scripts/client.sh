NIFI_TLS_ENABLED=true
tls_client_init() {
    local prefix=tls-conf/tls
    local caHostname=`grep port ${prefix}-service.properties | head -1 | cut -f 1 -d ':'`
    local caPort=`grep port ${prefix}-service.properties | head -1 | cut -f 2 -d '='`

    if [ -e ${prefix}.json ]; then
      return 0
    fi

    convert_prefix_hadoop_xml ${prefix} ${CDH_NIFI_XSLT}/hadoop2element-value.xslt

    sed -i "s/@@CA_HOSTNAME@@/${caHostname}/" ${prefix}-service.xml
    sed -i "s/@@CA_PORT@@/${caPort}/" ${prefix}-service.xml

    sed -i "s/@@DN_PREFIX@@/${DN_PREFIX}/" ${prefix}-client.xml
    sed -i "s/@@DN_SUFFIX@@/${DN_SUFFIX}/" ${prefix}-client.xml

    # Merge TLS configuration
    local merge=${CDH_NIFI_XSLT}/merge.xslt
    local in_a=${prefix}-client.xml
    local in_b=$(basename ${prefix}-service.xml) # relative paths only
    local out=${prefix}.xml
    xsltproc -o ${out} \
             --param with "'${in_b}'" \
             ${merge} ${in_a}
    rm -f ${in_a} ${in_b}


    xsltproc ${CDH_NIFI_XSLT}/xml2json.xslt $out | ${CDH_NIFI_JQ} '
      .configuration |
      .port=(.port| tonumber) |
      .days=(.days | tonumber) |
      .keySize=(.keySize | tonumber) |
      .reorderDn=(.reorderDn == "true")' > ${prefix}.json

    local CLASSPATH=".:${CDH_NIFI_TOOLKIT_HOME}/lib/*"

    "${JAVA}" -cp "${CLASSPATH}" \
                ${JAVA_OPTS:--Xms12m -Xmx24m} \
                ${CSD_JAVA_OPTS:-} \
                org.apache.nifi.toolkit.tls.TlsToolkitMain \
                client -F \
                --configJson ${prefix}.json
}
