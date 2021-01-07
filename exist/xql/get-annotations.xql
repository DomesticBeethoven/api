xquery version "3.1";


(: Endpoint for .../<directory>/annotations.json 

Gets annotation list from each file in directory.

goes to <annot>, gets <measure xml:id> from @plist, then grabs zone id from @facs, and the coordinates from  <zone>

:)

import module namespace config="http://api.domestic-beethoven.eu/xql/config" at "config.xqm";

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option exist:serialize "method=json media-type=application/json";

(: set output to JSON:)
declare option output:method "json";
declare option output:media-type "application/json";

let $header-addition := response:set-header("Access-Control-Allow-Origin","*")

(: get the ID of the requested document, as passed by the controller :)
let $document.id := request:get-parameter('document.id','')

(: get database from configuration :)

let $database := collection($config:data-root)

(: get the requested DIRECTORY, as passed by the controller :)
let $folder := request:get-parameter('folder','')
let $data.basePath := $config:data-root||$folder || '/'
  

let $files :=
    for $file in collection($data.basePath)//mei:mei
      let $id := $file/string(@xml:id)
      let $filename := $file/string(@xml:id)   
      let $title := $file//mei:titleStmt/mei:title/text()
  
        let $annotations :=
          for $annot in $file//mei:annot
          let $annot.id := $annot/string(@xml:id)
          let $measure.id := $annot/substring-after(@plist, '#')
          let $zone.id := $file//mei:measure[@xml:id=$measure.id]/substring-after(@facs, '#')
          let $x1 := $file//mei:zone[@xml:id=$zone.id]/xs:int(@ulx)
          let $x2 := $file//mei:zone[@xml:id=$zone.id]/xs:int(@lrx)
          let $y1 := $file//mei:zone[@xml:id=$zone.id]/xs:int(@uly)
          let $y2 := $file//mei:zone[@xml:id=$zone.id]/xs:int(@lry)
          let $height := $y2 - $y1
          let $width := $x2 - $x1
          let $iiifid := $file/substring-before(@xml:id, '.') 
          let $on := 'http://127.0.0.1:8182/iiif/2/' || $iiifid || '#xywh=' || $x1 || ',' || $y1 || ',' || $width || ',' || $height 
          
(:        let $iiif.image :=    :)
          
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
    (: '@id': $title || '/annotationList.json', :)
     '@type': 'sc:AnnotationList',
  	'resources': $annotations
      }

 return $files