xquery version "3.0";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;


(: 
EMA =
GET /{identifier}/{measureRanges}/{stavesToMeasures}/{beatsToMeasures}/{completeness} 
For now:
/source/filename/measure-range/measures.json

ema range.start, range.end separated by comma :)


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

(: build from scratch. MEASURES == scratch.json :)

(: NB:  Request for measure range separated by commas in EMA :)


if(matches($exist:path,'/[\da-zA-Z-_\.]+/measures.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/get-measures.xql">
          (: pass in the UUID of the document passed in the URI :)
          <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 1]}"/>
          <add-parameter name="measure.range" value="{tokenize($exist:path,'/')[last() - 2]}"/>

        </forward>
    </dispatch>

) else

(: endpoint for getting annotations from an MEI file - annotations.json = get-annotation1a.xql :)
if(matches($exist:path,'/annotations.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/get-annotation1a.xql"/>
    </dispatch>


) else

(: endpoint for ANNOTATION LIST - annotlist.json = get-annotation3.xql :)
if(matches($exist:path,'/annotlist.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/get-annotation3.xql"/>
    </dispatch>

) else

(: endpoint for MEASURES - get-measures.xql :)
if(matches($exist:path,'/measures.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),


    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/get-measures.xql">
  
         (\:   pass in the UUID of the document passed in the URI :\)
  
            <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 1]}"/>
            <add-parameter name="measure.range" value="{tokenize($exist:path,'/')[last() - 2]}"/>

        </forward>
    </dispatch>

) else


(: example:  / mm 33-36 / meifile.mei / measures.json:)

(: endpoint for GET-RANGE  /range.json = get.measure-range.xql :)

if(matches($exist:path,'/range.json')) then (
    response:set-header("Access-Control-Allow-Origin", "*"),

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/xql/get-measure-range.xql">
  
         (\:   pass in the UUID of the document passed in the URI :\)
  
            <add-parameter name="document.id" value="{tokenize($exist:path,'/')[last() - 1]}"/>
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
