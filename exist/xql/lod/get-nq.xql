xquery version "3.1";

(:
    get-nq.xql

    This xQuery retrieves a Linked Open Data version of an MEI file in NQ format
:)

(: import shared ressources, mainly path to data folder :)
import module namespace config="https://edirom.de/ns/config" at "../../xqm/config.xqm";
import module namespace lod="https://edirom.de/ns/lod" at "../../xqm/lod.xqm";

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

(: set output to JSON:)
declare option output:method "text";
declare option output:media-type "text/plain"; (: "application/octet-stream"; :)

(: allow Cross Origin Ressource Sharing / CORS :)
let $header-addition := response:set-header("Access-Control-Allow-Origin","*")

(: get database from configuration :)
let $database := collection($config:data-root)

(: get the ID of the requested document, as passed by the controller :)
let $document.id := request:get-parameter('document.id','')

(: get file from database :)
let $file := $database//mei:mei[@xml:id = $document.id]

let $file.id := $config:baseuri || 'id/' || $document.id
let $file.subject := '<' || $file.id || '>'

let $vivoScore.line := $file.subject || $lod:rdf.type || $lod:vivoScore || $lod:nq.eol

let $title := '"' || ($file//mei:manifestation/mei:titleStmt/mei:title[@type='main'])[1]/text() || '"'
(: let $title := "'"  || $file//mei:manifestation/mei:titleStmt/mei:title/text() || "'" :)
let $title.line := $file.subject || $lod:dce || $title || $lod:nq.eol

let $shortTitle := '"' || $file//mei:fileDesc/mei:titleStmt/mei:title[@type='desc']/text() || '"'
let $shortTitle.line := $file.subject || $lod:bibo.shortTitle || $shortTitle || $lod:nq.eol

let $work.auth := "<" || $file//mei:work/@auth.uri || ">"
let $arrangementOf.line := $file.subject || $lod:rdau.arrangementOf || $work.auth || $lod:nq.eol

let $repository := $file//mei:item/mei:physLoc/mei:repository/text()
let $shelfMark := $file//mei:item/mei:physLoc/mei:identifier/text()
let $siglum := '"' || $repository || ", " || $shelfMark || '"' 
let $siglum.line := $file.subject || $lod:wdt.inventoryNumber || $siglum || $lod:nq.eol

let $genre := "<" || $file//mei:expression/mei:identifier[@type='genre']/@auth.uri || ">"
let $genre.line := $file.subject || $lod:dbpedia.genre || $genre || $lod:nq.eol

let $perfRes.lines := 
   for $perfRes in $file//mei:expression/mei:perfMedium/mei:perfResList/mei:perfRes[@auth.uri and string-length(normalize-space(@auth.uri)) gt 0]
   let $perfRes.line := $file.subject || $lod:gndo.mediumOfPerformance || "<" || $perfRes/@auth.uri || '>' || $lod:nq.eol 
   return $perfRes.line
let $perfMedium := string-join($perfRes.lines,'')

let $pubPlace := 
    if ($file//mei:manifestation/mei:pubStmt/mei:pubPlace/mei:geogName/@auth.uri)
    then (
        "<" || $file//mei:manifestation/mei:pubStmt/mei:pubPlace/mei:geogName[@auth.uri and string-length(normalize-space(@auth.uri)) gt 0]/@auth.uri || ">"
    ) else if ($file//mei:manifestation/mei:pubStmt/mei:pubPlace/mei:geogName/text() and string-length($file//mei:manifestation/mei:pubStmt/mei:pubPlace/mei:geogName/normalize-space(text())) gt 0)
    then (
        '"' || $file//mei:manifestation/mei:pubStmt/mei:pubPlace/mei:geogName/normalize-space(text()) || '"'
    )
    else ()
let $pubPlace.line := 
    if ($pubPlace)
    then( $file.subject || $lod:rdau.placeOfPublication || $pubPlace || $lod:nq.eol)
    else()

let $pubDate := '"' || lod:resolveDateToString($file//mei:manifestation/mei:pubStmt/mei:date) || '"'
let $pubDate.line := $file.subject || $lod:gndo.dateOfPublication || $pubDate || $lod:nq.eol 

(: Originally, app pulled data from authority file if available. Current version of app 
does not support this, so $arranger.line was changed to return plain text content of 
<arranger> element (only) :)

(:
let $arranger.lines := 
    for $arranger in $file//mei:expression/mei:arranger/mei:persName[@auth.uri or (./text() and string-length(normalize-space(./text())) gt 0)]
    let $arranger.line := 
        if ($arranger/@auth.uri)
        then ($file.subject || $lod:gndo.arranger || '<' || $arranger/@auth.uri || '>' || $lod:nq.eol)
        else ($file.subject || $lod:gndo.arranger || '"' || $arranger/normalize-space(text()) || '"' || $lod:nq.eol)
    return $arranger.line
:)

let $arranger.lines := 
    for $arranger in $file//mei:expression/mei:arranger/mei:persName[@auth.uri or (./text() and string-length(normalize-space(./text())) gt 0)]
    let $arranger.line := ($file.subject || $lod:gndo.arranger || '"' || $arranger/normalize-space(text()) || '"' || $lod:nq.eol)
    return $arranger.line

let $publisher := 
    if ($file//mei:manifestation/mei:pubStmt/mei:publisher/mei:corpName/@auth.uri)
    then (
        '<' || $file//mei:manifestation/mei:pubStmt/mei:publisher/mei:corpName/@auth.uri|| '>'

    ) else if ($file//mei:manifestation/mei:pubStmt/mei:publisher/mei:corpName/text() and string-length($file//mei:manifestation/mei:pubStmt/mei:publisher/mei:corpName/normalize-space(text())) gt 0)
    then (
        '"' || $file//mei:manifestation/mei:pubStmt/mei:publisher/mei:corpName/normalize-space(text()) || '"'
    ) else if ($file//mei:manifestation/mei:pubStmt/mei:publisher/mei:persName/@auth.uri)
    then (
        '<' || $file//mei:manifestation/mei:pubStmt/mei:publisher/mei:persName/@auth.uri|| '>'

    ) else if ($file//mei:manifestation/mei:pubStmt/mei:publisher/mei:persName/text() and string-length($file//mei:manifestation/mei:pubStmt/mei:publisher/mei:persName/normalize-space(text())) gt 0)
    then (
        '"' || $file//mei:manifestation/mei:pubStmt/mei:publisher/mei:persName/normalize-space(text()) || '"'
    )
    else ()
let $publisher.line := 
    if ($publisher)
    then ($file.subject || $lod:dce.publisher || $publisher || $lod:nq.eol)
    else ()

let $publisherName := 
    if (starts-with($publisher, '<'))
    then (
        if ($file//mei:manifestation/mei:pubStmt/mei:publisher/mei:corpName/text() and string-length($file//mei:manifestation/mei:pubStmt/mei:publisher/mei:corpName/normalize-space(text())) gt 0)
        then (
            '"' || $file//mei:manifestation/mei:pubStmt/mei:publisher/mei:corpName/normalize-space(text()) || '"'
        )
        else if($file//mei:manifestation/mei:pubStmt/mei:publisher/mei:persName/text() and string-length($file//mei:manifestation/mei:pubStmt/mei:publisher/mei:persName/normalize-space(text())) gt 0)
        then (
            '"' || $file//mei:manifestation/mei:pubStmt/mei:publisher/mei:persName/normalize-space(text()) || '"'
        )
        else ()
    )
    else ()

let $publisherName.line := 
    if ($publisherName)
    then ($publisher || $lod:rdfs.label || $publisherName || $lod:nq.eol)
    else()

let $workComposer.auth := '<' || $file//mei:work/mei:composer/mei:persName/@auth.uri || '>'
let $workComposer.line := $work.auth || $lod:rdau.composer || $workComposer.auth || $lod:nq.eol

let $workComposerLabel := '"' || $file//mei:work/mei:composer/mei:persName/text() || '"'
let $workComposerLabel.line := $workComposer.auth || $lod:rdfs.label || $workComposerLabel || $lod:nq.eol

let $workIdentifier := '"' || $file//mei:work/mei:identifier[@type='opusNumber']/text() || '"'
let $workIdentifier.line := $work.auth || $lod:gndo.workIdentifier || $workIdentifier || $lod:nq.eol

let $workDateOfPublication := '"' || lod:getLatestDateAsString($file//mei:work/mei:creation/mei:date) || '"'
let $workDateOfPublication.line := $work.auth || $lod:gndo.dateOfPublication || $workDateOfPublication || $lod:nq.eol

let $workTitle := '"' || $file//mei:work/mei:title[@type='uniform']/text() || '"'
let $workTitle.line := $work.auth || $lod:rdfs.label || $workTitle || $lod:nq.eol

let $workShortTitle := '"' || $file//mei:work/mei:title[@type='abbreviated']/text() || '"'
let $workShortTitle.line := $work.auth || $lod:bibo.shortTitle || $workShortTitle || $lod:nq.eol

let $mei.lines := 
    if ($file//mei:measure//mei:note)
    then (
        let $mei.link := '<' || $config:file-basepath || $document.id || '.mei>'
        let $line.1 := $file.subject || $lod:frbr.embodiment || $mei.link || $lod:nq.eol
        let $line.2 := $mei.link || $lod:dct.format || '<http://www.music-encoding.org/ns/mei>' || $lod:nq.eol
        return $line.1 || $line.2
    )
    else ()

let $iiif.lines := 
    if ($file//mei:surface/mei:graphic/@target)
    then(
        let $iiif.link := '<' || $config:iiif-basepath || 'document/' || $document.id || '/manifest.json>'
        let $line.1 := $file.subject || $lod:frbr.embodiment || $iiif.link || $lod:nq.eol
        let $line.2 := $iiif.link || $lod:rdf.type || '<http://iiif.io/api/presentation/2#Manifest>' || $lod:nq.eol
        return $line.1 || $line.2
    )
    else ()

return 
   $vivoScore.line || 
   $title.line || 
   $shortTitle.line || 
   $arrangementOf.line || 
   $siglum.line || 
   $genre.line ||
   $perfMedium ||
   $pubPlace.line ||
   $pubDate.line ||
   string-join($arranger.lines, '') ||
   $publisher.line ||
   $publisherName.line ||
   $workComposer.line ||
   $workDateOfPublication.line ||
   $workTitle.line ||
   $workShortTitle.line ||
   $workComposerLabel.line ||
   $workIdentifier.line || 
   $mei.lines ||
   $iiif.lines
