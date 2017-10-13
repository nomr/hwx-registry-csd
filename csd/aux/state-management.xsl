<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:template match="configuration" >
    <stateManagement>
    <xsl:choose>
      <xsl:when test="property[name='cdh.stateManagement.provider.type' and value='local-provider']">
        <xsl:comment>State Provider that stores state locally in a configurable directory.</xsl:comment>
        <local-provider>
          <xsl:apply-templates>
            <xsl:with-param name="element-keys">id class</xsl:with-param>
          </xsl:apply-templates>
        </local-provider>
      </xsl:when>
      <xsl:when test="property[name='cdh.stateManagement.provider.type' and value='cluster-provider']">
        <xsl:comment>State Provider that stores cluster state.</xsl:comment>
        <cluster-provider>
          <xsl:apply-templates>
            <xsl:with-param name="element-keys">id class</xsl:with-param>
          </xsl:apply-templates>
        </cluster-provider>
      </xsl:when>
    </xsl:choose>
    </stateManagement>
  </xsl:template>

  <xsl:include href="hadoop2nifi.xslt"/>

</xsl:stylesheet>
