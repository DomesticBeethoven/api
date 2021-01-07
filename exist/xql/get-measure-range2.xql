xquery version "3.1";

(: Get facsimile zones for a specific RANGE of measures 
                        in a specific FILE 
                        and return IIIF coordinates 
                        
  ENDPOINT: .../<range>/<documentName>/range.json
  
          where "range" is separated by hyphen,
            and "documentName" is @xml:id of <mei> element of XML file
:)

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


(: get the ID of the requested document, as passed by the controller :)
let $document.id := request:get-parameter('document.id','')

(: get the RANGE of the requested document, as passed by the controller :)
let $range := request:get-parameter('measure.range','')


let $range.start := substring-before($range,'-')
let $range.end   := substring-after($range,'-')


(: get database from configuration :)
let $database := collection($config:data-root)

(: for $file in collection($data.basePath)//mei:mei :)

(: get file from database :)
let $file := $database//mei:mei[@xml:id = $document.id]

(:  let $id := $file/string(@xml:id):)

(:  let $filename := $file/(@xml:id):)


  let $title := $file//mei:fileDesc/mei:titleStmt/mei:title/text()
  let $surface := $file//mei:facsimile/mei:surface
  let $surface.id := $surface/string(@xml:id)
  let $annot := $file//mei:notesStmt/mei:annot/mei:p/text()
  let $meiHead := $file//mei:meiHead/string(@xml:id) 
  let $measure1 := $file//mei:measure[@label = 1]/string(@xml:id)
  
  let $all.measures := ($file//mei:measure)
  let $start.index := $file//mei:measure[@label = $range.start]/xs:int(@label)
  let $end.index := $file//mei:measure[@label = $range.end]/xs:int(@label)
  let $measure.count := xs:int($range.end) - xs:int($range.start) + 1
  let $relevant.measures := $all.measures[position() ge $start.index and position() le $end.index]
 
  
  (: for each relevant.measure, return id and coordinates of associated zone :)
  
    let $measures :=
       for $measure in $relevant.measures
       let $measure.id := $measure/string(@xml:id)
       let $zone.id := $measure/substring-after(@facs, '#')
       let $measure.number := $measure/string(@label)
       let $start.index.correct := exists($all.measures[@label = $range.start])
       let $end.index.correct := exists($all.measures[@label = $range.end])
       
       let $x1 := $file//mei:zone[@xml:id=$zone.id]/xs:int(@ulx)
       let $x2 := $file//mei:zone[@xml:id=$zone.id]/xs:int(@lrx)
       let $y1 := $file//mei:zone[@xml:id=$zone.id]/xs:int(@uly)
       let $y2 := $file//mei:zone[@xml:id=$zone.id]/xs:int(@lry)
       let $height := $y2 - $y1
       let $width := $x2 - $x1
    
       let $output := if($start.index.correct and $end.index.correct) then(
       
        map {
            'start.index.correct' : $start.index.correct,
            'end.index.correct' : $end.index.correct,
            'measure.id': $measure.id,
            'zone.id': $zone.id,
            'measure number': $measure.number,
             
             'xyhw' : $x1 || ',' || $y1 || ',' || $height || ',' || $width
        }
       ) else ( array {})
    
   return map {

   'output': $output
   }


(:      -=: Johannes's solution :=-

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

return map {
   'title': $title,
   'range': $range,
   'annot': $annot,
   'measure.count': $measure.count,
   'measures': $measures,
   'start.index' : $start.index,
   'relevant.measures': $relevant.measures

   }
   
   
   
   
   
   
   
   
   
