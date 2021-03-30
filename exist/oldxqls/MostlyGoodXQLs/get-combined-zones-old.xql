xquery version "3.1";

(:
    get-measures-all-docs.xql
    
    retrieve a RANGE of measures from an MEI file
    
    plus COORDINATES of single bounding box on facsimile 

endpoint: .../<range>/zones.json

IIIF: X, Y, W, H

NB:  measure numbers matched to @n (as opposed to @label)


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

(: get the ID of the requested document, as passed by the controller :)
let $document.id := request:get-parameter('document.id','')

(: get the RANGE of the requested document, as passed by the controller :)
let $range := request:get-parameter('measure.range','')


let $range.start := xs:int(substring-before($range,'-'))
let $range.end   := xs:int(substring-after($range,'-'))

let $file := $database//mei:mei[@xml:id = $document.id]

let $host := 'http://localhost:3000/'

    let $all.measures := ($file//mei:measure)

    let $relevant.measures := $all.measures[position() ge $range.start and position() le $range.end]
    
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
      let $max.width := $max.lrx - $min.ulx
      let $max.height := $max.lry - $min.uly

      
      return map {
         'id': $surface/string(@xml:id),
         'xywh' : $min.ulx || ',' || $min.uly || ',' || $max.width || ',' || $max.height
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
      let $width := $x2 - $x1
      let $height := $y2 - $y1
      let $measure.data := 
         if($start.index.correct and $end.index.correct) 
         then(map {
            'measure.number': $measure.number,
            'measure.id': $measure.id,
            'zone.id': $zone.id,
            'measure number': $measure.number,
            'xywh' : $x1 || ',' || $y1 || ',' || $width || ',' || $height,
            'url': $host||$document.id||'#'||$x1 || ',' || $y1 || ',' || $width || ',' || $height
         }) 
         else ( array {})
       return map {
         'measure.data': $measure.data
       }
      
    
      
    return map {

      'range':$range,
      'measures': $measures,
      'pages': $relevant.pages,
      'hots': $host
    }             

