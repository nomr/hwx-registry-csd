<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:template match="property">
    <xsl:param name="element-keys">id class</xsl:param>
    <xsl:choose>
      <xsl:when test="starts-with(name, 'cdh')"></xsl:when>
      <xsl:when test="contains(concat($element-keys, ' '), concat(name, ' '))">
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
