xquery version "3.1";

(:
    get-measures-all-docs.xql
    
    retrieve a RANGE of measures from ALL files in a folder
    
    plus facsimile COORDINATES

endpoint: .../<range>/<directory>/all-egs2.json

:)

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
let $range := request:get-parameter('measure.range','')


let $range.start := substring-before($range,'-')
let $range.end   := substring-after($range,'-')


let $file := $database//mei:mei[@xml:id = $document.id]

let $id := $file/string(@xml:id)
let $all.measures := ($file//mei:measure)
let $start.index := $file//mei:measure[@label = $range.start]/xs:int(@label)
let $end.index := $file//mei:measure[@label = $range.end]/xs:int(@label)
let $relevant.measures := 
   for $measure in $all.measures[position() ge $start.index and position() le $end.index]
      let $measure.id := $measure/string(@xml:id)
      let $zone.id := $measure/substring-after(@facs, '#')
      let $measure.number := $measure/string(@n)
      let $x1 := $file//mei:zone[@xml:id=$zone.id]/xs:int(@ulx)
      let $x2 := $file//mei:zone[@xml:id=$zone.id]/xs:int(@lrx)
      let $y1 := $file//mei:zone[@xml:id=$zone.id]/xs:int(@uly)
      let $y2 := $file//mei:zone[@xml:id=$zone.id]/xs:int(@lry)
      let $height := $y2 - $y1
      let $width := $x2 - $x1
      let $measure.data :=
      
       map {
         'measure.id': $measure.id,
         'zone.id': $zone.id,
         'measure number': $measure.number,
         'xyhw' : $x1 || ',' || $y1 || ',' || $height || ',' || $width
         }
    return map {
         'measure.data': $measure.data
         } 
(:
          let $x1 := $file//mei:zone[@xml:id=$zone.id]/xs:int(@ulx)
          let $x2 := $file//mei:zone[@xml:id=$zone.id]/xs:int(@lrx)
          let $y1 := $file//mei:zone[@xml:id=$zone.id]/xs:int(@uly)
          let $y2 := $file//mei:zone[@xml:id=$zone.id]/xs:int(@lry)
          let $height := $y2 - $y1
          let $width := $x2 - $x1
          let $measure.data := 
               map {
                   'measure.id': $measure.id,
                   'zone.id': $zone.id,
                   'measure number': $measure.number,
                   'xyhw' : $x1 || ',' || $y1 || ',' || $height || ',' || $width
               }
          

    
  return map {
    'id': $all.measures,
    'range':$range,
    'start': $start.index,
    'end': $end.index,
    'rel.measures': $relevant.measures

  }:)

return array { $relevant.measures }


 
(:let $files :=
  for $file in collection($data.basePath)//mei:mei
    let $id := $file/string(@xml:id)
    let $all.measures := ($file//mei:measure)
    let $start.index := $file//mei:measure[@label = $range.start]/xs:int(@label)
    let $end.index := $file//mei:measure[@label = $range.end]/xs:int(@label)
    let $relevant.measures := 
      for $measure in $all.measures[position() ge $start.index]
         let $measure.id := $measure/string(@xml:id)
         let $zone.id := $measure/substring-after(@facs, '#')
         let $measure.number := $measure/string(@n)
  

          let $x1 := $file//mei:zone[@xml:id=$zone.id]/xs:int(@ulx)
          let $x2 := $file//mei:zone[@xml:id=$zone.id]/xs:int(@lrx)
          let $y1 := $file//mei:zone[@xml:id=$zone.id]/xs:int(@uly)
          let $y2 := $file//mei:zone[@xml:id=$zone.id]/xs:int(@lry)
          let $height := $y2 - $y1
          let $width := $x2 - $x1
          let $measure.data := 
               map {
                   'measure.id': $measure.id,
                   'zone.id': $zone.id,
                   'measure number': $measure.number,
                   'xyhw' : $x1 || ',' || $y1 || ',' || $height || ',' || $width
               }
          

    
  return map {
    'id': $all.measures,
    'range':$range,
    'start': $start.index,
    'end': $end.index,
    'rel.measures': $relevant.measures

  }
:)