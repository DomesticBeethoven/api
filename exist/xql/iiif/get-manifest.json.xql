xquery version "3.1";

(:
    get-manifest.json.xql

    This xQuery retrieves a IIIF manifest for a given document ID
:)

(: import shared ressources, mainly path to data folder :)
import module namespace config="https://edirom.de/ns/config" at "../../xqm/config.xqm";
import module namespace iiif="https://edirom.de/iiif" at "../../xqm/iiif.xqm";

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace f = "http://local.link";
declare namespace map="http://www.w3.org/2005/xpath-functions/map";
declare namespace xi = "http://www.w3.org/2001/XInclude";

declare function f:addConditionally($map, $key, $data) as map(*) {
  if (exists($data)) then map:put($map, $key, $data) else $map
};

(: set output to JSON:)
declare option output:method "json";
declare option output:media-type "application/json";

(: allow Cross Origin Ressource Sharing / CORS :)
let $header-addition := response:set-header("Access-Control-Allow-Origin","*")

(: get database from configuration :)
let $database := collection($config:data-root)

(: get the ID of the requested document, as passed by the controller :)
let $document.id := request:get-parameter('document.id','')

let $document.uri := $config:iiif-basepath || 'document/' || $document.id || '/'

(: get file from database :)
let $file := ($database//mei:mei[@xml:id = $document.id] | $database//mei:facsimile[@xml:id = $document.id]/ancestor::mei:mei | $database//mei:manifestation[@xml:id = $document.id]/ancestor::mei:mei)
(: is this a link to a facsimile only, or to a document :)
let $is.facsimile.id := exists($file//mei:facsimile[@xml:id = $document.id])

(: build variable for file:)
let $file.context := 'https://iiif.io/api/presentation/2/context.json'
let $file.type := 'sc:Manifest'
let $id := $document.uri || 'manifest.json'
let $label := $file//mei:manifestation/mei:physLoc/mei:repository/mei:identifier[@auth = 'RISM']/text() || ' ' || $file//mei:manifestation/mei:physLoc/mei:identifier/text()
let $description := normalize-space(string-join($file//mei:fileDesc/mei:titleStmt/mei:composer//text(),' ')) || ': ' ||  string-join($file//mei:fileDesc/mei:titleStmt/mei:title//normalize-space(text()),' / ')
let $license := 'https://rightsstatements.org/vocab/CNE/1.0/' (: TODO: this should be made more specific, if possible :)
let $attribution := 'Domestic Beethoven'
let $viewingDirection := 'left-to-right'
let $viewingHint := 'paged'

(: if a specific facsimile was requested, get only that :)
let $relevantFacsimiles :=
    if($is.facsimile.id)
    then($file//mei:facsimile[@xml:id =  $document.id])
    else($file//mei:facsimile)

(: build variable for sequences :)
let $sequences :=
  for $facsimile in $relevantFacsimiles
  let $sequence.type := 'sc:Sequence'
  let $sequence.id := $document.uri || 'seq1'
  let $sequence.viewingDir := 'left-to-right'

  (: build variables for canvases = surfaces :)
  let $canvases :=
    for $canvas at $canvas.index in $facsimile/mei:surface (: iiif:canvas matches mei:surface :)
    let $canvas.id := $document.uri || 'canvas/' || (if($canvas/@xml:id) then($canvas/@xml:id) else($canvas.index))
    let $canvas.type := 'sc:Canvas'
    let $canvas.label :=
        if($canvas/@label)
        then($canvas/string(@label))
        else if($canvas/@n)
        then($canvas/string(@n))
        else(string($canvas.index))

    let $canvas.width := $canvas/mei:graphic[@width][1]/xs:integer(@width)
    let $canvas.height := $canvas/mei:graphic[@height][1]/xs:integer(@height)
    let $folium := (
        $file//mei:folium[(@recto = '#' || $canvas/@xml:id) or (@verso = '#' || $canvas/@xml:id)] |
        $file//mei:bifolium[(@inner.recto = '#' || $canvas/@xml:id) or (@inner.verso = '#' || $canvas/@xml:id) or (@outer.recto = '#' || $canvas/@xml:id) or (@outer.verso = '#' || $canvas/@xml:id)]
    )[1]

    (: build variables for images = graphics:)
    let $images :=
      for $image in $canvas/mei:graphic
      let $image.type := 'oa:Annotation'
      let $image.motivation := 'sc:painting'
      let $image.width := $image/xs:integer(@width)
      let $image.height := $image/xs:integer(@height)

      let $image.service :=
        if($folium/@width and $folium/@height and $folium/@unit)
        then(
            let $factor :=
                if($folium/@unit = 'mm')
                then(1)
                else if($folium/@unit = 'cm')
                then(10)
                else if($folium/@unit = 'in')
                then(25.4)
                else(1)

            let $scale := round(xs:decimal($folium/@height) * xs:decimal($factor) div xs:decimal($canvas.height) * 10000) div 10000
            return map {
                '@id': $canvas.id || '_physdim',
                '@context': 'https://iiif.io/api/annex/services/physdim/1/context.json',
                'profile': 'https://iiif.io/api/annex/services/physdim',
                'physicalScale': $scale,
                'physicalUnits': 'mm'
            }
        )
        else()

      let $image.resource :=
        if(exists($image.service))
        then(iiif:getImageResourceWithService($image.width, $image.height, $image/string(@target), $image.service))
        else(iiif:getImageResource($image.width, $image.height, $image/string(@target)))


      let $image.on := $canvas.id
      return map {
        '@type': $image.type,
        'motivation': $image.motivation,
        'resource': $image.resource,
        'on': $image.on
      }

    let $otherContent :=

        let $zoneContent :=

            if($canvas/mei:zone)
            then(
                map {
                  '@id': $document.uri || 'list/' || (if($canvas/@xml:id) then($canvas/@xml:id) else($canvas.index)) || '_zones',
                  '@type': 'sc:AnnotationList',
                  'within': map {
                    '@id': $document.uri || 'layer/measureZones',
                    '@type': 'sc:Layer',
                    'label': 'measure positions'
                  }
                }
            )
            else()

        (: overlaysPlus/ has enriched SVG shapes, overlays/ has the plain file :)
        let $svgContent :=
            if($canvas/xi:include)
            then(
                map {
                    '@id': $document.uri || 'overlaysPlus/' || $canvas/xi:include/tokenize(normalize-space(@href),'/')[last()],
                    '@type': 'sc:AnnotationList',
                    'within': map {
                        '@id': $document.uri || 'layer/svgShapes',
                        '@type': 'sc:Layer',
                        'label': 'svg shapes'
                      }
                }
            )
            else()
        return array { $zoneContent, $svgContent }

    let $canvas.map :=
        map {
            '@id': $canvas.id,
            '@type': $canvas.type,
            'label': $canvas.label,
            'images': array { $images },
            'width': $canvas.width,
            'height': $canvas.height,
            'otherContent': $otherContent
        }

    return $canvas.map

  return map {
    '@id': $sequence.id,
    '@type': $sequence.type,
    'viewingDirection': $sequence.viewingDir,
    'canvases': array { $canvases }
  }

(: content structures like movements :)
let $structures := iiif:getStructures_iiifPresentationAPI2($file, $document.uri)

return map {
  '@context': $file.context,
  '@type': $file.type,
  '@id': $id,
  'label': $label,
  'license': $license,
  'attribution': $attribution,
  'sequences': array { $sequences },
  'description': $description,
  'structures': $structures,
  'viewingDirection': $viewingDirection,
  'viewingHint': $viewingHint
}
