xquery version "3.1";

(:
    get-measures-all-docs.xql
    
    retrieve a RANGE of measures from ALL files in a folder
    
    plus facsimile COORDINATES

endpoint: .../<range>/<directory>/all-egs.json

IIIF: X Y W H

NB:  measure numbers matched to @n (as opposed to @label)

BUT will need to be matched to INDEX because possibility of alphanumeric measure numbers
e.g.:  measure 43a

:)

(: import shared resources, mainly path to data folder :)
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

(: get the requested DIRECTORY, as passed by the controller :)
let $folder := request:get-parameter('folder','')
let $data.basePath := $config:data-root||$folder || '/'

(: get the RANGE of the requested document, as passed by the controller :)
let $range := request:get-parameter('measure.range','')

let $range.start := substring-before($range,'-')
let $range.end   := substring-after($range,'-')
 
let $files :=
    for $file in collection($data.basePath)//mei:mei
    let $id := $file/string(@xml:id)
    
    let $all.measures := ($file//mei:measure)
    let $start.index := $file//mei:measure[@n = $range.start]/xs:int(@n)
    let $end.index := $file//mei:measure[@n = $range.end]/xs:int(@n)
    let $relevant.measures := $all.measures[position() ge $start.index and position() le $end.index]
    let $relevant.zones := 
      for $measure in $relevant.measures
      let $zone.id := $measure/substring-after(@facs, '#')
      return $file//mei:zone[@xml:id=$zone.id]
    
    let $relevant.pages :=
      for $surface in $file//mei:surface[.//mei:zone[@xml:id = $relevant.zones/@xml:id]] 
      let $zones.on.this.page := $relevant.zones[@xml:id = $surface//mei:zone/@xml:id]
      
      let $min.ulx := min($zones.on.this.page/xs:int(@ulx))
      let $min.uly := min($zones.on.this.page/xs:int(@uly))
      let $max.lrx := max($zones.on.this.page/xs:int(@lrx))
      let $max.lry := max($zones.on.this.page/xs:int(@lry))
      let $max.height := $max.lry - $min.uly
      let $max.width := $max.lrx - $min.ulx
      
      return map {
         'id': $surface/string(@xml:id),
         'xyhw' : $min.ulx || ',' || $min.uly || ',' || $max.height || ',' || $max.width
      }
    
    let $measures :=
      for $measure in $relevant.measures
      let $measure.id := $measure/string(@xml:id)
      let $zone.id := $measure/substring-after(@facs, '#')
      let $measure.number := $measure/string(@n)
      let $start.index.correct := exists($all.measures[@n = $range.start])
      let $end.index.correct := exists($all.measures[@n = $range.end])
      
      (: get facs coordinates and convert to IIIF coordinates :)  

      let $x1 := $relevant.zones[@xml:id=$zone.id]/xs:int(@ulx)
      let $x2 := $relevant.zones[@xml:id=$zone.id]/xs:int(@lrx)
      let $y1 := $relevant.zones[@xml:id=$zone.id]/xs:int(@uly)
      let $y2 := $relevant.zones[@xml:id=$zone.id]/xs:int(@lry)
      let $height := $y2 - $y1
      let $width := $x2 - $x1
      let $measure.data := 
         if($start.index.correct and $end.index.correct) 
         then(map {
            'measure.id': $measure.id,
            'zone.id': $zone.id,
            'measure number': $measure.number,
            'xyhw' : $x1 || ',' || $y1 || ',' || $height || ',' || $width
         }) 
         else ( array {})
       return map {
         'measure.data': $measure.data
       }
      
    
      
    return map {
      'id':$id,
      'range':$range,
      'measures': $measures,
      'pages': $relevant.pages
    }             
    return array { $files }
