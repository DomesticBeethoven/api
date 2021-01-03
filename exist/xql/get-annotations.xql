xquery version "3.1";

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

(: SUBDIRECTORY for testing  :)
let $data.basePath := $config:data-root||'p2/' 

  
let $files :=
  for $file in collection($data.basePath)//mei:mei
  let $id := $file/string(@xml:id)
  let $filename := $file/(@xml:id)
  

  
  let $title := $file//mei:titleStmt/mei:title/text()
  
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
      'on': $on
    }
   
   return

      map {
     '@context': 'http://iiif.io/api/presentation/2/context.json',
     'file.id': $id,
     '@id': $title || '/annotationList.json',
     '@type': 'sc:AnnotationList',
  	'resources': $annotations
      }

 return $files[1]