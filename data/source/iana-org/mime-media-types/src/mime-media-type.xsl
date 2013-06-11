<!-- Timothy Lebo -->
<xsl:transform version="2.0" 
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
               xmlns:xhtml="http://www.w3.org/1999/xhtml"
               exclude-result-prefixes="">
<xsl:output method="text"/>

<xsl:param name="scrapesource" select="'http://www.iana.org/assignments/media-types/application/index.html'"/>
<xsl:param name="supertype"    select="'application'"/>

<xsl:param name="base_uri"           select="'http://provenanceweb.org'"/>
<xsl:param name="source_identifier"  select="'iana-org'"/>
<xsl:param name="dataset_identifier" select="'mime-media-types'"/>
<!-- Safe to assume: -->
<xsl:param name="iana"         select="'http://www.iana.org'"/>

<!-- 
   Usage:
     saxon.sh ../../src/mime-media-type.xsl a a -v scrapesource=http://www.iana.org/assignments/media-types/application/index.html supertype=application -in source/application.html.tidy.html
-->

<!-- http://stackoverflow.com/questions/1384802/java-how-to-indent-xml-generated-by-transformer -->

<xsl:template match="/">
   <xsl:value-of select="concat(
      '@prefix prov:    &lt;http://www.w3.org/ns/prov#&gt; .',$NL,
      '@prefix dcterms: &lt;http://purl.org/dc/terms/&gt; .',$NL,
      '@prefix skos:    &lt;http://www.w3.org/2004/02/skos/core#&gt; .',$NL,
      '@prefix foaf:    &lt;http://xmlns.com/foaf/0.1/&gt; .',$NL,
      '@prefix rdfs:    &lt;http://www.w3.org/2000/01/rdf-schema#&gt; .',$NL,
      '@base            &lt;',$base_uri,'/format/mime/&gt; .',$NL,
      $NL)"/>
   <xsl:message select="count(//xhtml:table[count(xhtml:tr) gt 20]//xhtml:tr/xhtml:td[2])"/>
   <xsl:message select="count(//xhtml:table[count(xhtml:tbody/xhtml:tr) gt 20]/xhtml:tbody/xhtml:tr/xhtml:td[2])"/> <!-- application -->
   <xsl:apply-templates select="//xhtml:table[count(xhtml:tbody/xhtml:tr) gt 20]/xhtml:tbody/xhtml:tr/xhtml:td[2]"/> <!-- application -->
   <xsl:apply-templates select="//xhtml:table[count(xhtml:tr) gt 20]//xhtml:tr/xhtml:td[2]"/> <!-- text -->
</xsl:template>

<!--
      '@prefix :        &lt;',$base_uri,'/source/',$source_identifier,'/dataset/',$dataset_identifier,'/&gt; .',$NL,
-->

<!-- cells -->

<xsl:template match="xhtml:td[xhtml:a]">
   <xsl:value-of select="concat('&lt;',$supertype,'/',replace(normalize-space(xhtml:a/text()),'\+','-PLUS-'),'&gt;',$NL,
                                '   a dcterms:FileFormat;',$NL,
                                '   dcterms:title      ',$DQ,$supertype,'/',normalize-space(xhtml:a/text()),$DQ,';',$NL,
                                '   dcterms:identifier ',$DQ,$supertype,'/',normalize-space(xhtml:a/text()),$DQ,';',$NL,
                                '   skos:broader       &lt;',$supertype,'&gt;;',$NL,
                                '   foaf:page          &lt;',$scrapesource,'&gt;;',$NL
                                )"/>
   <xsl:if test="xhtml:a/@href">
      <xsl:value-of select="concat('   rdfs:isDefinedBy   &lt;',$iana,xhtml:a/@href,'&gt;;',$NL)"/>
   </xsl:if>
   <xsl:apply-templates select="following-sibling::xhtml:td[1]/xhtml:a"/>
   <xsl:value-of select="concat('.',$NL,$NL)"/>

   <xsl:if test="xhtml:a/@href">
      <xsl:value-of select="concat('&lt;',$iana,xhtml:a/@href,'&gt;',$NL,
                                   '   a foaf:Document;',$NL,
                                   '   rdfs:label ',$DQ,normalize-space(xhtml:a/text()),$DQ,';',$NL,
                                   '.',$NL,$NL)"/>
   </xsl:if>
   <xsl:apply-templates select="following-sibling::xhtml:td[1]/xhtml:a" mode="describe-object"/>
</xsl:template>

<xsl:template match="xhtml:a">
   <xsl:choose>
      <xsl:when test="matches(@href,'^http://www.iana.org')">
         <xsl:value-of select="concat('   prov:wasAttributedTo &lt;',@href,'&gt;;',$NL)"/>
      </xsl:when>
      <xsl:otherwise>
         <xsl:value-of select="concat('   rdfs:isDefinedBy   &lt;',@href,'&gt;;',$NL)"/>
      </xsl:otherwise>
   </xsl:choose>
</xsl:template>

<xsl:template match="xhtml:a" mode="describe-object">
   <xsl:value-of select="concat('&lt;',@href,'&gt;',$NL,
                                '  rdfs:label ',$DQ,normalize-space(text()),$DQ,';',$NL)"/>
   <xsl:choose>
      <xsl:when test="matches(@href,'^http://www.iana.org')">
         <xsl:value-of select="concat('  a foaf:Agent, prov:Agent;',$NL)"/>
      </xsl:when>
      <xsl:otherwise>
         <xsl:value-of select="concat('  a foaf:Document;',$NL)"/>
      </xsl:otherwise>
   </xsl:choose>
   <xsl:value-of select="concat('.',$NL,$NL)"/>
</xsl:template>

<xsl:template match="@*|node()"></xsl:template>
  <!--xsl:copy>
      <xsl:copy-of select="@*"/>   
      <xsl:apply-templates/>
  </xsl:copy-->

<xsl:template match="text()"></xsl:template>
   <!--xsl:value-of select="normalize-space(.)"/-->

<xsl:variable name="NL">
<xsl:text>
</xsl:text>
</xsl:variable>

<xsl:variable name="DQ">
<xsl:text>"</xsl:text>
</xsl:variable>

</xsl:transform>
