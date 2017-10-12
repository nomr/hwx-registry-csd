<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:template match="configuration" >
    <xsl:choose>
      <xsl:when test="property[name='cdh.stateManagement.provider.type' and value='local-provider']">
        <xsl:comment>State Provider that stores state locally in a configurable directory.</xsl:comment>
        <local-provider>
          <xsl:apply-templates/>
        </local-provider>
      </xsl:when>
      <xsl:when test="property[name='cdh.stateManagement.provider.type' and value='cluster-provider']">
        <xsl:comment>State Provider that stores cluster state.</xsl:comment>
        <cluster-provider>
          <xsl:apply-templates/>
        </cluster-provider>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="property">
    <xsl:choose>
      <xsl:when test="starts-with(name, 'cdh')"></xsl:when>
      <xsl:when test="name = 'id' or name = 'class'">
        <xsl:element name = "{name}">
          <xsl:value-of select="value"/>
        </xsl:element>
      </xsl:when>
      <xsl:otherwise>
        <property name="{name}"><xsl:value-of select="value"/></property>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>
