<div id="mapdiv"></div>
<script src="http://www.openlayers.org/api/OpenLayers.js"></script>
<script>
  map = new OpenLayers.Map("mapdiv");
  map.addLayer(new OpenLayers.Layer.OSM());

  dtypes = ["daily-rain", "daily-temperature", "daily-weather", "hourly-rain", "hourly-weather", "mean-wind", "radiation", "soil-temperature"];
  for (x of dtypes) {
      var pois = new OpenLayers.Layer.Text(x, {location:"markers/markers_"+x+"_201908.txt", projection: map.displayProjection});
      pois.setVisibility(true);
      map.addLayer(pois);

  }
// create layer switcher widget in top right corner of map.
  var layer_switcher= new OpenLayers.Control.LayerSwitcher({});
  map.addControl(layer_switcher);
  layer_switcher.maximizeControl();

// create layer switcher widget in top right corner of map.
  var layer_switcher= new OpenLayers.Control.LayerSwitcher({});
  map.addControl(layer_switcher);
  //Set start centrepoint and zoom
  var lonLat = new OpenLayers.LonLat(-3.173308, 55.921440 )
        .transform(
          new OpenLayers.Projection("EPSG:4326"), // transform from WGS 1984
          map.getProjectionObject() // to Spherical Mercator Projection
        );
  var zoom=16;
  map.setCenter (lonLat, zoom);

</script>
</body></html>
