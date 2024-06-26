bgc_tileserver <- "https://tileserver.thebeczone.ca/data/BC_BGC/{z}/{x}/{y}.pbf"
bgc_tilelayer <- "BECMap"
district_tileserver <- "https://tileserver.thebeczone.ca/data/Districts/{z}/{x}/{y}.pbf"
district_tilelayer <- "Districts"

plugins <- {list(vgplugin = 
                   htmltools::htmlDependency(
                     name = "leaflet.vectorgrid",
                     version = "1.3.0",
                     src = "htmlwidgets",
                     script = "lfx-vgrid-prod.js"
                   )
)
}
registerPlugin <- function(map, plugin) {
  map$dependencies <- c(map$dependencies, list(plugin))
  map
}

addPlugins <- function(map) {
  map <- registerPlugin(map, plugins$vgplugin)
  map <- registerPlugin(map, plugins$sliderplugin)
  map
}

addBGCTiles <- function(map) {
  map <- registerPlugin(map, plugins$vgplugin)
  map <- htmlwidgets::onRender(map, paste0('
    function(el, x, data) {
      ', paste0("var subzoneColors = {", paste0("'", subzones_colours_ref$classification, "':'", subzones_colours_ref$colour,"'", collapse = ","), "}"), '
      L.bec_layer_opacity = 0.6
      
      var vectorTileOptions=function(layerName, layerId, activ,
                             lfPane, colorMap, prop, id) {
        return {
          vectorTileLayerName: layerName,
          interactive: activ, // makes it able to trigger js events like click
          vectorTileLayerStyles: {
            [layerId]: function(properties, zoom) {
              return {
                weight: 0,
                fillColor: colorMap[properties[prop]],
                fill: true,
                fillOpacity: L.bec_layer_opacity
              }
            }
          },
          pane : lfPane,
          getFeatureId: function(f) {
              return f.properties[id];
          }
        }
        
      };
      
      var subzLayer = L.vectorGrid.protobuf(
        "', bgc_tileserver, '",
        vectorTileOptions("bec_map", "', bgc_tilelayer, '", true,
                          "tilePane", subzoneColors, "BGC", "BGC")
      )
      this.layerManager.addLayer(subzLayer, "tile", "bec_map", "BGCs");
      
      //Now districts regions
      var vectorTileOptionsDist=function(layerName, layerId, activ,
                                     lfPane, prop, id) {
        return {
          vectorTileLayerName: layerName,
          interactive: true, // makes it able to trigger js events like click
          vectorTileLayerStyles: {
            [layerId]: function(properties, zoom) {
              return {
                weight: 0.5,
                color: "#000000",
                fill: true,
                fillOpacity: 0
              }
            }
          },
          pane : lfPane,
          getFeatureId: function(f) {
            return f.properties[id];
          }
        }
      };
      var distLayer = L.vectorGrid.protobuf(
        "', district_tileserver, '",
        vectorTileOptionsDist("Districts", "', district_tilelayer, '", true,
                          "tilePane", "dist_code", "dist_code")
      )
      this.layerManager.addLayer(distLayer, "tile", "Districts", "Districts")
      // end districts
      
      //highlight on click
      var styleHL = {
            weight: 1.5,
            color: "#fc036f",
            fillColor: "#FFFB00",
            fillOpacity: 1,
            fill: true
      };
      
      var selectedDists = [];
      distLayer.on("click", function(e){
        console.log("click");
        Shiny.setInputValue("dist_click",e.layer.properties.dist_code);
        selectedDists.push(e.layer.properties.dist_code);
        var properties = e.layer.properties
			  highlight = properties.dist_code;
        distLayer.setFeatureStyle(highlight, styleHL);
      });
      
      Shiny.addCustomMessageHandler("clearDist",function(x){
        selectedDists.forEach((ID) => {
          distLayer.resetFeatureStyle(ID);
        });
      });
      
      var selectedBGC = [];
      subzLayer.on("click", function(e){
        console.log(e.layer.properties);
        Shiny.setInputValue("bgc_click",e.layer.properties.BGC);
        selectedBGC.push(e.layer.properties.BGC);
        var properties = e.layer.properties
			  highlight = properties.BGC;
        subzLayer.setFeatureStyle(highlight, styleHL);
      });
      
      Shiny.addCustomMessageHandler("clearBGC",function(x){
        selectedBGC.forEach((ID) => {
          subzLayer.resetFeatureStyle(ID);
        });
      });
      
      
      subzLayer.bindTooltip(function(e) {
        return e.properties.BGC;
      }, {sticky: true, textsize: "10px", opacity: 1});
      
      distLayer.bindTooltip(function(e) {
        return e.properties.dist_name;
      }, {sticky: true, textsize: "10px", opacity: 1});
      
      Shiny.addCustomMessageHandler("selectDist",function(x){
          distLayer.bringToFront();
      });
      
      Shiny.addCustomMessageHandler("selectBGC",function(x){
          subzLayer.bringToFront();
      });

    }'
  ))
  map
}
