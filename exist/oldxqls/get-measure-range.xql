xquery version "3.1";

(:
This copy of get-measure-range is an attempt to process EMA 

    get-measures-all-docs.xql
    
    retrieve a RANGE of measures from a given file
    
    plus facsimile COORDINATES

endpoint: .../<filename>/<range>/measures.json

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
declare namespace functx = "http://www.functx.com";
declare function functx:is-a-number
  ( $value as xs:anyAtomicType? )  as xs:boolean {

   string(number($value)) != 'NaN'
 } ;

(: set output to JSON:)
declare option output:method "json";
declare option output:media-type "application/json";

(: allow Cross Origin Ressource Sharing / CORS :)
let $header-addition := response:set-header("Access-Control-Allow-Origin","*")

(: get database from configuration :)

let $database := collection($config:data-root)

(: get the ID of the requested document, as passed by the controller :)
let $document.id := request:get-parameter('document.id','')

let $file := $database//mei:mei[@xml:id = $document.id]

(: get the RANGE of the requested document, as passed by the controller :)
let $range := request:get-parameter('measure.range','')

let $all.measures := ($file//mei:measure)

let $range.sections := 
   for $range.section in tokenize(normalize-space($range),',')
   
   let $section.type :=
   
      if(contains($range.section,'-'))
      then('range')
      else('measure')
   let $relevant.measures := 
   
      if($range.section = 'all')
      then($all.measures)
      
      (:resolving individual measures, i.e. "…,5,…":)
      else if($section.type = 'measure')
      then($all.measures[position() = xs:int($range.section)])
      
      (:resolving measure ranges, i.e. "…,5-7,…":)
      else if($section.type = 'range')
      then(
         let $start := substring-before($range.section,'-')
         let $end   := substring-after($range.section,'-')
         let $range.start := if($start = 'start') then(1) else(xs:int($start))
         let $range.end := if($end = 'end') then(count($all.measures)) else(xs:int($end))
         return $all.measures[position() ge $range.start and position() le $range.end]
      )
      else()
    
    let $measures :=
      for $measure in $relevant.measures
      let $measure.id := $measure/string(@xml:id)
      let $zone.id := $measure/substring-after(@facs, '#')
      let $measure.number := $measure/string(@n)
      
      (:get facsimile image:)
      
      let $facs.graphic.id := $file//mei:surface[//@zone=$zone.id]/@xml:id
      (:get surface dimensions:)
      
      (: get facs coordinates and convert to IIIF coordinates :)  

      let $x1 := $file//mei:zone[@xml:id=$zone.id]/xs:int(@ulx)
      let $x2 := $file//mei:zone[@xml:id=$zone.id]/xs:int(@lrx)
      let $y1 := $file//mei:zone[@xml:id=$zone.id]/xs:int(@uly)
      let $y2 := $file//mei:zone[@xml:id=$zone.id]/xs:int(@lry)
      let $height := $y2 - $y1
      let $width := $x2 - $x1
      let $measure.data := 
         
         map {
            'measure.id': $measure.id,
            'facs.graphic.id': $facs.graphic.id,
            'zone.id': $zone.id,
            'measure number': $measure.number,
            'xywh' : $x1 || ',' || $y1 || ','  ||  $width  || ',' || $height
         }
         
    
      return map {
         'measure.data': $measure.data
      }
   return $measures
   
return array {
   $range.sections
}
      