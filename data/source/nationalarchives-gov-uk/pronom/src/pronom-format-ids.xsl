<!-- Timothy Lebo -->

<!--
Usage:

(from local file)
saxon.sh ../../../src/pronom-format-id.xsl a a -v accept=text/turtle -in DROID_SignatureFile_V65.xml

(from web URL)
saxon.sh ../../src/pronom-format-id.xsl a a -v accept=text/turtle source=http://www.nationalarchives.gov.uk/documents/DROID_SignatureFile_V65.xml -in ../../src/pronom-format-id.xsl
-->

<xsl:transform version="2.0" 
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
               xmlns:sig="http://www.nationalarchives.gov.uk/pronom/SignatureFile"
               exclude-result-prefixes="">
<xsl:output method="text"/>
<xsl:param name="accept" select='text'/> <!-- Also, text/turtle -->

<xsl:param name="source"/>
<!-- e.g. http://www.nationalarchives.gov.uk/documents/DROID_SignatureFile_V65.xml 
          Listed at http://www.nationalarchives.gov.uk/aboutapps/pronom/droid-signature-files.htm -->

<xsl:key name="format-by-puid" match="sig:FileFormat" use="@ID"/>
<xsl:variable name="BASE_URI" select="'http://www.nationalarchives.gov.uk/pronom/'"/>

<!-- http://stackoverflow.com/questions/1384802/java-how-to-indent-xml-generated-by-transformer -->

<xsl:template match="/">
   <xsl:if test="$accept = 'text/turtle'">
      <xsl:value-of select="concat('@prefix dcterms: &lt;http://purl.org/dc/terms/&gt; .',$NL)"/>
      <xsl:value-of select="concat('@prefix pronom:  &lt;http://reference.data.gov.uk/technical-registry/&gt; .',$NL)"/>
      <xsl:value-of select="$NL"/>
   </xsl:if>
   <xsl:choose>
      <xsl:when test="string-length($source)">
         <xsl:apply-templates select="doc($source)//sig:FileFormat[@PUID]"/>
      </xsl:when>
      <xsl:otherwise>
         <xsl:apply-templates select="//sig:FileFormat[@PUID]"/>
      </xsl:otherwise>
   </xsl:choose>
</xsl:template>

<xsl:template match="sig:FileFormat[@PUID]">
   <xsl:choose>
      <xsl:when test="$accept = 'onlytettext/turtle'">
      </xsl:when>
      <xsl:otherwise>
         <xsl:value-of select="concat(@ID,' ',@PUID,$NL)"/>
      </xsl:otherwise>
   </xsl:choose>
</xsl:template>

<xsl:variable name="NL">
<xsl:text>
</xsl:text>
</xsl:variable>

<xsl:variable name="DQ">
<xsl:text>"</xsl:text>
</xsl:variable>

</xsl:transform>
