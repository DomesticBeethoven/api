xquery version "3.1";

(: Get facsimile zones for a specified RANGE of measures and return IIIF coordinates :)

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

(: SUBDIRECTORY for testing single file :)
let $data.basePath := $config:data-root||'p2/'


(: get the ID of the requested document, as passed by the controller :)
let $document.id := request:get-parameter('document.id','')

(: get the RANGE of the requested document, as passed by the controller :)
let $range := request:get-parameter('measure.range','')


let $range.start := substring-before($range,'-')
let $range.end   := substring-after($range,'-')



(: get database from configuration :)
let $database := collection($config:data-root)


(: get file from database :)
let $file := $database//mei:mei[@xml:id = $document.id]

(:  let $id := $file/string(@xml:id):)

(:  let $filename := $file/(@xml:id):)


  let $title := $file//mei:fileDesc/mei:titleStmt/mei:title/text()
  let $surface := $file//mei:facsimile/mei:surface
  let $surface.id := $surface/string(@xml:id)
  let $all.zones := ($file//mei:zone)
  let $annot := $file//mei:notesStmt/mei:annot/text()

  
(:  
  
  let $all.measures := ($file//mei:measure)
  let $start.index := $all.measures[@label = $range.start][1]/position()
  let $end.index := $all.measures[@label = $range.end][1]/position()
  let $relevant.measures := $all.measures[position() ge $start.index and position() le $end.index]
  
  let $start.index.correct := exists($all.measures[@label = $range.start])
  
  let $output := if($start.index.correct and $end.index.correct) then(
  
   map {
   'rel measures': $start.index
   }
  
   
  ) else ( array {})
:)

(:  let $measures :=
    for $measure in $relevant.measures
    let $measure.id := $measure/string(@xml:id)
    
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
    'xyhw' : $x1 || ',' || $y1 || ',' || $height || ',' || $width,
    'range.start': $range.start,
    'all.measures': $all.measures
    }:)
    
return map {
   'title': $title,
   'zones': $all.zones,
   'range': $range,
   'range start': $range.start,
   'range end': $range.end,
   'annot': $annot

(:   'filename': $filename:)
   }
   
(:
   return

      map {
     
     'file.id': $id,
     'title': $title,
     'description': 'List of measure zones',
     'measure range' : $range.start || ' - ' || $range.end,
  	'resources': $zones,
  	'document.id': $uri,
  	'surface.id': $surface.id,
  	'range.start': $range.start
      }


 
 
 
  let $annotations :=
    for $annot in $file//mei:annot[@xml:id]
    let $annot.id := $annot/string(@xml:id)
    let $measure.id := $annot/substring-after(@plist, '#')
    let $zone.id := $file//mei:measure[@xml:id=$measure.id]/substring-after(@facs, '#')
    let $x1 := $file//mei:zone[@xml:id=$zone.id]/xs:int(@ulx)
    let $x2 := $file//mei:zone[@xml:id=$zone.id]/xs:int(@lrx)
    let $y1 := $file//mei:zone[@xml:id=$zone.id]/xs:int(@uly)
    let $y2 := $file//mei:zone[@xml:id=$zone.id]/xs:int(@lry)
    let $height := $y2 - $y1
    let $width := $x2 - $x1
    let $on := 'http://127.0.0.1:8182/iiif/2/' || $filename || '#xywh=' || $x1 || ',' || $y1 || ',' || $width || ',' || $height 
    
    let $annot.text := normalize-space(string-join($annot//text(),' '))
    let $resource := map {

      '@type': 'cnt:ContentAsText',
      'format': 'text:plain',
      'chars': $annot.text
      }

    return map {
      '@id' : $annot.id,
      '@type':"oa:Annotation",
      'motivation': 'oa:commenting',
      'resource': $resource,
      'on': $on,
    }
:)