<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
      xmlns:xs="http://www.w3.org/2001/XMLSchema"
      xmlns:local="urn:local-functions"
      
      xmlns:rsiwp="http://reallysi.com/namespaces/generic-wordprocessing-xml"
      xmlns:stylemap="urn:public:/dita4publishers.org/namespaces/word2dita/style2tagmap"
      xmlns:relpath="http://dita2indesign/functions/relpath"
      
      exclude-result-prefixes="xs rsiwp stylemap local relpath"
      version="2.0">

  <!--==========================================
    DOCX to DITA generic transformation
    
    Copyright (c) 2009 DITA For Publishers, Inc.

    Transforms a DOCX document.xml file into a DITA topic using
    a style-to-tag mapping.
    
    This transform is intended to be the base for more specialized
    transforms that provide style-specific overrides.
    
    The input to this transform is the document.xml file within a DOCX
    package.
    
    
    Originally developed by Really Strategies, Inc.
    
    =========================================== -->
  
  <xsl:import href="../lib/relpath_util.xsl"/>
  
  <xsl:include href="wordml2simple.xsl"/>
  
  <xsl:param name="outputDir" as="xs:string"/>
  <xsl:param name="rootMapUrl" select="concat('rootMap_', format-time(current-time(),'[h][m][s][f]'),'.ditamap')" as="xs:string"/>
  <xsl:param name="debug" select="'false'" as="xs:string"/>

  <xsl:variable name="debugBoolean" as="xs:boolean" select="$debug = 'true'"/>  
  
  <xsl:template match="/" priority="10">
    <xsl:variable name="simpleWpDoc" as="element()">
      <xsl:call-template name="processDocumentXml"/>
    </xsl:variable>
    <xsl:variable name="tempDoc" select="relpath:newFile($outputDir, 'simpleWpDoc.xml')" as="xs:string"/>
    
     <xsl:if test="false() and $debugBoolean">        
       <xsl:result-document href="{$tempDoc}">
           <xsl:message> + [DEBUG] Intermediate simple WP doc saved as <xsl:sequence select="$tempDoc"/></xsl:message>
           <xsl:sequence select="$simpleWpDoc"/>
         </xsl:result-document>
     </xsl:if>    
    <xsl:apply-templates select="$simpleWpDoc"/>
    <xsl:message> + [INFO] Done.</xsl:message>
  </xsl:template>
  
  <xsl:template match="rsiwp:document">
    <!-- First <p> in doc should be title for the root topic. If it's not, bail -->  
    <xsl:variable name="firstP" select="rsiwp:body/(rsiwp:p|rsiwp:table)[1]" as="element()?"/>
    <xsl:if test="$debugBoolean">        
      <xsl:message> + [DEBUG] firstP=<xsl:sequence select="$firstP"/></xsl:message>
    </xsl:if>
    <xsl:if test="$firstP and not(local:isRootTopicTitle($firstP)) and not(local:isMap($firstP))">
      <xsl:message terminate="yes"> - [ERROR] The first block in the Word document must be mapped to the root topic title.
        First para is style <xsl:sequence select="string($firstP/@style)"/>, mapped as <xsl:sequence 
          select="key('styleMaps', string($firstP/@style), $styleMapDoc)[1]"/> 
      </xsl:message>
    </xsl:if>
    <xsl:choose>
      <xsl:when test="local:isRootTopicTitle($firstP)">
        <xsl:call-template name="makeTopic">
          <xsl:with-param name="content" select="rsiwp:body/(rsiwp:p|rsiwp:table)" as="node()*"/>
          <xsl:with-param name="level" select="0" as="xs:integer"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="local:isMap($firstP)">
        <xsl:call-template name="makeMap">
          <xsl:with-param name="content" select="rsiwp:body/(rsiwp:p|rsiwp:table)" as="node()*"/>
          <xsl:with-param name="level" select="0" as="xs:integer"/>
          <xsl:with-param name="mapUrl" select="$rootMapUrl" as="xs:string"/>
        </xsl:call-template>
      </xsl:when>
    </xsl:choose>
    
  </xsl:template>
  
  <xsl:template match="rsiwp:p[string(@structureType) = 'skip']" priority="10"/>
  
  <xsl:template match="rsiwp:p" name="transformPara">
    <xsl:variable name="tagName" as="xs:string"
      select="
      if (@tagName) 
      then string(@tagName)
      else 'p'
      "
    />
    <xsl:if test="not(./@tagName)">
      <xsl:message> + [WARNING] No style to tag mapping for paragraph style "<xsl:sequence select="string(@style)"/>"</xsl:message>
    </xsl:if>
    <xsl:choose>
      <xsl:when test="count(./*) = 0 and normalize-space(.) = ''">
        <xsl:if test="$debugBoolean">                  
          <xsl:message> + [DEBUG] Skipping apparently-empty paragraph: <xsl:sequence select="local:reportPara(.)"/></xsl:message>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <xsl:element name="{$tagName}">
          <xsl:sequence select="./@outputclass"/>
          <xsl:if test="./@dataName">
            <xsl:attribute name="name" select="./@dataName"/>
          </xsl:if>
          <xsl:call-template name="transformParaContent"/>    
        </xsl:element>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>
  
  <xsl:template name="transformParaContent">
    <!-- Transforms the content of a paragraph, where the containing
         element is generated by the caller. -->
    <xsl:choose>
      <xsl:when test="string(@useContent) = 'elementsOnly'">
        <xsl:apply-templates mode="p-content" select="*"/>
      </xsl:when>
      <xsl:when test="string(@putValueIn) = 'valueAtt'">
        <xsl:attribute name="value" select="string(.)"/>
        <xsl:if test="@dataName">
          <xsl:attribute name="name" select="string(@dataName)"/>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates mode="p-content"/>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>
  
  <xsl:template match="rsiwp:table">
<!--    <xsl:message> + [DEBUG] rsiwp:table: Starting...</xsl:message>-->
    <xsl:variable name="tagName" as="xs:string"
      select="
      if (@tagName) 
      then string(@tagName)
      else 'table'
      "
    />
    <xsl:element name="{$tagName}">
      <!-- FIXME: Need to account for table heads and table bodies -->
      <tgroup cols="{count(rsiwp:cols/rsiwp:col)}">
        <xsl:apply-templates select="rsiwp:cols"/>
        <tbody>
          <xsl:apply-templates select="rsiwp:tr"/>
        </tbody>        
      </tgroup>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="rsiwp:cols">
    <xsl:apply-templates/>
  </xsl:template>
  
  <xsl:template match="rsiwp:col">
    <colspec colname="{position()}" 
      colwidth="{concat(@width, '*')}"/>
  </xsl:template>
  
  <xsl:template match="rsiwp:tr">
    <row>
      <xsl:apply-templates/>
    </row>
  </xsl:template>
  
  <xsl:template match="rsiwp:td">
    <entry>
      <xsl:apply-templates/>
    </entry>
  </xsl:template>
  
  
  <xsl:template match="rsiwp:run" mode="p-content">
    <xsl:variable name="tagName" as="xs:string"
      select="
      if (@tagName) 
      then string(@tagName)
      else 'ph'
      "
    />
    <xsl:if test="not(./@tagName)">
      <xsl:message> + [WARNING] No style to tag mapping for character style "<xsl:sequence select="string(@style)"/>"</xsl:message>
    </xsl:if>
    <xsl:element name="{$tagName}">
      <xsl:apply-templates mode="#current"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="text()" mode="p-content">
    <xsl:copy/>
  </xsl:template>
  
  <xsl:template name="makeMap">
    <xsl:param name="content" as="element()+"/>
    <xsl:param name="level"  as="xs:integer"/><!-- Level of this topic -->
    
    <xsl:param name="mapUrl" as="xs:string">
      <xsl:variable name="mapTitleFragment" as="xs:string">
        <xsl:choose>
          <xsl:when test="contains($content[1],' ')">
            <xsl:value-of select="replace(substring-before(.,' '),'[\p{P}\p{Z}\p{C}]','')"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="replace($content[1],'[\p{P}\p{Z}\p{C}]','')"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:value-of select="concat('map_', $mapTitleFragment, '_', generate-id($content[1]), format-time(current-time(),'[h][m][s]'), '.ditamap')"/>
    </xsl:param>
  
    <xsl:variable name="firstP" select="$content[1]"/>
    <xsl:variable name="nextLevel" select="$level + 1" as="xs:integer"/>
    
    <xsl:variable name="formatName" select="$firstP/@format" as="xs:string?"/>
    <xsl:if test="not($formatName)">
      <xsl:message terminate="yes"> + [ERROR] No format= attribute for paragraph style <xsl:sequence select="string($firstP/@styleId)"/>, which is mapped to structure type "map".</xsl:message>
    </xsl:if>
    
    <xsl:variable name="format" select="key('formats', $formatName, $styleMapDoc)[1]"/>
    <xsl:if test="not($format)">
      <xsl:message terminate="yes"> + [ERROR] Failed to find output element with name "<xsl:sequence select="$formatName"/> specified for style <xsl:sequence select="string($firstP/@styleId)"/>.</xsl:message>
    </xsl:if>
    
    <xsl:variable name="prologType" as="xs:string"
      select="
      if ($firstP/@prologType and $firstP/@prologType != '')
      then $firstP/@prologType
      else 'topicmeta'
      "
    />
    
    <xsl:variable name="resultUrl" as="xs:string"
      select="relpath:newFile($outputDir, $mapUrl)"
    />
    
    <xsl:message> + [INFO] Creating new map document "<xsl:sequence select="$resultUrl"/>"...</xsl:message>
    
    
    <xsl:result-document href="{$resultUrl}"
      doctype-public="{$format/@doctype-public}"
      doctype-system="{$format/@doctype-system}"
      indent="yes"
      >
      <xsl:element name="{$firstP/@mapType}">
        <!-- The first paragraph can simply trigger a (possibly) untitled map, or
          it can also be the map title. If it's the map title, generate it.
          First paragraph can also generate a root topicref and/or a topicref
          to a topic in addition to the map.
        -->
        <xsl:if test="local:isMapTitle($firstP)">
          <xsl:apply-templates select="$firstP"/>
        </xsl:if>
        <xsl:if test="$content[string(@topicZone) = 'topicmeta' and string(@containingTopic) = 'root']">
          <xsl:variable name="prologParas" select="$content[string(@topicZone) = 'topicmeta' and string(@containingTopic) = 'root']" as="node()*"/>
          <!-- Now process any map-level topic metadata paragraphs. -->
          <xsl:element name="{$prologType}">
            <xsl:call-template name="handleTopicProlog">
              <xsl:with-param name="content" select="$prologParas"/>
            </xsl:call-template>
          </xsl:element>
        </xsl:if>
        <xsl:call-template name="generateTopicsAndTopicrefs">
          <xsl:with-param name="content" select="$content" as="node()*"/>
          <xsl:with-param name="nextLevel" select="$nextLevel" as="xs:integer"/>
        </xsl:call-template>                  
      </xsl:element>
    </xsl:result-document>
  </xsl:template>
  
  <xsl:template name="generateTopicsAndTopicrefs">
    <xsl:param name="content" as="node()*"/>
    <xsl:param name="nextLevel" as="xs:integer"/>
    
    <xsl:call-template name="generateTopicrefs">
      <xsl:with-param name="content" select="$content" as="node()*"/>
      <xsl:with-param name="level" select="$nextLevel" as="xs:integer"/>
    </xsl:call-template>
    <xsl:call-template name="generateTopics">
      <xsl:with-param name="content" select="$content" as="node()*"/>
      <xsl:with-param name="level" select="$nextLevel" as="xs:integer"/>
    </xsl:call-template>        
    
  </xsl:template>
  
  <xsl:template name="handleTopicProlog">
    <xsl:param name="content" as="node()*"/>
    
    <xsl:call-template name="handleBodyParas">
      <xsl:with-param name="bodyParas" select="$content"/>
    </xsl:call-template>
    
  </xsl:template>
  
  <!-- Generate topicsrefs and topicheads.
  -->
  <xsl:template name="generateTopicrefs">
    <xsl:param name="content" as="node()*"/>
    <xsl:param name="level" as="xs:integer"/>
    <xsl:variable name="firstP" select="$content[1]" as="element()*"/>
    
    <xsl:choose>
      <xsl:when test="$firstP/@rootTopicrefType != ''">
        <xsl:if test="$debugBoolean">                  
          <xsl:message> + [DEBUG] generateTopicrefs(): First para specifies rootTopicrefType</xsl:message>
        </xsl:if>
        <xsl:element name="{$firstP/@rootTopicrefType}">
          <xsl:if test="string($firstP/@rootTopicrefType) = 'learningObject'">
            <!-- FIXME: This is a workaround until we implement the ability
              to specify collection-type for the root topicref type.
            -->
            <xsl:attribute name="collection-type" select="'sequence'"/>
          </xsl:if>
          <xsl:choose>
            <xsl:when test="@topicrefType != ''">
              <xsl:element name="{@topicrefType}">
                <xsl:variable name="topicUrl"
                  as="xs:string"
                  select="local:getResultUrlForTopic($firstP)"
                />
                <xsl:call-template name="generateTopicrefAtts">
                  <xsl:with-param name="topicUrl" select="$topicUrl"/>
                </xsl:call-template>            
                <xsl:call-template name="generateSubordinateTopicrefs">
                  <xsl:with-param name="content" select="$content"/>
                  <xsl:with-param name="level" select="$level"/>
                </xsl:call-template>    
              </xsl:element>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="generateSubordinateTopicrefs">
                <xsl:with-param name="content" select="$content"/>
                <xsl:with-param name="level" select="$level"/>
              </xsl:call-template>    
            </xsl:otherwise>
          </xsl:choose>          
        </xsl:element>
      </xsl:when>
      <xsl:when test="$firstP/@topicrefType">
        <xsl:if test="$debugBoolean">                  
          <xsl:message> + [DEBUG] generateTopicrefs(): First para specifies topicrefType but not rootTopicrefType</xsl:message>
        </xsl:if>
        <xsl:element name="{$firstP/@topicrefType}">
          <xsl:variable name="topicUrl"
            as="xs:string"
            select="local:getResultUrlForTopic($firstP)"
          />
          <xsl:call-template name="generateTopicrefAtts">
            <xsl:with-param name="topicUrl" select="$topicUrl"/>
          </xsl:call-template>            
          <xsl:call-template name="generateSubordinateTopicrefs">
            <xsl:with-param name="content" select="$content"/>
            <xsl:with-param name="level" select="$level"/>
          </xsl:call-template>    
        </xsl:element>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="generateSubordinateTopicrefs">
          <xsl:with-param name="content" select="$content"/>
          <xsl:with-param name="level" select="$level"/>
        </xsl:call-template>    
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>
  <xsl:template name="generateSubordinateTopicrefs">
    <xsl:param name="content"/>
    <xsl:param name="level"/>
    <xsl:for-each-group select="$content[position() > 1]" 
      group-starting-with="*[(string(@structureType) = 'topicTitle' or 
      string(@structureType) = 'map' or 
      string(@structureType) = 'mapTitle' or
      string(@structureType) = 'topicHead' or
      string(@structureType) = 'topicGroup')  and
      string(@level) = string($level)]">
      <xsl:variable name="topicrefType" as="xs:string"
        select="if (@topicrefType) then @topicrefType else 'topicref'"
      />
      <xsl:choose>
        <xsl:when test="string(@structureType) = 'topicTitle' and string(@topicDoc) = 'yes'">
          <xsl:if test="$debugBoolean">        
            <xsl:message> + [DEBUG] generateTopicrefs: Got a doc-creating topic title. Level=<xsl:sequence select="string(@level)"/></xsl:message>
          </xsl:if>
          <xsl:variable name="topicUrl"
            as="xs:string"
            select="local:getResultUrlForTopic(current-group()[1])"
          />
          <xsl:element name="{$topicrefType}">            
            <xsl:call-template name="generateTopicrefAtts">
              <xsl:with-param name="topicUrl" select="$topicUrl"/>
            </xsl:call-template>            
            <xsl:call-template name="generateTopicrefs">
              <xsl:with-param name="content" select="current-group()[position() > 1]" as="node()*"/>
              <xsl:with-param name="level" select="$level + 1"  as="xs:integer"/>
            </xsl:call-template>
          </xsl:element>          
        </xsl:when>
        <xsl:when test="string(@structureType) = 'topichead'">
          
          <xsl:if test="$debugBoolean">        
            <xsl:message> + [DEBUG] generateTopicrefs: Got a topic head. Level=<xsl:sequence select="string(@level)"/></xsl:message>
          </xsl:if>
          <xsl:variable name="topicheadType" select="if (@topicheadType) then string(@topicheadType) else 'topichead'"/>
          <xsl:variable name="topicmetaType" select="if (@topicmetaType) then string(@topicmetaType) else 'topicmeta'"/>
          <xsl:variable name="navtitleType" select="if (@navtitleType) then string(@navtitleType) else 'navtitle'"/>
          <xsl:element name="{$topicheadType}">
            <xsl:element name="{$topicmetaType}">
              <xsl:apply-templates select="current-group()[1]"/>
            </xsl:element>
            <xsl:call-template name="generateTopicrefs">
              <xsl:with-param name="content" select="current-group()[position() > 1]" as="node()*"/>
              <xsl:with-param name="level" select="$level + 1" as="xs:integer"/>
            </xsl:call-template>
          </xsl:element>          
        </xsl:when>
        <xsl:when test="string(@structureType) = 'map' or string(@structureType) = 'mapTitle'">
          <xsl:if test="$debugBoolean">        
            <xsl:message> + [DEBUG] generateTopicrefs: Got a map-reference-generating map or map title. Level=<xsl:sequence select="string(@level)"/></xsl:message>
          </xsl:if>
          <xsl:variable name="mapRefType" as="xs:string"
          >
            <xsl:choose>
              <xsl:when test="@mapRefType != ''">
                <xsl:sequence select="string(@mapRefType)"/>
              </xsl:when>
              <xsl:when test="@rootTopicrefType != ''">
                <xsl:sequence select="string(@rootTopicrefType)"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$topicrefType"/>
              </xsl:otherwise>
            </xsl:choose>
            
          </xsl:variable>
          <xsl:variable name="mapUrl" as="xs:string">
            <xsl:variable name="mapTitleFragment" as="xs:string">
              <xsl:choose>
                <xsl:when test="contains(.,' ')">
                  <xsl:value-of select="replace(substring-before(.,' '),'[\p{P}\p{Z}\p{C}]','')"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="replace(.,'[\p{P}\p{Z}\p{C}]','')"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:value-of select="concat('map_', $mapTitleFragment, '_', generate-id(.), format-time(current-time(),'[h][m][s]'), '.ditamap')"/>
          </xsl:variable>
          <xsl:element name="{$mapRefType}">
            <xsl:attribute name="format" select="'ditamap'"/>
            <xsl:attribute name="navtitle" select="."/>
            <xsl:attribute name="href" select="$mapUrl"/>
            
            <xsl:for-each select="./*[string(@structureType) = 'topicTitle' and string(@level) = $level]">
              <xsl:call-template name="generateTopicrefs">
                <xsl:with-param name="content" select="current-group()[position() > 1]" as="node()*"/>
                <xsl:with-param name="level" select="$level + 1" as="xs:integer"/>
              </xsl:call-template>
            </xsl:for-each>
            
            
          </xsl:element>          
        </xsl:when>
        <xsl:when test="current-group()[position() = 1]">
          <!-- Ignore this stuff since it should be map metadata or ignorable stuff -->
        </xsl:when>
        <xsl:otherwise>
          <xsl:message> + [WARNING] generateTopicrefs: Shouldn't be here, first para=<xsl:sequence select="current-group()[1]"/></xsl:message>
        </xsl:otherwise>
      </xsl:choose>          
    </xsl:for-each-group>
    
  </xsl:template>
  <xsl:template name="generateTopicrefAtts">
    <xsl:param name="topicUrl"/>
    <xsl:attribute name="href" select="$topicUrl"/>
    <xsl:if test="@chunk">
      <xsl:copy-of select="@chunk"/>
    </xsl:if>
    <xsl:if test="@collection-type">
      <xsl:copy-of select="@collection-type"/>
    </xsl:if>
    <xsl:if test="@processing-role">
      <xsl:copy-of select="@processing-role"/>
    </xsl:if>
    
  </xsl:template>
  
  
 
  <!-- Generates topics and submaps. Generation of topicrefs in maps is handled by separate
       mode and processing pass.
    -->
  <xsl:template name="generateTopics">
    <xsl:param name="content" as="node()*"/>
    <xsl:param name="level" as="xs:integer"/>
    
    <!-- First paragraph is a special case because a first para
         may generate both a map and a topicref.
      -->
    <xsl:variable name="firstP" select="$content[1]" as="element()*"/>
    
    <xsl:for-each-group select="$content" 
      group-starting-with="*[(string(@structureType) = 'topicTitle' or string(@structureType) = 'map' or string(@structureType) = 'mapTitle') and
      string(@level) = string($level)]">
      <xsl:choose>
        <xsl:when test="string(@structureType) = 'topicTitle' and string(@secondStructureType) = 'mapTitle'">
          <xsl:call-template name="makeMap">
            <xsl:with-param name="content" select="current-group()" as="node()*"/>
            <xsl:with-param name="level" select="$level" as="xs:integer"/>
          </xsl:call-template>
          <xsl:call-template name="makeTopic">
            <xsl:with-param name="content" select="current-group()" as="node()*"/>
            <xsl:with-param name="level" select="$level" as="xs:integer"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="string(@structureType) = 'topicTitle'">
          <xsl:call-template name="makeTopic">
            <xsl:with-param name="content" select="current-group()" as="node()*"/>
            <xsl:with-param name="level" select="$level" as="xs:integer"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="string(@structureType) = 'map' or string(@structureType) = 'mapTitle'">
          <xsl:choose>
            <xsl:when test="count(. | $firstP) = 1">
              <xsl:choose>
                <xsl:when test="@topicrefType != ''">
                  <xsl:call-template name="makeTopic">
                    <xsl:with-param name="content" select="current-group()" as="node()*"/>
                    <xsl:with-param name="level" select="$level" as="xs:integer"/>
                  </xsl:call-template>
                </xsl:when>
                <xsl:otherwise/><!-- Just a map generator, ignore the paragraph -->
              </xsl:choose>              
            </xsl:when>
            <xsl:otherwise><!-- Not the first para, handle normally -->
              <xsl:call-template name="makeMap">
                <xsl:with-param name="content" select="current-group()" as="node()*"/>
                <xsl:with-param name="level" select="$level" as="xs:integer"/>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>          
        </xsl:when>
        <xsl:when test="current-group()[position() = 1]">
          <!-- Ignore this stuff since it should be map metadata or ignorable stuff -->
        </xsl:when>
        <xsl:otherwise>
          <xsl:message> + [WARNING] Shouldn't be here, first para=<xsl:sequence select="current-group()[1]"/></xsl:message>
        </xsl:otherwise>
      </xsl:choose>          
    </xsl:for-each-group>
    
  </xsl:template>
  
  <xsl:template name="makeTopic">
    <xsl:param name="content" as="node()+"/>
    <xsl:param name="level" as="xs:integer"/><!-- Level of this topic -->
    <xsl:variable name="firstP" select="$content[1]"/>
    <xsl:variable name="topicFileName" select="substring-before($firstP,' ')"/>
    <xsl:variable name="makeDoc" select="string($firstP/@topicDoc) = 'yes'" as="xs:boolean"/>
    
    <xsl:choose>
      <xsl:when test="$makeDoc">
        <xsl:variable name="topicUrl"
           as="xs:string"
           select="local:getResultUrlForTopic($firstP)"
        />
        
        <xsl:variable name="resultUrl" as="xs:string"
            select="relpath:newFile($outputDir,$topicUrl)"
        />
        
        <xsl:message> + [INFO] Creating new topic document "<xsl:sequence select="$resultUrl"/>"...</xsl:message>
        
        <xsl:variable name="formatName" select="$firstP/@topicType" as="xs:string?"/>
        <xsl:if test="not($formatName)">
          <xsl:message terminate="yes"> + [ERROR] No topicType= attribute for paragraph style <xsl:sequence select="string($firstP/@styleId)"/>, when topicDoc="yes".</xsl:message>
        </xsl:if>
        
        <xsl:variable name="format" select="key('formats', $formatName, $styleMapDoc)[1]"/>
        <xsl:if test="not($format)">
          <xsl:message terminate="yes"> + [ERROR] Failed to find output element with name "<xsl:sequence select="$formatName"/> specified for style <xsl:sequence select="string($firstP/@styleId)"/>.</xsl:message>
        </xsl:if>
        <xsl:result-document href="{local:getResultUrlForTopic($firstP)}"
          doctype-public="{$format/@doctype-public}"
          doctype-system="{$format/@doctype-system}"
          >
          <xsl:call-template name="constructTopic">
            <xsl:with-param name="content" select="$content"  as="node()*"/>
            <xsl:with-param name="level" select="$level" as="xs:integer"/>
          </xsl:call-template>
        </xsl:result-document>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="constructTopic">
          <xsl:with-param name="content" select="$content" as="node()*"/>
          <xsl:with-param name="level" select="$level" as="xs:integer"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Constructs the topic itself -->
  <xsl:template name="constructTopic">
    <xsl:param name="content" as="node()*"/>
    <xsl:param name="level" as="xs:integer"/>
    
    <xsl:variable name="initialSectionType" as="xs:string" select="string(@initialSectionType)"/>
    <xsl:variable name="firstP" select="$content[1]"/>
    <xsl:variable name="nextLevel" select="$level + 1" as="xs:integer"/>
 
    <xsl:if test="$debugBoolean">
      <xsl:message> + [DEBUG] constructTopic: firstP=<xsl:sequence select="local:reportPara($firstP)"/></xsl:message>
    </xsl:if>
    
    <xsl:variable name="topicType" as="xs:string"
      select="local:getTopicType($firstP)"
    />
    
    <xsl:variable name="bodyType" as="xs:string"
      select="
      if ($firstP/@bodyType)
      then $firstP/@bodyType
      else 'body'
      "
    />
    
    <xsl:variable name="prologType" as="xs:string"
      select="
      if ($firstP/@prologType and $firstP/@prologType != '')
      then $firstP/@prologType
      else 'prolog'
      "
    />
    
    <xsl:if test="$debugBoolean">
      <xsl:message> + [DEBUG] constructTopic: topicType="<xsl:value-of select="$topicType"/>"</xsl:message>
      <xsl:message> + [DEBUG] constructTopic: bodyType="<xsl:value-of select="$bodyType"/>"</xsl:message>
      <xsl:message> + [DEBUG] constructTopic: prologType="<xsl:value-of select="$prologType"/>"</xsl:message>
      <xsl:message> + [DEBUG] constructTopic: initialSectionType="<xsl:value-of select="$initialSectionType"/>"</xsl:message>
    </xsl:if>
    
    <xsl:variable name="nextLevel" select="$level + 1" as="xs:integer"/>
    
    <xsl:if test="$debugBoolean">
      <xsl:message> + [DEBUG] constructTopic: Creating topic element <xsl:value-of select="$topicType"/></xsl:message>
    </xsl:if>
    <xsl:element name="{$topicType}">
      <xsl:attribute name="id" select="generate-id($firstP)"/>
      <xsl:if test="$firstP/@topicOutputclass">
        <xsl:attribute name="outputclass" select="$firstP/@topicOutputclass"/>
      </xsl:if>
      <xsl:variable name="titleTagName" as="xs:string"
        select="if ($firstP/@tagName)
        then $firstP/@tagName
        else 'title'
        "
      />
      <xsl:if test="$debugBoolean">
        <xsl:message> + [DEBUG] constructTopic: Applying templates to firstP...</xsl:message>
      </xsl:if>      
      <xsl:apply-templates select="$firstP"/>
      <xsl:if test="$debugBoolean">
        <xsl:message> + [DEBUG] constructTopic: For-each-group on content...</xsl:message>
      </xsl:if>      
      <xsl:for-each-group select="$content[position() > 1]" 
        group-starting-with="*[string(@structureType) = 'topicTitle' and string(@level) = string($nextLevel)]">
        <xsl:if test="false() and $debugBoolean">
          <xsl:message> + [DEBUG] constructTopic: currentGroup[<xsl:sequence select="position()"/>]: <xsl:sequence select="current-group()"/></xsl:message>
        </xsl:if>      
        <xsl:choose>
            <xsl:when test="current-group()[position() = 1] and current-group()[1][string(@structureType) != 'topicTitle']">
              <!-- Prolog and body elements for the topic -->
            <!-- NOTE: can't process title itself here because we're using title elements to define
              topic boundaries.
            -->
            <xsl:apply-templates select="current-group()[string(@topicZone) = 'titleAlts']"/>        
            <xsl:apply-templates select="current-group()[string(@topicZone) = 'shortdesc']"/>             
            <xsl:if test=".[string(@topicZone) = 'prolog' or $level = 0]">
              <xsl:choose>
                <xsl:when test="$level = 0">
                  <xsl:element name="{$prologType}">
                    <!-- For root topic, can pull metadata from anywhere in the incoming document. -->
                    <xsl:apply-templates select="root($firstP)//*[string(@containingTopic) = 'root' and 
                      string(@topicZone) = 'prolog' and 
                      contains(@baseClass, ' topic/author ')]"/>                        
                    <xsl:apply-templates select="root($firstP)//*[string(@containingTopic) = 'root' and 
                      string(@topicZone) = 'prolog' and 
                      contains(@baseClass, ' topic/data ')
                      ]"/>                        
                  </xsl:element>                  
                </xsl:when>
                <xsl:when test="current-group()[string(@topicZone) = 'prolog' and not(@containingTopic)]">
                  <xsl:element name="{$prologType}">
                    <xsl:apply-templates select="current-group()[not(@containingTopic) and string(@topicZone) = 'prolog']"/>
                  </xsl:element>
                </xsl:when>
                <xsl:otherwise/><!-- Must be only root-level prolog elements in this non-root topic context -->
              </xsl:choose>
            </xsl:if>
            <xsl:if test="current-group()[string(@topicZone) = 'body']">
              <xsl:if test="$debugBoolean">        
                <xsl:message> + [DEBUG] current group is topicZone body</xsl:message>
              </xsl:if>
              <xsl:element name="{$bodyType}">
                <xsl:call-template name="handleSectionParas">
                  <xsl:with-param name="sectionParas" select="current-group()[string(@topicZone) = 'body']" as="element()*"/>
                  <xsl:with-param name="initialSectionType" select="$initialSectionType" as="xs:string"/>
                </xsl:call-template>
              </xsl:element>                  
            </xsl:if>
          </xsl:when>
          <xsl:otherwise>
            <xsl:if test="$debugBoolean">        
              <xsl:message> + [DEBUG] makeTopic(): Not topicZone prolog or body, calling makeTopic...</xsl:message>
            </xsl:if>
            <xsl:call-template name="makeTopic">
              <xsl:with-param name="content" select="current-group()" as="node()*"/>
              <xsl:with-param name="level" select="$level + 1" as="xs:integer"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>        
      </xsl:for-each-group>
    </xsl:element>      
  </xsl:template>
  
  <xsl:template name="handleSectionParas">
    <xsl:param name="sectionParas" as="element()*"/>
    <xsl:param name="initialSectionType" as="xs:string"/>
    
    <xsl:if test="$debugBoolean">
      <xsl:message> + [DEBUG] handleSectionParas: initialSectionType="<xsl:sequence select="$initialSectionType"/>"</xsl:message>
    </xsl:if>
    <xsl:for-each-group select="$sectionParas" group-starting-with="*[string(@structureType) = 'section']">
      <xsl:choose>
        <xsl:when test="current-group()[position() = 1] and string(@structureType) != 'section'">
          <xsl:choose>
            <xsl:when test="$initialSectionType != ''">
              <xsl:element name="{$initialSectionType}">
                <xsl:call-template name="handleBodyParas">
                  <xsl:with-param name="bodyParas" select="current-group()"/>
                </xsl:call-template>
              </xsl:element>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="handleBodyParas">
                <xsl:with-param name="bodyParas" select="current-group()"/>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>
          
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="sectionType" as="xs:string"
              select="if (@sectionType) then string(@sectionType) else 'section'"
          />
          <xsl:element name="{$sectionType}">
            <xsl:variable name="bodyParas"
              select="if (string(@useAsTitle) = 'no')
                         then current-group()[position() > 1]
                         else current-group()
                         
              "
            />
            <xsl:call-template name="handleBodyParas">
              <xsl:with-param name="bodyParas" select="$bodyParas"/>
            </xsl:call-template>
          </xsl:element>
        </xsl:otherwise>
      </xsl:choose>      
    </xsl:for-each-group>
  </xsl:template>
  
  <xsl:template name="handleBodyParas">
    <xsl:param name="bodyParas" as="element()*"/>
    
    <xsl:for-each-group select="$bodyParas" group-adjacent="boolean(@containerType)">
      <xsl:choose>
        <xsl:when test="@containerType">
          <xsl:choose>
            <xsl:when test="@containerOutputclass">
              <xsl:for-each-group select="current-group()" group-adjacent="@containerOutputclass">
                <xsl:variable name="containerGroup" as="element()">
                  <containerGroup containerType="{@containerType}" containerOutputclass="{@containerOutputclass}">
                    <xsl:sequence select="current-group()"/>
                  </containerGroup>
                </xsl:variable>
                <xsl:apply-templates select="$containerGroup"/>
              </xsl:for-each-group>
            </xsl:when>
            <xsl:otherwise>
              <xsl:variable name="containerGroup" as="element()">
                <containerGroup containerType="{@containerType}">
                  <xsl:sequence select="current-group()"/>
                </containerGroup>
              </xsl:variable>
              <xsl:apply-templates select="$containerGroup"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="current-group()"/>
        </xsl:otherwise>
      </xsl:choose>
      
    </xsl:for-each-group>
  </xsl:template>
  
  <xsl:template match="containerGroup">
<!--    <xsl:message> + [DEBUG] Handling groupContainer...</xsl:message>-->
    <xsl:call-template name="processLevelNContainers">
      <xsl:with-param name="context" select="*" as="element()*"/>
      <xsl:with-param name="level" select="1" as="xs:integer"/>
      <xsl:with-param name="currentContainer" select="'body'" as="xs:string"/>
    </xsl:call-template>    
  </xsl:template>
  
  <xsl:template name="processLevelNContainers">
    <xsl:param name="context" as="element()*"/>
    <xsl:param name="level" as="xs:integer"/>
    <xsl:param name="currentContainer" as="xs:string"/>
<!--    <xsl:message> + [DEBUG] processLevelNContainers, level="<xsl:sequence select="$level"/>"</xsl:message>
    <xsl:message> + [DEBUG]   currentContainer="<xsl:sequence select="$currentContainer"/>"</xsl:message>
-->    
    <xsl:for-each-group select="$context[@level = $level]" group-adjacent="@containerType">
<!--      <xsl:message> + [DEBUG]   @containerType="<xsl:sequence select="string(@containerType)"/>"</xsl:message>
      <xsl:message> + [DEBUG]   $currentContainer != @containerType="<xsl:sequence select="$currentContainer != string(@containerType)"/>"</xsl:message>
-->
      <xsl:choose>
        <xsl:when test="$currentContainer != string(@containerType)">
<!--          <xsl:message> + [DEBUG ]  currentContainer != @containerType, currentPara=<xsl:sequence select="local:reportPara(.)"/></xsl:message>-->
          <xsl:element name="{@containerType}">
            <xsl:if test="@containerOutputclass">
              <xsl:attribute name="outputclass" select="string(@containerOutputclass)"/>
            </xsl:if>
            <xsl:for-each select="current-group()">
              <xsl:call-template name="handleGroupSequence">
                <xsl:with-param name="level" select="$level" as="xs:integer"/>
              </xsl:call-template>
            </xsl:for-each>
          </xsl:element>
        </xsl:when>
        <xsl:otherwise>
          <xsl:for-each select="current-group()">
            <xsl:call-template name="handleGroupSequence">
              <xsl:with-param name="level" select="$level" as="xs:integer"/>
            </xsl:call-template>
          </xsl:for-each>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each-group>    
  </xsl:template>
  <xsl:template name="handleGroupSequence">
    <xsl:param name="level" as="xs:integer"/>
    <xsl:choose>
      <xsl:when test="string(@structureType) = 'dt' and @level = $level">
        <xsl:variable name="dlEntryType" as="xs:string"
          select="if (@dlEntryType) then string(@dlEntryType) else 'dlentry'"
        />
        <xsl:element name="{$dlEntryType}">
          <xsl:call-template name="transformPara"/>          
          <xsl:variable name="followingSibling" as="element()?" select="following-sibling::*[1]"/>
          <xsl:variable name="precedingSibling" as="element()?" select="preceding-sibling::*[1]"/>
          <xsl:choose>
            <xsl:when test="$followingSibling/@level &gt; @level">
              <xsl:for-each-group select="following-sibling::*" group-adjacent="@level">
                <xsl:if test="@level &gt; $level">
                  <xsl:element name="{@containerType}">
                  <xsl:for-each select="current-group()">
                    <xsl:choose>
                      <xsl:when test="string(@structureType) = 'dt'">
                        <xsl:variable name="nestedFollowingSibling" as="element()?" select="following-sibling::*[1]"/>
                        <xsl:variable name="dlEntryType" as="xs:string"
                          select="if (@dlEntryType) then string(@dlEntryType) else 'dlentry'"
                        />
                        <xsl:element name="{$dlEntryType}">
                          <xsl:call-template name="transformPara"/>
                          <xsl:for-each select="$nestedFollowingSibling">
                            <xsl:call-template name="transformPara"/>
                          </xsl:for-each>
                        </xsl:element>
                      </xsl:when>
                    </xsl:choose>
                  </xsl:for-each>
                </xsl:element>
                </xsl:if>
              </xsl:for-each-group>
            </xsl:when>
            <xsl:when test="$precedingSibling/@level &lt; @level"/>
              <xsl:otherwise>
                <xsl:for-each select="$followingSibling">
                  <xsl:call-template name="transformPara"/>
                </xsl:for-each>
              </xsl:otherwise>
          </xsl:choose>
          <!-- FIXME: This isn't going to handle nested paras within DD -->
        </xsl:element>
      </xsl:when>
      <xsl:when test="string(@structureType) = 'dd'"/><!-- Handled by dt processing -->
     <xsl:when test="following-sibling::*[1][@level &gt; $level]">
        <xsl:variable name="me" select="." as="element()"/>
        <xsl:element name="{@tagName}">
          <xsl:call-template name="transformParaContent"/>
          <xsl:call-template name="processLevelNContainers">
            <xsl:with-param name="context" 
              select="following-sibling::*[(@level = $level + 1) and 
              preceding-sibling::*[@level = $level][1][. is $me]]" as="element()*"/>
            <xsl:with-param name="level" select="$level + 1" as="xs:integer"/>
            <xsl:with-param name="currentContainer" select="@tagName" as="xs:string"/>
          </xsl:call-template>
        </xsl:element>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="transformPara"/>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>
  
  <xsl:template match="rsiwp:break" mode="p-content">
    <br/>
  </xsl:template>
  
  <xsl:template match="rsiwp:tab" mode="p-content">
    <tab/>
  </xsl:template>
  
  <xsl:template match="rsiwp:hyperlink" mode="p-content">
    <xsl:element name="{@tagName}">
      <!-- Not all Word hyperlinks become DITA hyperlinks: -->
      <xsl:if test="string(@structureType) = 'xref'">
        <xsl:attribute name="href" select="@href"/>
        <xsl:attribute name="scope" select="@scope"/>
      </xsl:if>
      <xsl:apply-templates mode="#current"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="rsiwp:image" mode="p-content">
    <art>
      <art_title><xsl:sequence select="string(@src)"/></art_title>
      <image href="{@src}">
        <alt><xsl:sequence select="string(@src)"/></alt>
      </image>
    </art>
  </xsl:template>
  
  <xsl:function name="local:isMap" as="xs:boolean">
    <xsl:param name="context" as="element()"/>
    <xsl:variable name="styleName" as="xs:string"
      select="$context/@style"
    />
    <xsl:choose>
      <xsl:when test="$styleName = '' or $styleName = '[None]'">
        <xsl:sequence select="false()"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="styleMap" as="element()?"
          select="key('styleMaps', $styleName, $styleMapDoc)[1]"
        />
        <xsl:sequence
          select="
          if ($styleMap)
          then ($styleMap/string(@structureType) = 'map' or
                $styleMap/string(@structureType) = 'mapTitle')
          else false()
          "
        />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:function name="local:isMapRoot" as="xs:boolean">
    <xsl:param name="context" as="element()"/>
    <xsl:variable name="styleName" as="xs:string"
      select="$context/@style"
    />
    <xsl:choose>
      <xsl:when test="$styleName = '' or $styleName = '[None]'">
        <xsl:sequence select="false()"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="styleMap" as="element()?"
          select="key('styleMaps', $styleName, $styleMapDoc)[1]"
        />
        <xsl:sequence
          select="
          if ($styleMap)
          then string($styleMap/@structureType) = 'map'
          else false()
          "
        />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:function name="local:isMapTitle" as="xs:boolean">
    <xsl:param name="context" as="element()"/>
    <xsl:variable name="styleName" as="xs:string"
      select="$context/@style"
    />
    <xsl:choose>
      <xsl:when test="$styleName = '' or $styleName = '[None]'">
        <xsl:sequence select="false()"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="styleMap" as="element()?"
          select="key('styleMaps', $styleName, $styleMapDoc)[1]"
        />
        <xsl:sequence
          select="
          if ($styleMap)
          then string($styleMap/@structureType) = 'mapTitle'
          else false()
          "
        />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:function name="local:isRootTopicTitle" as="xs:boolean">
    <xsl:param name="context" as="element()"/>
    <xsl:variable name="styleName" as="xs:string"
      select="$context/@style"
    />
    <xsl:choose>
      <xsl:when test="$styleName = '' or $styleName = '[None]'">
        <xsl:sequence select="false()"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="styleMap" as="element()?"
          select="key('styleMaps', $styleName, $styleMapDoc)[1]"
        />
        <xsl:sequence
          select="
          if ($styleMap)
          then (($styleMap/@level = '0') and ($styleMap/@structureType = 'topicTitle'))
          else false()
          "
        />
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:function>
  
  <xsl:function name="local:isTopicTitle" as="xs:boolean">
    <xsl:param name="context" as="element()"/>
    <xsl:variable name="styleId" as="xs:string"
      select="$context/@style"
    />
    <xsl:choose>
      <xsl:when test="$styleId = '' or $styleId = '[None]'">
        <xsl:sequence select="false()"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="styleMap" as="element()"
          select="key('styleMaps', $styleId, $styleMapDoc)[1]"
        />
        <xsl:sequence
          select="
          if ($styleMap)
          then $styleMap/@structureType = 'topicTitle'
          else false()
          "
        />
      </xsl:otherwise>
    </xsl:choose>    
  </xsl:function>
  
  <xsl:function name="local:getTopicType" as="xs:string">
    <xsl:param name="context" as="element()"/>
    <xsl:variable name="styleId" as="xs:string"
      select="$context/@style"
    />
    <xsl:if test="$debugBoolean">
      <xsl:message> + [DEBUG] local:getTopicType(): styleId="<xsl:value-of select="$styleId"/>"</xsl:message>
    </xsl:if>
    <xsl:choose>
      <xsl:when test="$styleId = '' or $styleId = '[None]'">
        <xsl:sequence select="'unknown-topic-type'"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="styleMap" as="element()"
          select="key('styleMaps', $styleId, $styleMapDoc)[1]"
        />
        <xsl:if test="$debugBoolean">
          <xsl:message> + [DEBUG] local:getTopicType(): styleMap="<xsl:sequence select="$styleMap"/>"</xsl:message>
        </xsl:if>
        <xsl:variable name="topicType"
          select="
          if ($styleMap and $styleMap/@topicType)
          then string($styleMap/@topicType)
          else 'unknown-topic-type'
          "
          as="xs:string"
        />
        <xsl:if test="$debugBoolean">
          <xsl:message> + [DEBUG] local:getTopicType(): returning "<xsl:value-of select="$topicType"/>"</xsl:message>
        </xsl:if>
        <xsl:sequence select="$topicType"/>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:function>

  <xsl:function name="local:getMapType" as="xs:string">
    <xsl:param name="context" as="element()"/>
    <xsl:variable name="styleId" as="xs:string"
      select="$context/@style"
    />
    <xsl:choose>
      <xsl:when test="$styleId = '' or $styleId = '[None]'">
        <xsl:sequence select="'unknown-map-type'"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="styleMap" as="element()"
          select="key('styleMaps', $styleId, $styleMapDoc)[1]"
        />
        <xsl:sequence
          select="
          if ($styleMap and $styleMap/@mapType)
          then string($styleMap/@mapType)
          else 'unknown-map-type'
          "
        />
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:function>
  
  <xsl:function name="local:getResultUrlForTopic" as="xs:string">
    <xsl:param name="context" as="element()"/>
    <xsl:variable name="topicRelativeUri" as="xs:string">
      <xsl:apply-templates mode="topic-url" select="$context"/>
    </xsl:variable>
    <!-- FIXME: This use of the outputDir parameter is a workaround for a bug
         in Saxon 9.1.0.7. It should not be necessary if the main result
         file has been set, which it always should be when this transform is
         run by RSuite.
      -->
    <xsl:variable name="result" as="xs:string"
      select="relpath:newFile($outputDir, $topicRelativeUri)"
    />
    <xsl:sequence select="$result"/>
  </xsl:function>

  <xsl:template match="rsiwp:p" mode="topic-url">   
    <xsl:variable name="topicTitleFragment" as="xs:string">
      <xsl:choose>
        <xsl:when test="contains(.,' ')">
          <xsl:value-of select="replace(substring-before(.,' '),'[\p{P}\p{Z}\p{C}]','')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="replace(.,'[\p{P}\p{Z}\p{C}]','')"/>
        </xsl:otherwise>
      </xsl:choose>
      </xsl:variable>
    <xsl:sequence select="concat('topics/topic_', $topicTitleFragment, '_', generate-id(.),format-time(current-time(),'[h][m][s]'), '.dita')"/>
  </xsl:template>
 
  
  <xsl:template match="rsiwp:*" mode="topic-url">
    <xsl:message> + [WARNING] Unhandled element <xsl:sequence select="name(..)"/>/<xsl:sequence select="name(.)"/> in mode 'topic-url'</xsl:message>
    <xsl:variable name="topicTitleFragment">
      <xsl:choose>
        <xsl:when test="contains(.,' ')">
          <xsl:value-of select="replace(substring-before(.,' '),'[\p{P}\p{Z}\p{C}]','')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="replace(.,'[\p{P}\p{Z}\p{C}]','')"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:sequence select="concat('topics/topic_', $topicTitleFragment, '_', generate-id(.),format-time(current-time(),'[h][m][s]'), '.dita')"/>
  </xsl:template>
  
  <xsl:function name="local:debugMessage">
    <xsl:param name="msg" as="xs:string"/>
    <xsl:message> + [DEBUG] <xsl:sequence select="$msg"/></xsl:message>
  </xsl:function>
  
  <xsl:function name="local:reportPara">
    <xsl:param name="para" as="element()?"/>
    <xsl:if test="$para">
      <xsl:sequence 
        select="concat('[', 
                       name($para),
                       ' ',
                       ' tagName=',
                       $para/@tagName,
                       if ($para/@level)
                          then concat(' level=', $para/@level)
                          else '',
                       if ($para/@containerType)
                          then concat(' containerType=', $para/@containerType)
                          else '',
                       if ($para/@containerOutputclass)
                          then concat(' containerOutputclass=', $para/@containerOutputclass)
                          else '',
                          ']',
                       substring(normalize-space($para), 1,20)
                       )"
      />
    </xsl:if>
  </xsl:function>
  
  <xsl:template match="rsiwp:*" priority="-0.5" mode="p-content">
    <xsl:message> + [WARNING] docx2dita[p-content]: Unhandled element <xsl:sequence select="name(..)"/>/<xsl:sequence select="name(.)"/></xsl:message>
  </xsl:template>
  
  <xsl:template match="rsiwp:*" priority="-0.5">
    <xsl:message> + [WARNING] docx2dita: Unhandled element <xsl:sequence select="name(..)"/>/<xsl:sequence select="name(.)"/></xsl:message>
  </xsl:template>

</xsl:stylesheet>
