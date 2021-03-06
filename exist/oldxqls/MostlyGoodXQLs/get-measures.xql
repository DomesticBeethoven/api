xquery version "3.1";

(: Get the facsimile zones for each measure and convert to IIIF coordinates :)
(: Endpoint for MEASURES ...<fileID>/measures.json :)

import module namespace config="http://api.domestic-beethoven.eu/xql/config" at "config.xqm";

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace response="http://exist-db.org/xquery/response";

declare option exist:serialize "method=json media-type=application/json";

let $header-addition := response:set-header("Access-Control-Allow-Origin","*")

(: get database from configuration :)
let $database := collection($config:data-root)

(: get the ID of the requested document, as passed by the controller :)
let $document.id := request:get-parameter('document.id','')


let $file := $database//mei:mei[@xml:id = $document.id]


  let $id := $file/string(@xml:id)

  let $filename := $file/(@xml:id)
  let $uri := document-uri(root($file))
  let $title := $file//mei:title/text()
  
(: TBD surfaces = canvases :)

  let $zones :=
    for $zone in $file//mei:zone
    let $zone.id := $zone/string(@xml:id)
    let $type := $zone/string(@type)
    let $measure := $file//mei:measure[@facs='#'||$zone.id]
    let $measure.num := $measure/string(@n)
   
(: get facs coordinates and convert to IIIF coordinates :)  

    let $x1 := $file//mei:zone[@xml:id=$zone.id]/xs:int(@ulx)
    let $x2 := $file//mei:zone[@xml:id=$zone.id]/xs:int(@lrx)
    let $y1 := $file//mei:zone[@xml:id=$zone.id]/xs:int(@uly)
    let $y2 := $file//mei:zone[@xml:id=$zone.id]/xs:int(@lry)
    let $width := $x2 - $x1
    let $height := $y2 - $y1
   
    return map {
        'zone.id': $zone.id,
        'type': $type,
        'measure': $measure.num,
        'xywh' : $x1 || ',' || $y1 || ',' || $width || ',' ||  $height
    }
 
   return map {
  
      'file.id': $id,
      'title': $title,
      'description': 'List of measure zones',
      'resources': $zones,
      'document.id': $uri
   (: 'surface.id': $surface.id:)
   (: 'range': $range:)
   (: 'measure range' : $range.start || ' - ' || $range.end,:)
    
    }
