xquery version "3.1";

(: test to get position() and index working  :)

(: needs range. so actually more like /range.json endpoint:)

(: Get the facsimile zones for each measure and convert to IIIF coordinates :)

(: so actually getting the zones, and then finding the corresponding measure number :)

(: TBD surfaces = canvases :)


import module namespace config="http://api.domestic-beethoven.eu/xql/config" at "config.xqm";

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace functx = "http://www.functx.com";
declare option exist:serialize "method=json media-type=application/json";

let $header-addition := response:set-header("Access-Control-Allow-Origin","*")

(: get database from configuration :)
let $database := collection($config:data-root)

(: get the ID of the requested document, as passed by the controller :)
let $document.id := request:get-parameter('document.id','')

let $file := $database//mei:mei[@xml:id = $document.id]

(: get the RANGE of the requested document, as passed by the controller :)
let $range := request:get-parameter('measure.range','')

let $range.start := substring-before($range,'-')
let $range.end   := substring-after($range,'-')
 
(:let $surface.id := $surface/string(@xml:id):)

   let $all.measures := ($file//mei:measure)
   let $an.index := $all.measures[$range.end]/string(@xml:id)
   let $start.index := $all.measures[@label = $range.start]/position()
   let $end.index := $all.measures[@label = $range.end]/position()
   let $count := count($all.measures)
  
   let $new.index := $all.measures[@label = $range.start]
  
(:let $start.index := $all.measures[@label = $range.start][1]/position()
  let $end.index := $all.measures[@label = $range.end][1]/position()
  let $relevant.measures := $all.measures[position() ge $start.index and position() le $end.index]
  
  let $start.index.correct := exists($all.measures[@label = $range.start])
  
  let $output := if($start.index.correct and $end.index.correct) then(
  
   map {
   'rel measures': $start.index
   }
  
   
  ) else ( array {})
:)
let $file := $database//mei:mei[@xml:id = $document.id]


  let $id := $file/string(@xml:id)
  let $filename := $file/(@xml:id)
  let $uri := document-uri(root($file))
  let $title := $file//mei:title/text()
  


(:
  let $zones :=
   for $zone in $file//mei:zone
   let $zone.id := $zone/string(@xml:id)
   let $type := $zone/string(@type)
   let $measure := $file//mei:measure[@facs='#'||$zone.id]
   let $measure.num := $measure/string(@n)
   
(\: get facs coordinates and convert to IIIF coordinates :\)  

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
       'xyhw' : $x1 || ',' || $y1 || ',' || $height || ',' || $width
   }
 :) 
    return map {

     'file.id': $id,
     'an index': $an.index,
     'new index': $new.index,
     'count': $count,
     'title': $title,
     'start.index': $start.index,
     'end.index': $end.index,
     'description': 'List of measure zones',
(:  	'resources': $zones,:)
  	'document.id': $uri
(:  	'surface.id': $surface.id:)
(:  	'range': $range:)
(:     'measure range' : $range.start || ' - ' || $range.end,:)
    
    }

