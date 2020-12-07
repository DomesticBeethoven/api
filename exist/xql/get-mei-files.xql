xquery version "3.1";

(:
    get-mei-files.xql

    This xQuery retrieves a list of all MEI files in the database
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

let $data.basePath := $config:data-root

let $files :=
  for $file in collection($data.basePath)//mei:mei
  let $id := $file/string(@xml:id)
  let $title := $file//mei:title[@type="editionTitle"]/text()
  let $annot := $file//mei:annot[@n="3"]/mei:p/text()





  let $surfaces :=
    for $surface in $file//mei:surface
    let $surface.id := $surface/string(@xml:id)
    let $surface.n := $surface/string(@n)
    let $surface.label := $surface/string(@label)
    let $surface.page := $surface/string(@page)
    let $graphic := $surface/mei:graphic[@type='iiif']
    let $iiif := $graphic/string(@target) || 'info.json'
    let $width := $graphic/string(@width)
    let $height := $graphic/string(@height)
    let $annots2 := $file//mei:annotationList/text()
    let $annots := 'annotations'
    let $annot := '"@type": "oa:Annotation"'
    let $bplate := 'some Boilerplate'

    return 
      map {
         'annot': $annot,
         'id': $surface.id,
         'n': $surface.n,
         'XQueryLabel': 'get-mei-files-xql',
         'surfaceLabel': $surface.label,
         'url': $iiif,
         'width': $width,
         'height': $height,
         'page': $surface.page,
         'annotations' : $annots,
         'Annotation File': $annots2
         
 }

      
      
      
  let $surfaces.array := array { $surfaces }
  let $var1 := map { 
      '@context': 'http://iiif.io/api/presentation/2/context.json',
      '@type': 'sc:Manifest',
      '@id': 'http://localhost:3000/page2.json',
      'grandchild': map {
         'Hello': 5
       }
}
      
  
  return

    map {
    
	'@id': 'http://55354df6-bb94-4706-ac17-1e51669d76d2',
	'@type': 'sc:Manifest',
	
	'label': 'Page 3',
	'child': $var1
	
(:
    'line1': $line1,
      'line2': $line2,
      'line3': $line3,
      'line4': $line4,
      'service1a': 'serviceValue',
      'id': $id,
      'attribution': 'Beethovens Werkstatt',    
      'title': $title,
      'surfaces': $surfaces.array,
      'service': 'serviceValue',
      'annot' : $annot
:)

}




 return array { $files } 