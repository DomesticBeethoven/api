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

let $data.basePath := $config:data-root||'new/'


  
let $files :=
  for $file in collection($data.basePath)//mei:mei
  let $id := $file/string(@xml:id)
  
  let $annotations :=
    for $annot in $file//mei:annot[@xml:id]
    let $annot.id := $annot/string(@xml:id)     
    let $annot.text := normalize-space(string-join($annot//text(),' '))
    return map {
      '@id' : $annot.id,
      'chars': $annot.text,
      'check': 'CHECK xql loop'
    }


   let $title := $file//mei:titleStmt/mei:title/text()
  
   let $annot := $file//mei:annot/mei:p/text()

   let $zone := $file//mei:zone/string(@xml:id)

   let $annotID := $file//mei:annot/string(@xml:id)
  
   let $ulx := $file//mei:zone/string(@ulx)

   let $resource := map {

      '@type': 'cnt:ContentAsText',
      'format': 'text/plain',
      'motivation': 'oa:commenting',
      'chars': $annot

     }

   return

      map {
      
     'ulx': $ulx,     
     '@id': $annotID,
     '@type': 'oa:annotation',
     'motivation': 'oa:commenting',
  
     'title': $title||'.html',
     'zone': $zone,
     'annotations': $annotations,
  
  	'resource': $resource,
     'on': 'http://127.0.0.1:8182/iiif/2/page2.jpg#xywh=408,160,119,161'
      }

 return array { $files }