xquery version "3.1";

(:
This copy of get-measure-range is an attempt to process EMA 

    get-measures-all-docs.xql
    
    retrieve a RANGE of measures from ALL files in a folder
    
    plus facsimile COORDINATES

endpoint: .../<range>/<filename>/range.json


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
            'zone.id': $zone.id,
            'measure number': $measure.number,
            'xyhw' : $x1 || ',' || $y1 || ',' || $height || ',' || $width
         }
         
    
      return map {
         'measure.data': $measure.data
      }
   return $measures
   
return array {
   $range.sections
}
      
(:
    let $id := $file/string(@xml:id)
    
    
    let $start.index := xs:int($range.start) (\:$file//mei:measure[@n = $range.start]/xs:int(@n):\)
    let $end.index := xs:int($range.end) (\:$file//mei:measure[@n = $range.end]/xs:int(@n):\)
    let $relevant.measures := $all.measures[position() ge $start.index and position() le $end.index]
      let $measures :=
         for $measure in $relevant.measures
         let $measure.id := $measure/string(@xml:id)
         let $zone.id := $measure/substring-after(@facs, '#')
         let $measure.number := $measure/string(@n)
         let $start.index.correct := exists($all.measures[@n = $range.start])
         let $end.index.correct := exists($all.measures[@n = $range.end])
         
         
         (\: get facs coordinates and convert to IIIF coordinates :\)  

          let $x1 := $file//mei:zone[@xml:id=$zone.id]/xs:int(@ulx)
          let $x2 := $file//mei:zone[@xml:id=$zone.id]/xs:int(@lrx)
          let $y1 := $file//mei:zone[@xml:id=$zone.id]/xs:int(@uly)
          let $y2 := $file//mei:zone[@xml:id=$zone.id]/xs:int(@lry)
          let $height := $y2 - $y1
          let $width := $x2 - $x1
          let $measure.data := if($start.index.correct and $end.index.correct) then(
       
        map {
            'measure.id': $measure.id,
            'zone.id': $zone.id,
            'measure number': $measure.number,
            'xyhw' : $x1 || ',' || $y1 || ',' || $height || ',' || $width
        }
       ) else ( array {})
    
   return map {

   'measure.data': $measure.data
   }
:)
  
  (:return map {
    'id':$id,
    'range':$range,
    'measures': $measures

  }:)
             

