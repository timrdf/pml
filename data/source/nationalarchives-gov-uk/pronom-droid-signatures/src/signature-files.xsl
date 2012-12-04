<!-- Timothy Lebo -->
<xsl:transform version="2.0" 
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
               xmlns:xhtml="http://www.w3.org/1999/xhtml"
               exclude-result-prefixes="">
<xsl:output method="text"/>
<xsl:param name="base" select="'http://www.nationalarchives.gov.uk'"/>

<xsl:template match="/">
  <xsl:apply-templates select="//xhtml:p[@class='mainbodytext']/xhtml:a"/>
</xsl:template>

<xsl:template match="xhtml:a">
   <xsl:value-of select="concat($base,@href,$NL)"/>
</xsl:template>

<xsl:variable name="NL">
<xsl:text>
</xsl:text>
</xsl:variable>

</xsl:transform>
