<!-- Timothy Lebo -->
<xsl:transform version="2.0" 
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
               xmlns:xhtml="http://www.w3.org/1999/xhtml"
               exclude-result-prefixes="">
<xsl:output method="text"/>

<!-- 
   Usage:
     saxon.sh ../../src/mime-media-type-index.xsl a a source/index.html.tidy.html > automatic/mime-media-types.csv
-->

<!-- http://stackoverflow.com/questions/1384802/java-how-to-indent-xml-generated-by-transformer -->

<xsl:template match="/">
   <xsl:apply-templates select="//xhtml:p[matches(text()[1],'The following is the list')]/following-sibling::xhtml:p"/>
</xsl:template>

<xsl:template match="xhtml:p">
   <xsl:variable name="type" select="concat('http://www.iana.org',replace(xhtml:a/@href,'/$',''))"/>
   <xsl:value-of select="concat($type,' ',$NL)"/>
</xsl:template>

<xsl:template match="@*|node()">
  <xsl:copy>
      <xsl:copy-of select="@*"/>   
      <xsl:apply-templates/>
  </xsl:copy>
</xsl:template>

<!--xsl:template match="text()">
   <xsl:value-of select="normalize-space(.)"/>
</xsl:template-->

<xsl:variable name="NL">
<xsl:text>
</xsl:text>
</xsl:variable>

</xsl:transform>
