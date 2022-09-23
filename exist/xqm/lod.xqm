xquery version "3.1";

module namespace lod="https://edirom.de/ns/lod";

(: import shared ressources, mainly path to data folder :)
import module namespace config="https://edirom.de/ns/config" at "./config.xqm";

declare namespace repo="http://exist-db.org/xquery/repo";
declare namespace expath="http://expath.org/ns/pkg";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace system="http://exist-db.org/xquery/system";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace map="http://www.w3.org/2005/xpath-functions/map";
declare namespace tools="http://edirom.de/ns/tools";

declare variable $lod:nq.eol := ' .
';

declare variable $lod:vivoScore := '<http://vivoweb.org/ontology/core#Score>';

declare variable $lod:rdf.type := ' <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> ';
declare variable $lod:dce := ' <http://purl.org/dc/elements/1.1/title> ';

declare variable $lod:bibo.shortTitle := ' <http://purl.org/ontology/bibo/shortTitle> ';
declare variable $lod:rdau.arrangementOf := ' <http://rdaregistry.info/Elements/u/P60242> ';
declare variable $lod:wdt.inventoryNumber := ' <https://www.wikidata.org/prop/direct/P217> ';
declare variable $lod:gndo.workIdentifier := ' <https://d-nb.info/standards/elementset/gnd#opusNumericDesignationOfMusicalWork> ';
declare variable $lod:dbpedia.genre := ' <https://dbpedia.org/ontology/genre> ';
declare variable $lod:gndo.mediumOfPerformance := ' <https://d-nb.info/standards/elementset/gnd#mediumOfPerformance> ';
declare variable $lod:rdau.placeOfPublication := ' <http://rdaregistry.info/Elements/u/P60163> ';
declare variable $lod:gndo.dateOfPublication := ' <https://d-nb.info/standards/elementset/gnd#dateOfPublication> ';
declare variable $lod:gndo.arranger := ' <https://d-nb.info/standards/elementset/gnd#arranger> ';
declare variable $lod:dce.publisher := ' <http://purl.org/dc/elements/1.1/publisher> '; 
declare variable $lod:dct.format := ' <http://purl.org/dc/terms/format> '; 
declare variable $lod:rdau.composer := ' <http://rdaregistry.info/Elements/u/P60426> ';
declare variable $lod:rdfs.label := ' <http://www.w3.org/2000/01/rdf-schema#label> ';
declare variable $lod:frbr.embodiment := ' <http://purl.org/vocab/frbr/core#embodiment> ';
declare variable $lod:iiif.manifest := ' <http://iiif.io/api/presentation/2#Manifest> ';
declare variable $lod:iiif.hasManifests := ' <http://iiif.io/api/presentation/2#hasManifests> ';

declare function lod:getLodLink($file.id as xs:string?) as xs:string? {
    if ($file.id)
    then(
        let $link := $config:baseuri || 'lod/' || $file.id || '.nq'
        return $link
    )
    else()
};

declare function lod:resolveDateToString($date as element(mei:date)) as xs:string {
   let $string :=
      if($date/@startdate and $date/@enddate)
      then($date/string(@startdate || '-' || $date/string(@enddate)))
      else if($date/@isodate)
      then($date/string(@isodate))
      else if($date/@startdate)
      then($date/string(@startdate) || '-?')
      else if($date/@enddate)
      then('?-' || $date/string(@enddate))
      else if($date/@notbefore and $date/@notafter)
      then('between ' || $date/string(@notbefore) || ' and ' || $date/string(@notafter))
      else if($date/@notbefore)
      then('not before ' || $date/string(@notbefore))
      else if($date/@notafter)
      then('not after ' || $date/string(@notafter))
      else('')
   return $string
};

declare function lod:getLatestDateAsString($date as element(mei:date)) as xs:string {
   let $string :=
      if($date/@enddate)
      then($date/string(@enddate))
      else if($date/@isodate)
      then($date/string(@isodate))
      else('')
   return $string
};

