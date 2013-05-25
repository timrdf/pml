<!-- This processes a DROID/PRONOM format description XML, which looks like:
     (from http://www.nationalarchives.gov.uk/pronom/fmt/319 - "Save as XML")

   <PRONOM-Report xmlns="http://pronom.nationalarchives.gov.uk">
     <report_format_detail>
       <FileFormat>
         <FormatID>1064</FormatID>
         <FormatName>ESRI Spatial Index File</FormatName>
         <FormatVersion>
         </FormatVersion>
         <FormatAliases>
         </FormatAliases>
         <FormatFamilies>
         </FormatFamilies>
         <FormatTypes>GIS</FormatTypes>
-->

<!--
Usage:

(from local file)
saxon.sh ../../src/pronom-format.xsl a a source/fmt__319.xml

(from web URL)
-->

<xsl:transform version="2.0" 
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
               xmlns:pronom="http://pronom.nationalarchives.gov.uk"
               xmlns:xs="http://www.w3.org/2001/XMLSchema"
               exclude-result-prefixes="">

<xsl:output method="text"/>
<xsl:param name="accept" select="'text/turtle'"/> <!-- Also, text/turtle -->

<!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->   
<!-- Change if you want to host your own URIs for the formats. -->
<xsl:param name="BASE_URI"        select="'http://provenanceweb.org'"/> 
<!-- Change if http://www.nationalarchives.gov.uk/pronom/fmt/1 no longer resolves -->
<xsl:param name="BASE_URI_PRONOM" select="'http://www.nationalarchives.gov.uk/pronom/'"/>
<!-- Set to a URL to scrape directly from that
       e.g. http://www.nationalarchives.gov.uk/documents/DROID_SignatureFile_V65.xml 
          Listed at http://www.nationalarchives.gov.uk/aboutapps/pronom/droid-signature-files.htm -->
<xsl:param name="source"/>
<!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->   

<xsl:template match="/">
   <xsl:if test="$accept = 'text/turtle'">
      <xsl:value-of select="concat('@prefix rdfs:    &lt;http://www.w3.org/2000/01/rdf-schema#&gt; .',$NL)"/>
      <xsl:value-of select="concat('@prefix dcterms: &lt;http://purl.org/dc/terms/&gt; .',$NL)"/>
      <xsl:value-of select="concat('@prefix prov:    &lt;http://www.w3.org/ns/prov#&gt; .',$NL)"/>
      <xsl:value-of select="concat('@prefix pronom:  &lt;http://reference.data.gov.uk/technical-registry/&gt; .',$NL)"/>
      <xsl:value-of select="$NL"/>
   </xsl:if>
   <xsl:choose>
      <xsl:when test="string-length($source)">
         <xsl:apply-templates select="doc($source)//pronom:FileFormat"/>
      </xsl:when>
      <xsl:otherwise>
         <xsl:apply-templates select="//pronom:FileFormat"/>
      </xsl:otherwise>
   </xsl:choose>
</xsl:template>

<xsl:key name="format-by-puid" match="pronom:FileFormat" use="@ID"/>

<xsl:template match="pronom:FileFormat">
   <xsl:variable name="puid" select="pronom:FileFormatIdentifier[pronom:IdentifierType='PUID']/pronom:Identifier"/>

   <xsl:if test="$puid">

      <xsl:choose>
         <xsl:when test="$accept = 'text/turtle'">
            <xsl:value-of select="concat('&lt;',pronom:name($BASE_URI,$puid),'&gt;',$NL,
                                                       '   a dcterms:FileFormat;',$NL,
                   if( pronom:FormatName ) then concat('   dcterms:title ',$DQ,pronom:FormatName,$DQ,';',$NL) else '',
if( pronom:ne(pronom:FormatVersion) gt 0 ) then concat('   pronom:version ',$DQ,pronom:FormatVersion,$DQ,';',$NL) else '',
                                                       '   dcterms:identifier ',$DQ,$puid,$DQ,';',$NL,
                                                       '   pronom:puid        ',$DQ,$puid,$DQ,';',$NL,
                     if( pronom:FormatID ) then concat('   dcterms:identifier     ',$DQ,pronom:FormatID,$DQ,';',$NL) else '',
                                                       '   pronom:strFileFormatID ',$DQ,pronom:FormatID,$DQ,';',$NL,
 if( pronom:ne(pronom:FormatDescription) ) then concat('   dcterms:description ',$TDQ,replace(normalize-space(pronom:FormatDescription),$DQ,$SQ),$TDQ,';',$NL) else '',
                                                       '   prov:wasAttributedTo  &lt;',$BASE_URI,'&gt;;',$NL,
                                                       '   prov:specializationOf &lt;info:pronom/',$puid,'&gt;;',$NL,
                                                       '   prov:alternateOf      &lt;',$BASE_URI_PRONOM,$puid,'&gt;;',$NL,
                                                       '   rdfs:seeAlso          &lt;https://github.com/timrdf/prizms/wiki/PRONOM&gt;;',$NL
            )"/>

            <xsl:for-each-group select="pronom:Extension" group-by=".">
               <xsl:value-of select="concat('   pronom:extension ',$DQ,.,$DQ,';',$NL)"/>
            </xsl:for-each-group>

            <xsl:for-each-group select="pronom:HasPriorityOverFileFormatID" group-by=".">
               <xsl:if test="key('format-by-puid',text())/@PUID">
                  <xsl:value-of select="concat('   pronom:hasPriorityOver &lt;',pronom:name($BASE_URI,key('format-by-puid',text())/@PUID),'&gt;;',$NL)"/>
               </xsl:if>
            </xsl:for-each-group>

            <xsl:value-of select="concat('.',$NL)"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:value-of select="concat(pronom:name($BASE_URI,$puid),$NL)"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:if>
</xsl:template>

<xsl:function name="pronom:ne">
   <xsl:param name="string"/>
   <xsl:copy-of select="xs:integer(string-length(normalize-space($string)))"/>
</xsl:function>

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

<xsl:variable name="SQ">
<xsl:text>'</xsl:text>
</xsl:variable>

<xsl:variable name="TDQ">
<xsl:text>"""</xsl:text>
</xsl:variable>

</xsl:transform>
