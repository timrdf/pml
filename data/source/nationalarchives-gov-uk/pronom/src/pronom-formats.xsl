<!-- Timothy Lebo -->

<!-- This processes a DROID/PRONOM signature file, which looks like:
   <FFSignatureFile DateCreated="2012-10-25T12:11:19" Version="65" 
      xmlns="http://www.nationalarchives.gov.uk/pronom/SignatureFile">
        ...
        <FileFormat ID="1268"
            Name="Acrobat PDF/A - Portable Document Format"
            PUID="fmt/481" Version="3u">
            <InternalSignatureID>755</InternalSignatureID>
            <Extension>pdf</Extension>
            <HasPriorityOverFileFormatID>613</HasPriorityOverFileFormatID>
            <HasPriorityOverFileFormatID>614</HasPriorityOverFileFormatID>
            <HasPriorityOverFileFormatID>615</HasPriorityOverFileFormatID>
            <HasPriorityOverFileFormatID>616</HasPriorityOverFileFormatID>
            <HasPriorityOverFileFormatID>617</HasPriorityOverFileFormatID>
            <HasPriorityOverFileFormatID>618</HasPriorityOverFileFormatID>
            <HasPriorityOverFileFormatID>637</HasPriorityOverFileFormatID>
            <HasPriorityOverFileFormatID>1016</HasPriorityOverFileFormatID>
        </FileFormat>
-->

<!--
Usage:

(from local file)
saxon.sh ../../../src/pronom-format-id.xsl a a -v accept=text/turtle -in DROID_SignatureFile_V65.xml

(from web URL)
saxon.sh ../../src/pronom-format-id.xsl a a -v accept=text/turtle source=http://www.nationalarchives.gov.uk/documents/DROID_SignatureFile_V65.xml -in ../../src/pronom-format-id.xsl
-->

<xsl:transform version="2.0" 
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
               xmlns:pronom="http://pronom.nationalarchives.gov.uk"
               xmlns:sig="http://www.nationalarchives.gov.uk/pronom/SignatureFile"
               exclude-result-prefixes="">
<xsl:output method="text"/>
<xsl:param name="accept" select='text'/> <!-- Also, text/turtle -->

<!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->
<!-- Change if you want to host your own URIs for the formats. -->
<xsl:param name="BASE_URI" select="'http://provenanceweb.org'"/>
<!-- Set to a URL to scrape directly from that
       e.g. http://www.nationalarchives.gov.uk/documents/DROID_SignatureFile_V65.xml 
          Listed at http://www.nationalarchives.gov.uk/aboutapps/pronom/droid-signature-files.htm -->
<xsl:param name="source"/>
<!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->

<xsl:template match="/">
   <xsl:if test="$accept = 'text/turtle'">
      <xsl:value-of select="concat('@prefix dcterms: &lt;http://purl.org/dc/terms/&gt; .',$NL)"/>
      <xsl:value-of select="concat('@prefix prov:    &lt;http://www.w3.org/ns/prov#&gt; .',$NL)"/>
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

<xsl:key name="format-by-puid" match="sig:FileFormat" use="@ID"/>

<xsl:template match="sig:FileFormat[@PUID]">
   <xsl:choose>
      <xsl:when test="$accept = 'text/turtle'">

         <xsl:value-of select="concat('&lt;',pronom:name($BASE_URI,@PUID),'&gt;',$NL,
                                      '   a dcterms:FileFormat;',$NL,
              if( @Name ) then concat('   dcterms:title ',$DQ,@Name,$DQ,';',$NL) else '',
           if( @Version ) then concat('   pronom:version ',$DQ,@Version,$DQ,';',$NL) else '',
                                      '   dcterms:identifier ',$DQ,@PUID,$DQ,';',$NL,
                                      '   pronom:puid        ',$DQ,@PUID,$DQ,';',$NL,
                if( @ID ) then concat('   dcterms:identifier     ',$DQ,@ID,$DQ,';',$NL) else '',
                                      '   pronom:strFileFormatID ',$DQ,@ID,$DQ,';',$NL)"/>

            <xsl:for-each-group select="sig:Extension" group-by=".">
               <xsl:value-of select="concat('   pronom:extension ',$DQ,.,$DQ,';',$NL)"/>
            </xsl:for-each-group>

            <xsl:for-each-group select="sig:HasPriorityOverFileFormatID" group-by=".">
               <xsl:if test="key('format-by-puid',text())/@PUID">
                  <xsl:value-of select="concat('   pronom:hasPriorityOver &lt;',pronom:name($BASE_URI,key('format-by-puid',text())/@PUID),'&gt;;',$NL)"/>
               </xsl:if>
            </xsl:for-each-group>

         <xsl:value-of select="concat('.',$NL,$NL)"/>
      </xsl:when>
      <xsl:otherwise>
         <xsl:value-of select="concat($BASE_URI,@PUID,$NL)"/>
      </xsl:otherwise>
   </xsl:choose>
</xsl:template>

<xsl:function name="pronom:name">
   <xsl:param name="base"/>
   <xsl:param name="puid"/>
   <xsl:value-of select="concat($base,'/formats/pronom/',$puid)"/>
</xsl:function>

<xsl:variable name="NL">
<xsl:text>
</xsl:text>
</xsl:variable>

<xsl:variable name="DQ">
<xsl:text>"</xsl:text>
</xsl:variable>

</xsl:transform>
