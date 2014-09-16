class @StatsMap
	constructor: (@map, @opts={}) ->
		#@layer = L.geoJson().addTo @map
		@layer = null
		@selection = []
	
	set_polygons: (@geojson, @getid) ->

	set_data: (data, @value_formatter = (v) -> v) ->
		@data = {}
		for [k, v] in data
			@data[k] = v
	
	set_selection: (@selection) => @render()

	render: =>
		if @layer and @layer._data != @geojson
			@map.removeLayer @layer
			@layer = null
		else if @layer and @layer.data == @data
			@layer.setStyle @styler
			
		if not @data or not @geojson
			return

		all_values = []
		for poly in @geojson.features
			pid = @getid poly
			if pid not of @data
				continue
			val = @data[pid]
			if isNaN val
				continue
			all_values.push val
		
		all_values.sort((a, b) -> a - b)
		min_value = all_values[0]
		max_value = all_values[all_values.length-1]
		# Creates a green (highest) to red (lowest) colormap
		value_to_color = new L.HSLHueFunction(
			new L.Point(min_value,0),
			new L.Point(max_value,120),
			outputSaturation: "75%")

		colorf = (val) -> value_to_color.evaluate val
		@colormap = colorf

		if @opts.legend_el
			set_colormap_legend $(@opts.legend_el),
				[min_value, max_value], colorf,
				formatter: @value_formatter
		
		@styler = (polygon) =>
			# Get the value and force it in to the color mapping range
			id = @getid polygon
			value = @data[id]
			if value < min_value
				value = min_value
			if value > max_value
				value = max_value
			# Specify the styling and coloring by value
			color = value_to_color.evaluate(value)
			style =
				stroke: true
				fill: true
				color: "white"
				fillColor: color
				fillOpacity: 0.7
				opacity: 1
				dashArray: '3'
				weight: 1
	
			layer = @layers_by_area[id]
			if id in @selection
				style.weight = 3
				style.color = "black"
				style.dashArray = ''
				layer.bringToFront()
			
			if not value? or isNaN(value)
				style.fillOpacity = 0.1
				return style
			
			if not layer
				return style

			if not @data_bounds
				@data_bounds = layer.getBounds()
			else
				@data_bounds.extend(layer.getBounds())
			
			
			return style
		
		@data_bounds = null
		if not @layer
			@layers_by_area = {}
			@layer = L.geoJson @geojson,
				style: @styler
				onEachFeature: (polygon, layer) =>
					bind_area = (event) =>
						layer.on event, (e) =>
							id = @getid e.target.feature
							$(@).trigger("area-#{event}",
								[id, @data[id], e])

					for e in ['mouseover', 'mouseout', 'click']
						bind_area e
					@layers_by_area[@getid polygon] = layer


	

			
			@layer.addTo @map
			@layer._data = @geojson
		else
			@layer.setStyle @styler
		
	fit_data_bounds: =>
		return if not @data_bounds
		@map.fitBounds @data_bounds
		

set_colormap_legend = ($el, range, colormap, opts={}) ->
	$el.empty()
	steps = opts.steps ? 10
	formatter = opts.formatter ? (v) -> v

	stepsize = (range[1] - range[0])/(steps-1)
	value = range[0]
	
	binheight = opts.binheight ? "10px"
	width = 100/steps + "%"
	
	scale = $("""<ul class="colormap_scale" style="clear: both;">""")
		.appendTo $el
	$el.append $ """
		<div style="float: left; width: 50%">#{formatter range[0]}</div>
		"""
	$el.append $ """
		<div style="float: right; width: 50%; text-align: right;">#{formatter range[1]}</div>
		"""

	
	binvalues = (range[0] + i*stepsize for i in [0...steps])
	for value in binvalues
		bin = $("""<li>""").appendTo scale
		bin.css
			"background-color": colormap(value)
			width: width
			height: binheight
			display: "block"
			float: "left"
			margin: 0
			padding: 0
		bin.prop "title", value
		value += stepsize
	
