xquery version "3.0";
(:     B I T H   :)

(: Variable names still need to be changed in controller.xql - all camel case :)

(: 

ENDPOINTS

iiif/documents.json
iiif/document/<filename>/manifest.json
<filename>/measures.json
<filename>/annotations.json
<filename>/annotlist.json
<filename>/<range>/range.json
<filename>/<range>/zones.json

TEST: get-measures2

:)



(:declare namespace exist="http://exist-db.org/xquery/response";
:)
declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;


(: LIST all documents in the database - documents.json = get-documents.xql :)
if(ends-with($exist:path,'/iiif/documents.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/get-documents.xql"/>
    </dispatch>

) else


(: retrieves a IIIF MANIFEST for a given document - manifest.json = get-manifest.json.xql :)
if(matches($exist:path,'/iiif/document/[\da-zA-Z-_\.]+/manifest.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/get-manifest.json.xql">
          (: pass in the UUID of the document passed in the URI :)
          <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 1]}"/>
        </forward>
    </dispatch>

) else

(: endpoint for MEASURES ...<fileID>/measures.json   - get-measures.xql :)
(: retrieves measure data and facs zones for ALL measures in a file :)

(: MAKE SURE this regex works for all possibilites (e.g. umlauts?) :)

if(matches($exist:path,'/[\da-zA-Z-_\.]+/measures.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/get-measures.xql">
  
         (\:   pass in the UUID of the document passed in the URI :\)
  
            <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 1]}"/>

        </forward>
    </dispatch>
) else

(: From BEETHOVENS WERKSTATT :)
(: retrieves a IIIF annotation list for the zones on a given page :)
(:if(matches($exist:path,'/iiif/document/[\da-zA-Z-_\.]+/list/[\da-zA-Z-_\.]+_zones$')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/iiif/get-measure-positions-on-page.xql">
          (\: pass in the UUID of the document passed in the URI :\)
          <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 2]}"/>
          <add-parameter name="canvas.id" value="{substring-before(tokenize($exist:path,'/')[last()],'_zones')}"/>
        </forward>
    </dispatch>:)
    
if(matches($exist:path,'/iiif/document/[\da-zA-Z-_\.]+/list/[\da-zA-Z-_\.]+_zones$')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/iiif/get-measure-positions-on-page.xql">
          (\: pass in the UUID of the document passed in the URI :\)
          <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 2]}"/>
          <add-parameter name="canvas.id" value="{substring-before(tokenize($exist:path,'/')[last()],'_zones')}"/>
        </forward>
    </dispatch>



(: endpoint for ANNOTATIONS ...<file.id>/annotations.json   - get-annotatins.xql :)
(: retrieves measure data and facs zones for ALL measures in a file :)

(: MAKE SURE this regex works for all possibilites (e.g. umlauts?) :)

if(matches($exist:path,'/[\da-zA-Z-_\.]+/annotations.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/get-annotations.xql">
  
         (\:   pass in the UUID of the document passed in the URI :\)
  
            <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 1]}"/>

        </forward>
    </dispatch>

) else

(: endpoint for ANNOTATION LIST - annotlist.json = get-annotation-list.xql :)
if(matches($exist:path,'/annotlist.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/get-annotation-list.xql">
  
         (\:   pass in the UUID of the document passed in the URI :\)
  
            <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 1]}"/>

         </forward>
    </dispatch>

) else


(: endpoint for EMA MEASURES 
   .../<filename>/<range>/measures.json = get-measure-range.xql :)

if(matches($exist:path,'/range.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/get-measure-range.xql">

            <add-parameter name="measure.range" value="{tokenize($exist:path,'/')[last() - 1]}"/>
            <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 2]}"/>

         </forward>
    </dispatch>

) else


(: endpoint for EMA: Measures and Staves 
   .../<filename>/<EMAmeasures>/<EMAstaves>/staves.json = get-ema-staves.xql :)
if(matches($exist:path,'/staves.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/get-ema-staves.xql">

            <add-parameter name="staves" value="{tokenize($exist:path,'/')[last() - 1]}"/>
            <add-parameter name="measure.range" value="{tokenize($exist:path,'/')[last() - 2]}"/>
            <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 3]}"/>

         </forward>
    </dispatch>
 
) else

(: endpoint for COMBINED ZONES 
   .../<filename>/<range>/zones.json = get-combined-zones.xql :)

if(matches($exist:path,'/zones.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/get-combined-zones.xql">

            <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 2]}"/>
            <add-parameter name="measure.range" value="{tokenize($exist:path,'/')[last() - 1]}"/>

         </forward>
    </dispatch>

) else

(: endpoint for index.html :)

if ($exist:path eq "/index.html") then (
    (: forward root path to index.xql :)
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <cache-control cache="yes"/>
    </dispatch>
)

(: all other requests are forwarded to index.html, which will inform about the available endpoints :)

else (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="index.html"/>
    </dispatch>
)
