freedman_diconis_bins = (data) ->
	iqr = d3.quantile(data, 0.75) - d3.quantile(data, 0.25)
	h = 0.75*iqr/Math.pow(data.length, 1/3)
	range = data[data.length-1] - data[0]
	nbins = Math.floor range/h
	binw = range/nbins
	return ([i*binw+data[0], binw] for i in [1...nbins+1])

discretize = (bins, xy) ->
	i = 0
	bins = ({x: b[0], dx: b[1], y: []} for b in bins)
	for [x, y] in xy
		while x > bins[i].x
			i += 1
		bins[i].y.push [x, y]
	return bins

class @BlockHist
	constructor: (el) ->
		@topel = $(el)
		hack = $("""
			<table>
			<tr><td class="histogram_canvas" style="position: relative; width: 100%; height: 100%;"></td></tr>
			<tr><td class="axis">
			<div class="minval" style="float: left"/><div class="maxval" style="float: right"/>
			</td></tr>
			</table>
			""").appendTo(@topel)
		@el = hack.find(".histogram_canvas")
		@axis = hack.find(".axis")
		@colormap = (v) -> 'gray'
		@formatter = (v) -> v
	
	set_data: (values, labels) =>
		@data = _.zip values, labels
		@data = (d for d in @data when (not isNaN(d[0])))
		@data.sort (a, b) -> a[0] - b[0]

	_add_element: (size, pos, entry) =>
		p = (v) -> "#{v*100}%"
		
		el = @_bin_cache[entry[1]]
		if el
			delete @_bin_cache[entry[1]]
		else
			el = $("""<div class="bin"><div class="subbin"/></div>""").appendTo @el
		
		el.attr "data-bin-label", entry[1]
		el.data "bin-label", entry[1]
		el.data "bin-value", entry[0]
		style =
			left: p pos[0]
			bottom: p pos[1]
			width: p size[0]
			height: p size[1]
			"background-color": @colormap entry[0]
			position: "absolute"
			transition: [
				"width 0.25s ease-out 0s",
				"height 0.25s ease-out 0s",
				"left 0.5s ease-out 0s",
				"bottom 0.5s ease-out 0s"
				"background-color 0.1s linear #{0.5+pos[0]*0.5}s"
				]
		el.css style
		
	
	draw: =>
		# TODO: Refresh selection
		@_bin_cache = {}
		for bin in @el.find('.bin')
			@_bin_cache[$(bin).data "bin-label"] = $ bin
		[x, y] = _.zip @data...
		bins = freedman_diconis_bins x
		disc = discretize bins, @data
		@axis.find(".minval").text @formatter disc[0].y[0][0]
		@axis.find(".maxval").text @formatter disc[disc.length-1].y[disc[disc.length-1].y.length-1][0]
		max = Math.max (b.y.length for b in disc)...
		binh = 1.0/max
		binw = 1.0/disc.length
		size = [binw, binh]
		for bin, xi in disc
			x = xi * binw
			for entry, yi in bin.y
				y = yi * binh
				@_add_element size, [x,y], entry

		for key, bin of @_bin_cache
			bin.remove()

