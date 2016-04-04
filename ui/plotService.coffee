angular.module('myApp.services').service 'plotService', ->
  HSL_LIGHTNESS = 0.6
  HSL_SATURATION = 0.75
  NUM_GRID_LINES = 21
  @dynamicComponents = []

  parse_point = (c) ->
    new IMGPlotter.Vector3(
      parseFloat(c.x)
      parseFloat(c.y)
      parseFloat(c.z)
    )

  @update_projection = ->
    @plotter.removeComponent( c ) for c in @dynamicComponents
    @dynamicComponents = @bvol.getComponents(@scope.projection_mode.value)
      .concat(make_projection_plane(@contig_points, @scope.projection_mode.value, true, true))
    @plotter.addComponent( c ) for c in @dynamicComponents
    @plotter.render()
    return

  make_projection_plane = (points, zero_plane, b_draw_points, b_draw_lines) ->
    result = []
    if zero_plane < 0 or zero_plane > 2
      return result
    projected_points = points.map((v) ->v.clone())
    switch zero_plane
      when 0 then projected_points.map((v) ->v.setX 0)
      when 1 then projected_points.map((v) ->v.setY 0)
      else projected_points.map((v) ->v.setZ 0)
    if b_draw_lines
      line_color = (new IMGPlotter.Color).setHSL(0, 0, 0.8)
      lines = projected_points.map((v,i) ->
        new IMGPlotter.Line( line_color, [v, points[i]] )
      )
      result = result.concat(lines)
    if b_draw_points
      point_color = (new IMGPlotter.Color).setHSL(0,0,0.2)
      projected_point_series = new IMGPlotter.DataSeries(
        projected_points
        ->
          point_color
        ->
          4
        ->
          false
        null
        null
        null
      )
      result.push projected_point_series
    result

  get_hash = (color_mode) ->
    if color_mode >= 0 and color_mode <= 6
      #Taxon
      return (contig) ->
        taxon_array = contig.taxonomy.split(';')
        end = if taxon_array.length > color_mode then color_mode else taxon_array.length - 1
        taxon_array[0..end].join ';'
    else if color_mode == 7
      return (contig) ->
        if 'is_contam' of contig
          'Contaminant'
        else
          'Clean'
    else
      return (contig) ->
        'Unknown'

  make_color_map = (color_mode, contigs) ->
    f_hash = get_hash(color_mode)
    color_map = {}
    if color_mode < 7
      p_i = 0
      while p_i < contigs.length
        the_hash = f_hash(contigs[p_i])
        if !(the_hash of color_map) and the_hash != 'Unknown'
          color_map[the_hash] = new (THREE.Color)
        ++p_i
      num_colors = 0
      for taxon of color_map
        num_colors++
      taxon_i = 0
      taxon_sorted = (k for k,v of color_map).sort()
      for taxon of taxon_sorted
        color_map[taxon_sorted[taxon]].setHSL taxon_i / num_colors, HSL_SATURATION, HSL_LIGHTNESS
        taxon_i++
    else if color_mode == 7
      color_map.Clean = (new (THREE.Color)).setHSL(0.333, HSL_SATURATION, HSL_LIGHTNESS)
      color_map.Contaminant = (new (THREE.Color)).setHSL(0.0, HSL_SATURATION, HSL_LIGHTNESS)
    else
      #Unknown
    color_map.Unknown = new (THREE.Color)
    color_map.Unknown.setHSL 0.0, 0.0, HSL_LIGHTNESS
    color_map

  make_axes = (points, box) ->
    components = []
    line_color = (new IMGPlotter.Color).setHSL(0,0,0.8)
    components.push( new IMGPlotter.Line line_color, [[0,0,0],[box.max.z,0,0]].map((v) ->(new IMGPlotter.Vector3(v[0], v[1], v[2]))) )
    components.push( new IMGPlotter.Line line_color, [[0,0,0],[0,box.max.z,0]].map((v) ->(new IMGPlotter.Vector3(v[0], v[1], v[2]))) )
    components.push( new IMGPlotter.Line line_color, [[0,0,0],[0,0,box.max.z]].map((v) ->(new IMGPlotter.Vector3(v[0], v[1], v[2]))) )
    components.push( new IMGPlotter.SceneLabel new IMGPlotter.Vector3(box.max.z,0,0), 'PCA1' )
    components.push( new IMGPlotter.SceneLabel new IMGPlotter.Vector3(0,box.max.z,0), 'PCA2' )
    components.push( new IMGPlotter.SceneLabel new IMGPlotter.Vector3(0,0,box.max.z), 'PCA3' )
    components

  class BoundingVolume
    constructor: (points) ->
      @box = new (THREE.Box3)
      @box.setFromPoints points

    center: ->
      @box.center()

    getComponents: (zero_plane) ->
      result = []
      line_color = (new IMGPlotter.Color).setHSL(0,0,0.8)
      box_points = [
        new IMGPlotter.Vector3(@box.min.x, @box.min.y, @box.min.z)
        new IMGPlotter.Vector3(@box.min.x, @box.min.y, @box.max.z)
        new IMGPlotter.Vector3(@box.max.x, @box.min.y, @box.max.z)
        new IMGPlotter.Vector3(@box.max.x, @box.min.y, @box.min.z)
        new IMGPlotter.Vector3(@box.min.x, @box.max.y, @box.min.z)
        new IMGPlotter.Vector3(@box.min.x, @box.max.y, @box.max.z)
        new IMGPlotter.Vector3(@box.max.x, @box.max.y, @box.max.z)
        new IMGPlotter.Vector3(@box.max.x, @box.max.y, @box.min.z)
      ]
      plane_indices = [ [ 0,4,5,1 ],[ 1,2,6,5 ],[ 2,3,7,6 ],[ 3,0,4,7 ],[ 0,1,2,3 ],[ 4,5,6,7 ] ]
      #render bounding planes

      lerp = (a, b, alpha) ->
        b * alpha + a * (1 - alpha)

      for plane_i in [0..5]
        line_points = []
        for i in [0..3]
          line_points.push box_points[plane_indices[plane_i][i]]
        line_points.push box_points[plane_indices[plane_i][0]]
        result.push( new IMGPlotter.Line(line_color, line_points))

      origin_colors = [
        (new IMGPlotter.Color).setHSL(0, HSL_SATURATION, HSL_LIGHTNESS)
        (new IMGPlotter.Color).setHSL(0.33, HSL_SATURATION, HSL_LIGHTNESS)
        (new IMGPlotter.Color).setHSL(0.66, HSL_SATURATION, HSL_LIGHTNESS)
      ]
      #origin plane points
      origin_plane_points = [
        (box_points[i] for i in [0,4,5,1]).map((v) ->(new IMGPlotter.Vector3(0,v.y,v.z)))
        (box_points[i] for i in [0,1,2,3]).map((v) ->(new IMGPlotter.Vector3(v.x,0,v.z)))
        (box_points[i] for i in [0,3,7,4]).map((v) ->(new IMGPlotter.Vector3(v.x,v.y,0)))
      ]
      if zero_plane >= 0 and zero_plane <= 2
        #render zero-plane grid
        for i in [0...NUM_GRID_LINES]
          line_geom = []
          line_geom.push origin_plane_points[zero_plane][0].clone().lerp(origin_plane_points[zero_plane][3], i / (NUM_GRID_LINES - 1))
          line_geom.push origin_plane_points[zero_plane][1].clone().lerp(origin_plane_points[zero_plane][2], i / (NUM_GRID_LINES - 1))
          result.push new (IMGPlotter.Line)(origin_colors[zero_plane], line_geom)
        for i in [0...NUM_GRID_LINES]
          line_geom = []
          line_geom.push origin_plane_points[zero_plane][0].clone().lerp(origin_plane_points[zero_plane][1], i / (NUM_GRID_LINES - 1))
          line_geom.push origin_plane_points[zero_plane][3].clone().lerp(origin_plane_points[zero_plane][2], i / (NUM_GRID_LINES - 1))
          result.push new (IMGPlotter.Line)(origin_colors[zero_plane], line_geom)
      result

  @update_plot_colors = ->
    color_mode = @scope.color_taxon_level.value
    @color_map = make_color_map(color_mode, @data.contigs)
    @scope.update_legend @color_map
    if @dataSeries?
      @dataSeries.updateColors()
    if @plotter?
      @plotter.render()
    return

  @init = (@data, @scope) ->

    @contig_points = @data.contigs.map((v) ->parse_point(v))
    bv = new BoundingVolume(@contig_points)
    normalizer = 100 / (bv.box.max.z - bv.box.min.z)
    @contig_points.map((v) ->v.multiplyScalar(normalizer))

    @dataSeries = undefined
    @plotter = undefined

    @update_plot_colors()

    @selected = undefined

    @dataSeries = new IMGPlotter.DynamicDataSeries(
      @contig_points
      (p,i) =>
        @color_map[get_hash(@scope.color_taxon_level.value)(@data.contigs[i])]
      (p,i) =>
        if @data.contigs[i].is_contam?
          16
        else
          32
      ->
        false
      (p,i,cmp) => #onclick
        if @selected?
          cmp.setSelection(@selected, false)
        @selected = i
        cmp.setSelection(i, true)
        @scope.contig = @data.contigs[i]
        @scope.$apply()
        true
      null #onhover
      null #onrender
    )

    @bvol = new BoundingVolume(@contig_points)
    @plotter = new IMGPlotter.Plotter

    @plotter.addComponent( component ) for component in make_axes(@contig_points, @bvol.box)
    @plotter.addComponent @dataSeries

    bgcolor = new IMGPlotter.Color
    bgcolor.setHSL(0,0,1)
    @plotter.init(1024, 1024, bgcolor, 'plot_area')
    @update_projection()
    @plotter.run()
    return
