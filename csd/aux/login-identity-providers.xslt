<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:template match="configuration" >
    <loginIdentityProviders>
    <xsl:choose>
      <xsl:when test="property[name='cdh.login.identity.providers.type' and value='provider']">
        <providers>
          <xsl:apply-templates/>
        </providers>
      </xsl:when>
    </xsl:choose>
    </stateManagement>
  </xsl:template>

  <xsl:include href="hadoop2nifi.xslt"/>

</xsl:stylesheet>
