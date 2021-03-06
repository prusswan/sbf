// layerData json structure: for future extension

var custom_layerData = {
  AgencyName: "LTA",
  Category: "Transit",
  FeatureType: "Point",
  FieldNames: "NAME,TOTALROOMS,KEEPERNAME,POSTALCODE,DESCRIPTION,ADDRESS,HYPERLINK",
  Icon: undefined,
  IconPath: "http://t1.onemap.sg/icons/HOTELS/",
  MapTipFieldName: "NAME",
  MaxLevel: "",
  MinLevel: "",
  RelatedTabName: "",
  calloutFieldName: "",
  calloutURL: "",
  color: "",
  lineThickness: "",
  outlineColor: "",
  pointColour: undefined,
  visibleFields: "1,0,0,1,0,1,1"
}

function loadScript(entry) {
  // alert(entry + $('#div_onemap').length + typeof dojo + $('#map_canvas').length + typeof google);
  getAddress();

  if (typeof google === 'undefined') {
    var script = document.createElement("script");
    script.type = "text/javascript";
    script.src = 'http://maps.googleapis.com/maps/api/js?v=3&libraries=places&sensor=false&callback=initGMap';
    document.body.appendChild(script);
  } else {
    initGMap();
  }

  // $.getScript("http://www.onemap.sg/API/JS?accessKEY=<%= Settings.onemap_api_key %>&v=2.8&type=full", function(data) {
  //   eval(data);
  //   window.dojo.addOnLoad(addressSearch);
  // });

  if (typeof dojo === 'undefined') {
    var script2 = document.createElement("script");
    script2.type = "text/javascript";
    script2.src = onemap_path;
    document.body.appendChild(script2);

    var script3 = document.createElement("script");
    script3.type = "text/javascript";
    script3.src = "http://t1.onemap.sg/om_js/arcgis_js_api/library/2.8/arcgis/js/default.js";
    document.body.appendChild(script3);


    script3.onreadystatechange = function() {
      if (this.readyState == 'complete' || this.readyState == 'loaded') this.onload({ target: this });
    };

    script3.onload = function(load) {
      /*init code here*/
      dojo.addOnLoad(initOneMap);
    };
  } else {
    dojo.addOnLoad(initOneMap);
  }

  // jQuery.ajax({
  //     async:false,
  //     type:'GET',
  //     url: "http://www.onemap.sg/API/JS?accessKEY=<%= Settings.onemap_api_key %>&v=2.8&type=full",
  //     data:null,
  //     success: om_success,
  //     dataType:'script'
  // });
}

//window.onload = loadScript('window');
$('body').bind('pjax:end',loadScript('pjax:end'));
// $('body').bind('pjax:end',dojo.addOnLoad(addressSearch));


// $(document).bind('pjax:success', function() {
//   jQuery.ajax({
//       async:false,
//       type:'GET',
//       url: "http://www.onemap.sg/API/JS?accessKEY=<%= Settings.onemap_api_key %>&v=2.8&type=full",
//       data:null,
//       success: om_success,
//       dataType:'script'
//   });
// });
//   loadScript;
//   //google.maps.event.addDomListener(window, 'load', initialize);
//   dojo.addOnLoad(addressSearch);
// });

// $(document).bind('pjax:popstate', function() {
//    $(document).bind('pjax:end', function(event) {
//         $(event.target).find('script').each(function() {
//             $.globalEval(this.text || this.textContent || this.innerHTML || '');
//         })
//    });
// });

function getAddress() {
  if (typeof address === 'undefined') address = $('#address').data("address");
  return address;
}

/*
  methods for Google Maps
*/

function initGMap() {
  // alert("loaded!");
  var address = getAddress();
  var yourAddress = address + ", Singapore";
  var geocoder = new google.maps.Geocoder();

  var mapOptions;

  infowindow = new google.maps.InfoWindow();

  geocoder.geocode({
    address: yourAddress
  }, function(locResult) {
    console.log(locResult, 'gmap_result');

    var center = locResult[0].geometry.location;

    mapOptions = {
      zoom: 18,
      center: center,
      mapTypeId: google.maps.MapTypeId.ROADMAP
    }

    map = new google.maps.Map(document.getElementById("map_canvas"),mapOptions);

    var marker = new google.maps.Marker({
      position: center,
      title: address,
      map: map,
    });

    var transitLayer = new google.maps.TransitLayer();
    transitLayer.setMap(map);

    var request = {
      location: center,
      radius: '1000',
      types: ['bus_station']
    };

    service = new google.maps.places.PlacesService(map);
    service.nearbySearch(request, callback);
  });

  // alert(google);
  // alert(dojo);
  // dojo.addOnLoad(addressSearch);
}

function callback(results, status) {
  if (status == google.maps.places.PlacesServiceStatus.OK) {
    console.log(results, 'places');
    for (var i = 0; i < results.length; i++) {
      var place = results[i];
      createMarker(results[i]);
    }
  }
}

function createMarker(place) {
  var placeLoc = place.geometry.location;
  var marker = new google.maps.Marker({
    map: map,
    position: place.geometry.location
  });

  google.maps.event.addListener(marker, 'click', function() {
    infowindow.setContent(place.name);
    infowindow.open(map, this);
  });
}

function overlayData(mashupResults)
{
  function hexToRgb(hex) {
    var result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    return result ? {
      r: parseInt(result[1], 16),
      g: parseInt(result[2], 16),
      b: parseInt(result[3], 16)
    } : null;
  }
  var results = mashupResults.results;
  console.log(mashupResults, 'bus_stops')

  if (results == "No results") {
    // alert("Theme not found. Please check theme name.");
    return
  }

  var featcount = mashupResults.count;
  var iconPath = mashupResults.iconPath;

  iconPath = 'http://www.publictransport.sg/img/bus.gif';
  var featType = mashupResults.featType;
  var theme = mashupResults.theme;

  themeGraphicsLayer.clear();
  var i;
  var xPnt;
  var yPnt;
  var xCord;
  var yCord;

  var pntArr = new Array();


  if (results.length==0){
    return
  }

  if (featType == "Point" || theme == 'Bus_Stop')
  {
    //process all the results
    for (i = 0; i < results.length; i++)
    {

      //create point graphic on map using generatePointGraphic function
      var PointGraphic=generatePointGraphic(results[i].XY,results[i].ICON_NAME,iconPath)
      //set graphic attributes
      PointGraphic.attributes=results[i]
      //add newly created graphic in graphiclayer
      themeGraphicsLayer.add(PointGraphic);
    }
  }
  else if (featType == "Polygon")
  {
    var polygon;
    for (i = 0;i < results.length; i++)
    {
      if(mashupResults.results[i].SYMBOLCOLOR !=undefined && mashupResults.results[i].SYMBOLCOLOR !="")
      {
        var polyColor = mashupResults.results[i].SYMBOLCOLOR;
        var r= hexToRgb(polyColor).r;
        var g= hexToRgb(polyColor).g;
        var b= hexToRgb(polyColor).b;
      }
      else if(mashupResults.results[i].SYMBOLCOLOR =="")
      {
        var r= 0;
        var g= 0;
        var b= 0;
      }
      pntArr = [];
      polygon = new esri.geometry.Polygon(new esri.SpatialReference({wkid:3414}));

      for (var x=0; x < results[i].XY.split("|").length; x++)
      {
        xCord = results[i].XY.split("|")[x].split(",")[0];
        yCord = results[i].XY.split("|")[x].split(",")[1];

        var PointLocation = new esri.geometry.Point(xCord, yCord, new esri.SpatialReference({ wkid: 3414 }))
        pntArr.push(PointLocation);
      }
      polygon.addRing(pntArr);

      gra = new esri.Graphic;
      gra.geometry = polygon;
      gra.attributes=results[i];

      var sfs = new esri.symbol.SimpleFillSymbol(esri.symbol.SimpleFillSymbol.STYLE_SOLID,
        new esri.symbol.SimpleLineSymbol(esri.symbol.SimpleLineSymbol.STYLE_SOLID,
          new dojo.Color([0,0,0]), 2),new dojo.Color([r,g,b,0.8]));

      gra.symbol = sfs;
      themeGraphicsLayer.add(gra);
    }
  }
  else if (featType == "Line")
  {
    var pLine;
    for (i = 0;i < results.length; i++)
    {
      if(mashupResults.results[i].SYMBOLCOLOR !=undefined && mashupResults.results[i].SYMBOLCOLOR !="")
      {
        var polyColor = mashupResults.results[i].SYMBOLCOLOR;
        var r= hexToRgb(polyColor).r;
        var g= hexToRgb(polyColor).g;
        var b= hexToRgb(polyColor).b;
      }
      else if(mashupResults.results[i].SYMBOLCOLOR =="")
      {
        var r= 0;
        var g= 0;
        var b= 0;
      }
      pntArr = [];
      pLine = new esri.geometry.Polyline(new esri.SpatialReference({wkid:3414}));

      for (var x=0; x < results[i].XY.split("|").length; x++)
      {
        xCord = results[i].XY.split("|")[x].split(",")[0];
        yCord = results[i].XY.split("|")[x].split(",")[1];

        var PointLocation = new esri.geometry.Point(xCord, yCord, new esri.SpatialReference({ wkid: 3414 }))
        pntArr.push(PointLocation);
      }
      pLine.addPath(pntArr);

      gra = new esri.Graphic;
      gra.geometry = pLine;
      gra.attributes = results[i];

      var sfs = new esri.symbol.SimpleLineSymbol(esri.symbol.SimpleLineSymbol.STYLE_SOLID,
        new dojo.Color([r,g,b]), 2);
      gra.symbol = sfs;
      themeGraphicsLayer.add(gra);
    }
  }
}


/*
  methods for OneMap
*/

function OverlayTheme(){
  // debugger;

   //var themeName = document.getElementById('txtTheme').value;
   var themeName = 'Bus_Stop';
   //themeName = 'Hotels';

    // if (themeName == "") {
    // alert('Please provide theme name')
    // return
    // }

    mashup = new MashupData();
    mashup.themeName = themeName;
    mashup.layerData = custom_layerData; // somehow this avoids the error triggerd in GetMashupData due to invalid layerData
    mashup.extent = OneMap.map.extent.xmin + "," + OneMap.map.extent.ymin + "," + OneMap.map.extent.xmax + "," + OneMap.map.extent.ymax;
    // mashup.extent = OneMap.map.extent;

    // (old) hack to prevent GetDataForCallout from breaking due to missing layerdata for Bus_Stop!
    //if ((obj.layerData == undefined) || (obj.layerData == "")) {
        // var extractData = new GetLayerInfoClass()
        // extractData.themeName = 'Hotels';
        // var extractedLayerData = extractData.ExtracLayerInfo(function(results) {
        //     mashup.layerData = results;
        // })
    //}
    console.log(mashup, 'mashup_layerdata');

    //add graphic layer
    themeGraphicsLayer = new esri.layers.GraphicsLayer();
    themeGraphicsLayer.id=themeName;
    OneMap.map.addLayer(themeGraphicsLayer);

    mashup.GetMashupData(overlayData);


    //resize info widnow
    OneMap.map.infoWindow.resize(300, 200);
    OneMap.map.infoWindow.hide();
    OneMap.onOneMapExtentChange(OverlayThemeOnExtentChnage)
    try{

      //set graphic onclick event
      dojo.connect(themeGraphicsLayer, "onClick", function(evt)
      {//debugger
          console.log(mashup, 'mashup');
          mashup.GetDataForCallout(evt.graphic,"",function(results)
          {//debugger
              var formattedResults=formatResultsBus(results);//mashup.formatResults(results);
              OneMap.map.infoWindow.setContent(formattedResults);
              $('a.busstop_code').bind('click', queryBusCode);

              OneMap.map.infoWindow.show(evt.screenPoint,OneMap.map.getInfoWindowAnchor(evt.screenPoint));
          });
      })
    }
    catch (err)
    {}
 }

function OverlayThemeOnExtentChnage(extent)
 {//debugger

    mashup.extent = extent.xmin + "," + extent.ymin + "," + extent.xmax + "," + extent.ymax;

    mashup.GetMashupData(overlayData)
}

function initOneMap() {
  //alert(typeof OneMap);
  // dojo.query('#div_onemap_infowindow').forEach(function(node){
  //   console.log(node,'dojo_node');
  //   dijit.byNode(node).destroyRecursive(true);
  // });

  // hack to remove orphaned dojo widget: div_onemap_infowindow
  var ids = ["div_onemap_infowindow"];
  dijit.registry.forEach(function(w){
    if(dojo.indexOf(ids,1)){ // 1 will be yourid it will get destroy
      w.destroyRecursive();
    }
  });

  addressSearch();
}

function queryBusCode() {
  code = $(this).attr('id');
  var busstop_link = $(this);
  var url = "http://www.onemap.sg/API/services.svc/busstop/" + code;
  $.ajax({
    url: url,
    dataType: "jsonp",
    success: function(data) {
      console.log(data,'bus_services');

      var services = $.map(data['Services'], function(n,i){
        return "<a class='busstop_route'>" + n.SERVICES + "</a>";
      });

      var services_div = "<div id='" + code + "'>" + services.join("|") + "</div>"
      busstop_link.replaceWith(services_div);

      $('a.busstop_route').bind('click', queryBusRoute);

      var layerList = OneMap.map.layerIds;
      for (var i=0; i<layerList.length; i++) {
        var layer = layerList[i]
        if (layer.indexOf("route_layer") == 0) OneMap.map.removeLayer(OneMap.map.getLayer(layer));
      }
    }
  });
}

function repaintPolyLine(layer) {
  //create a random color for the symbol
  var r = Math.floor(Math.random() * 250);
  var g = Math.floor(Math.random() * 100);
  var b = Math.floor(Math.random() * 100);

  var symbol = new esri.symbol.SimpleLineSymbol().setWidth(4).setColor(new dojo.Color([r,g,b]));

  var feature_layer = layer.getLayers()[0];
  var features = feature_layer.graphics;
  for (var i=0, il=features.length; i<il; i++) {
    //set symbol
    features[i].setSymbol(symbol);
  }

  dojo.connect(feature_layer,"onMouseOver",onMouseOverPolyLine);
}

function onMouseOverPolyLine(layer) {
  // alert('test!');
}

var testKML;

function queryBusRoute() {
  code = $(this).attr('id');
  service = $(this).text();
  var busstop_link = $(this);
  var strKMLURL = "http://www.publictransport.sg/kml/busroutes/";

  for(var i=0;i<2;i++) {
    var layer_id = 'route_layer_' + service + '_' + (i+1);
    if ($.inArray(layer_id, OneMap.map.layerIds) > -1) continue;

    var kmlUrl = strKMLURL + service + "-" + (i+1) + ".kml";
    var kml = new esri.layers.KMLLayer(kmlUrl,{
      // http://www.onemap.sg/api/help/JSCoordConvertor.aspx
      outSR: new esri.SpatialReference({ wkid: 3414 })
    });

    testKML = kml;

    // if (kml.loaded) {
    //   repaintPolyLine();
    // }
    // else {
    dojo.connect(kml,"onLoad",repaintPolyLine);

    kml.id = layer_id;
    OneMap.map.addLayer(kml);
  }
}

function formatResultsBus(resultObject) {
    //debugger;
    var nameVal = ""
    nameVal = nameVal + "<br/>"
    // to add Name on top
    for (var key in resultObject[0]) {
        switch (key) {
            case 'NAME':
                if (resultObject[0]["NAME"] != "") {
                    nameVal += "<strong>" + resultObject[0][key] + "</strong>" + "<br/>"
                    break;
                }
                else { break; }
            case 'BUS_STOP_CODE':
                if (resultObject[0][key] != "") {
                    var code = resultObject[0][key];
                    nameVal += "<br/><a id='" + code +"' class='busstop_code'>Services</a>" + "<br/>"
                    break;
                }
                else { break; }
        }
    }
    for (var key in resultObject[0]) {
        switch (key) {
            case 'NAME':
                if (resultObject[0]["NAME"] != "") {
                    break;
                }
                else { break; }
            case "PHOTOURL":
                if (resultObject[0]["PHOTOURL"] != "") {
                    break;
                }
                else { break; }
            case "ICON_NAME":
                if (resultObject[0]["ICON_NAME"] != "") {
                    break;
                }
                else { break; }
            case "XY":
                if (resultObject[0]["XY"] != "") {
                    break;
                }
                else { break; }
            case 'DESCRIPTION':
                if (resultObject[0]["DESCRIPTION"] != "") {
                    nameVal += resultObject[0]["DESCRIPTION"] + " "
                    break;
                }
                else { break; }
            case "HYPERLINK":
                if (resultObject[0]["HYPERLINK"] != "") {
                    nameVal += "<br/><a href=" + resultObject[0]["HYPERLINK"] + " target='_blank'>More Info</a>" + "<br/>"
                    break;
                }
                else { break; }
            case "ADDRESSSTREETNAME":
                if (resultObject[0]["ADDRESSSTREETNAME"] != "") {
                    nameVal += resultObject[0]["ADDRESSSTREETNAME"] + " "
                    break;
                }
                else { break; }
            case "ADDRESSFLOORNUMBER":
                if (resultObject[0]["ADDRESSFLOORNUMBER"] != "") {
                    nameVal += resultObject[0]["ADDRESSFLOORNUMBER"] + " "
                    break;
                }
                else { break; }
            case "ADDRESSBLOCKHOUSENUMBER":
                if (resultObject[0]["ADDRESSBLOCKHOUSENUMBER"] != "") {
                    nameVal += resultObject[0]["ADDRESSBLOCKHOUSENUMBER"] + " "
                    break;
                }
                else { break; }
            case "ADDRESSBUILDINGNAME":
                if (resultObject[0]["ADDRESSBUILDINGNAME"] != "") {
                    nameVal += resultObject[0]["ADDRESSBUILDINGNAME"] + " "
                    break;
                }
                else { break; }
            case "ADDRESSFLOORNUMBER":
                if (resultObject[0]["ADDRESSFLOORNUMBER"] != "") {
                    nameVal += resultObject[0]["ADDRESSFLOORNUMBER"] + " "
                    break;
                }
                else { break; }
            case "ADDRESSUNITNUMBER":
                if (resultObject[0]["ADDRESSUNITNUMBER"] != "") {
                    nameVal += resultObject[0]["ADDRESSUNITNUMBER"] + " "
                    break;
                }
                else { break; }
            case "ADDRESSPOSTALCODE":
                if (resultObject[0]["ADDRESSPOSTALCODE"] != "") {
                    nameVal += resultObject[0]["ADDRESSPOSTALCODE"] + " "
                    break;
                }
                else { break; }
            case "SYMBOLCOLOR":
                if (resultObject[0]["SYMBOLCOLOR"] != "") {
                    break;
                }
                else { break; }
            case "MAPTIP":
                if (resultObject[0]["MAPTIP"] != "") {
                    break;
                }
                else { break; }
            case "OBJECTID":
                if (resultObject[0]["OBJECTID"] != "") {
                    break;
                }
                else { break; }
            default:
                nameVal += resultObject[0][key] + "<br/>"
        }
    }
    // for photo to be on bottom
    for (var key in resultObject[0]) {
        switch (key) {
            case "PHOTOURL":
                if (resultObject[0]["PHOTOURL"] != "") {
                    nameVal += "<img src=" + resultObject[0]["PHOTOURL"] + "></img>" + "<br/>"
                    break;
                }
                else { break; }
        }
    }
    return nameVal

}

function addressSearch() {
  var basicSearch = new BasicSearch;
  basicSearch.searchVal = address;
  basicSearch.returnGeom = 1;
  basicSearch.GetSearchResults(function(resultData) {
    var results = resultData.results;
    console.log(results,'om_BasicSearch');
    omResults = results;
    var row = false;
    if (results=='No results') {
      // return false
    }
    else {
      row = results[0];
      // alert(row);
      // return row;
    }
    createMap(row);
  });
  // dojo.addOnLoad(createMap);
}

function createMap(center) {
  var levelNumber=8;
  var centerPoint="28968.103,33560.969"

  if (center != false) {
    centerPoint = center.X + ',' + center.Y;
  }

  OneMap = new GetOneMap('div_onemap','SM',{level:levelNumber,center:centerPoint});
  dojo.addOnLoad(OverlayTheme);

  if (center != false) {
    OneMap.showLocation(parseFloat(center.X),parseFloat(center.Y));
  }

  dojo.require("esri.layers.KMLLayer");
}
