xquery version "3.1";
(: import shared ressources, mainly path to data folder :)
import module namespace config="http://api.domestic-beethoven.eu/xql/config" at "config.xqm";

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

(: set output to JSON:)
declare option output:method "json";
declare option output:media-type "application/json";

(: allow Cross Origin Ressource Sharing / CORS :)
let $header-addition := response:set-header("Access-Control-Allow-Origin","*")

(: get database from configuration :)
let $database := collection($config:data-root)

(: get the ID of the requested document, as passed by the controller :)
let $document.id := request:get-parameter('document.id','')

(: get the RANGE of the requested document, as passed by the controller :)
let $range := request:get-parameter('range','')


let $range.start := substring-before($range,'-')
let $range.end   := substring-after($range,'-')




(: get database from configuration :)
let $database := collection($config:data-root)

let $document.uri := 'https://api.domestic-beethoven.eu/data/WoO32/' || $document.id || '/'

(: get file from database :)
let $file := $database//mei:mei[@xml:id = $document.id]

  let $id := $file/string(@xml:id)
  let $filename := $file/(@xml:id)
  let $uri := document-uri(root($file))
  let $title := $file//mei:fileDesc/mei:titleStmt/mei:title/text()
  let $surface := $file//mei:facsimile/mei:surface
  let $surface.id := $surface/string(@xml:id)

  let $zones :=
    for $zone in $file//mei:zone
    let $zone.id := $zone/string(@xml:id)
    let $type := $zone/string(@type)
    let $measure := $file//mei:measure[@facs='#'||$zone.id]
    let $measure.num := $measure/string(@n)
    
    let $x1 := $file//mei:zone[@xml:id=$zone.id]/xs:int(@ulx)
    let $x2 := $file//mei:zone[@xml:id=$zone.id]/xs:int(@lrx)
    let $y1 := $file//mei:zone[@xml:id=$zone.id]/xs:int(@uly)
    let $y2 := $file//mei:zone[@xml:id=$zone.id]/xs:int(@lry)
    let $height := $y2 - $y1
    let $width := $x2 - $x1
    

    return map {
       'zone.id': $zone.id,
       'type': $type,
       'measure': $measure.num,
       'x': $x1,
       'y': $y1,
       'height' : $height,
       'width' : $width,
       'xyhw' : $x1 || ',' || $y1 || ',' || $height || ',' || $width
       }

   return map {
     'file.id': $id,
     'title': $title,
     'description': 'List of measure zones',
     'measure range' : $range.start || ' - ' || $range.end,
  	'resources': $zones,
  	'document.id': $uri,
  	'surface.id': $surface.id,
  	'range': $range
      }