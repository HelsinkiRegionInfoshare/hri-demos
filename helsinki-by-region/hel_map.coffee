@hel_leaflet_map = (element, mapopts={}) ->
    crs_name = 'EPSG:3879'
    proj_def = '+proj=tmerc +lat_0=0 +lon_0=25 +k=1 +x_0=25500000 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs'

    bounds = [25440000, 6630000, 25571072, 6761072]
    crs = new L.Proj.CRS.TMS crs_name, proj_def, bounds,
        resolutions: [256, 128, 64, 32, 16, 8, 4, 2, 1, 0.5, 0.25, 0.125, 0.0625]

    ###
    layer_name = "hel:orto2013"
    layer_fmt = "jpg"
    orto_layer = new L.Proj.TileLayer.TMS "http://geoserver.hel.fi/geoserver/gwc/service/tms/1.0.0/#{layer_name}@ETRS-GK25@#{layer_fmt}/{z}/{x}/{y}.#{layer_fmt}", crs,
        maxZoom: 11
        minZoom: 2
        continuousWorld: true
        tms: false
    ###

    orto_layer = L.tileLayer.wms "http://geoserver.hel.fi/geoserver/wms",
        layers: "hel:orto2013"
        format: "image/jpeg"

    map_layer = L.tileLayer.wms "http://geoserver.hel.fi/mapproxy/service",
        layers: "osm-sm"
        format: "image/png"
    
    # The old ugly map
    ###
    layer_name = "hel:Opaskartta"
    layer_fmt = "gif"
    map_layer = new L.Proj.TileLayer.TMS "http://geoserver.hel.fi/geoserver/gwc/service/tms/1.0.0/#{layer_name}@ETRS-GK25@#{layer_fmt}/{z}/{x}/{y}.#{layer_fmt}", crs,
        maxZoom: 12
        minZoom: 2
        continuousWorld: true
        tms: false
    ###
    
    crs = get_tm35_crs()
    # The new nice map
    #map_layer = make_tile_layer "http://geoserver.hel.fi/mapproxy/wmts/osm-sm/etrs_tm35fin/{z}/{x}/{y}.png"
    default_mapopts =
        crs: crs
        continuusWorld: true
        worldCopyJump: false
        zoomControl: true
        layers: [map_layer]
    
    #console.log _.extend(default_mapopts, mapopts)
    map = new L.Map element, _.extend(default_mapopts, mapopts)
        
    map.setView [60.171944, 24.941389], 5

    L.control.scale(imperial: false, maxWidth: 200).addTo map

    layer_control = L.control.layers
        'Opaskartta': map_layer
        'Ilmakuva': orto_layer
    
    return map: map, layer_control: layer_control

get_tm35_crs = ->
    crs_name = 'EPSG:3067'
    proj_def = '+proj=utm +zone=35 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs'

    bounds = L.bounds L.point(-548576, 6291456), L.point(1548576, 8388608)
    origin_nw = [bounds.min.x, bounds.max.y]
    crs_opts =
        resolutions: [8192, 4096, 2048, 1024, 512, 256, 128, 64, 32, 16, 8, 4, 2, 1, 0.5, 0.25]
        bounds: bounds
        transformation: new L.Transformation 1, -origin_nw[0], -1, origin_nw[1]
    
    crs = new L.Proj.CRS crs_name, proj_def, crs_opts
    return crs

# Adapted from https://github.com/City-of-Helsinki/servicemap/blob/master/src/map.coffee
make_tile_layer = (url, crs) ->
    opts =
        maxZoom: 15
        minZoom: 5
        continuousWorld: true
        tms: false

    map_layer = new L.TileLayer url, opts

    return map_layer

