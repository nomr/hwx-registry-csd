<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:template match="configuration" >
    <authorizers>
    <xsl:choose>
      <xsl:when test="property[name='cdh.authorizers.type' and value='userGroupProvider']">
        <userGroupProvider>
          <xsl:apply-templates/>
        </userGroupProvider>
      </xsl:when>
      <xsl:when test="property[name='cdh.authorizers.type' and value='accessPolicyProvider']">
        <accessPolicyProvider>
          <xsl:apply-templates/>
         </accessPolicyProvider>
      </xsl:when>
      <xsl:when test="property[name='cdh.authorizers.type' and value='authorizer']">
        <authorizer>
          <xsl:apply-templates/>
         </authorizer>
      </xsl:when>
    </xsl:choose>
    </authorizers>
  </xsl:template>

  <xsl:include href="hadoop2nifi.xslt"/>

</xsl:stylesheet>
