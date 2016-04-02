angular.module('myApp.services').service('plotService', function() {
  var BoundingVolume, HSL_LIGHTNESS, HSL_SATURATION, NUM_GRID_LINES, get_hash, make_axes, make_color_map, make_projection_plane, parse_point;
  HSL_LIGHTNESS = 0.6;
  HSL_SATURATION = 0.75;
  NUM_GRID_LINES = 21;
  this.dynamicComponents = [];
  parse_point = function(c) {
    return new IMGPlotter.Vector3(300 * parseFloat(c.x), 300 * parseFloat(c.y), 300 * parseFloat(c.z));
  };
  this.update_projection = function() {
    var c, j, l, len, len1, ref, ref1;
    ref = this.dynamicComponents;
    for (j = 0, len = ref.length; j < len; j++) {
      c = ref[j];
      this.plotter.removeComponent(c);
    }
    this.dynamicComponents = this.bvol.getComponents(this.scope.projection_mode.value).concat(make_projection_plane(this.contig_points, this.scope.projection_mode.value, true, true));
    ref1 = this.dynamicComponents;
    for (l = 0, len1 = ref1.length; l < len1; l++) {
      c = ref1[l];
      this.plotter.addComponent(c);
    }
    this.plotter.render();
  };
  make_projection_plane = function(points, zero_plane, b_draw_points, b_draw_lines) {
    var line_color, lines, point_color, projected_point_series, projected_points, result;
    result = [];
    if (zero_plane < 0 || zero_plane > 2) {
      return result;
    }
    projected_points = points.map(function(v) {
      return v.clone();
    });
    switch (zero_plane) {
      case 0:
        projected_points.map(function(v) {
          return v.setX(0);
        });
        break;
      case 1:
        projected_points.map(function(v) {
          return v.setY(0);
        });
        break;
      default:
        projected_points.map(function(v) {
          return v.setZ(0);
        });
    }
    if (b_draw_lines) {
      line_color = (new IMGPlotter.Color).setHSL(0, 0, 0.8);
      lines = projected_points.map(function(v, i) {
        return new IMGPlotter.Line(line_color, [v, points[i]]);
      });
      result = result.concat(lines);
    }
    if (b_draw_points) {
      point_color = (new IMGPlotter.Color).setHSL(0, 0, 0.2);
      projected_point_series = new IMGPlotter.DataSeries(projected_points, function() {
        return point_color;
      }, function() {
        return 4;
      }, function() {
        return false;
      }, null, null, null);
      result.push(projected_point_series);
    }
    return result;
  };
  get_hash = function(color_mode) {
    if (color_mode >= 0 && color_mode <= 6) {
      return function(contig) {
        var end, taxon_array;
        taxon_array = contig.taxonomy.split(';');
        end = taxon_array.length > color_mode ? color_mode : taxon_array.length - 1;
        return taxon_array.slice(0, +end + 1 || 9e9).join(';');
      };
    } else if (color_mode === 7) {
      return function(contig) {
        if ('is_contam' in contig) {
          return 'Contaminant';
        } else {
          return 'Clean';
        }
      };
    } else {
      return function(contig) {
        return 'Unknown';
      };
    }
  };
  make_color_map = function(color_mode, contigs) {
    var color_map, f_hash, k, num_colors, p_i, taxon, taxon_i, taxon_sorted, the_hash, v;
    f_hash = get_hash(color_mode);
    color_map = {};
    if (color_mode < 7) {
      p_i = 0;
      while (p_i < contigs.length) {
        the_hash = f_hash(contigs[p_i]);
        if (!(the_hash in color_map) && the_hash !== 'Unknown') {
          color_map[the_hash] = new THREE.Color;
        }
        ++p_i;
      }
      num_colors = 0;
      for (taxon in color_map) {
        num_colors++;
      }
      taxon_i = 0;
      taxon_sorted = ((function() {
        var results;
        results = [];
        for (k in color_map) {
          v = color_map[k];
          results.push(k);
        }
        return results;
      })()).sort();
      for (taxon in taxon_sorted) {
        color_map[taxon_sorted[taxon]].setHSL(taxon_i / num_colors, HSL_SATURATION, HSL_LIGHTNESS);
        taxon_i++;
      }
    } else if (color_mode === 7) {
      color_map.Clean = (new THREE.Color).setHSL(0.333, HSL_SATURATION, HSL_LIGHTNESS);
      color_map.Contaminant = (new THREE.Color).setHSL(0.0, HSL_SATURATION, HSL_LIGHTNESS);
    } else {

    }
    color_map.Unknown = new THREE.Color;
    color_map.Unknown.setHSL(0.0, 0.0, HSL_LIGHTNESS);
    return color_map;
  };
  make_axes = function(points, box) {
    var components, line_color;
    components = [];
    line_color = (new IMGPlotter.Color).setHSL(0, 0, 0.8);
    components.push(new IMGPlotter.Line(line_color, [[0, 0, 0], [box.max.z, 0, 0]].map(function(v) {
      return new IMGPlotter.Vector3(v[0], v[1], v[2]);
    })));
    components.push(new IMGPlotter.Line(line_color, [[0, 0, 0], [0, box.max.z, 0]].map(function(v) {
      return new IMGPlotter.Vector3(v[0], v[1], v[2]);
    })));
    components.push(new IMGPlotter.Line(line_color, [[0, 0, 0], [0, 0, box.max.z]].map(function(v) {
      return new IMGPlotter.Vector3(v[0], v[1], v[2]);
    })));
    components.push(new IMGPlotter.SceneLabel(new IMGPlotter.Vector3(box.max.z, 0, 0), 'PCA1'));
    components.push(new IMGPlotter.SceneLabel(new IMGPlotter.Vector3(0, box.max.z, 0), 'PCA2'));
    components.push(new IMGPlotter.SceneLabel(new IMGPlotter.Vector3(0, 0, box.max.z), 'PCA3'));
    return components;
  };
  BoundingVolume = (function() {
    function BoundingVolume(points) {
      this.box = new THREE.Box3;
      this.box.setFromPoints(points);
    }

    BoundingVolume.prototype.center = function() {
      return this.box.center();
    };

    BoundingVolume.prototype.getComponents = function(zero_plane) {
      var box_points, i, j, l, lerp, line_color, line_geom, line_points, m, n, origin_colors, origin_plane_points, plane_i, plane_indices, ref, ref1, result;
      result = [];
      line_color = (new IMGPlotter.Color).setHSL(0, 0, 0.8);
      box_points = [new IMGPlotter.Vector3(this.box.min.x, this.box.min.y, this.box.min.z), new IMGPlotter.Vector3(this.box.min.x, this.box.min.y, this.box.max.z), new IMGPlotter.Vector3(this.box.max.x, this.box.min.y, this.box.max.z), new IMGPlotter.Vector3(this.box.max.x, this.box.min.y, this.box.min.z), new IMGPlotter.Vector3(this.box.min.x, this.box.max.y, this.box.min.z), new IMGPlotter.Vector3(this.box.min.x, this.box.max.y, this.box.max.z), new IMGPlotter.Vector3(this.box.max.x, this.box.max.y, this.box.max.z), new IMGPlotter.Vector3(this.box.max.x, this.box.max.y, this.box.min.z)];
      plane_indices = [[0, 4, 5, 1], [1, 2, 6, 5], [2, 3, 7, 6], [3, 0, 4, 7], [0, 1, 2, 3], [4, 5, 6, 7]];
      lerp = function(a, b, alpha) {
        return b * alpha + a * (1 - alpha);
      };
      for (plane_i = j = 0; j <= 5; plane_i = ++j) {
        line_points = [];
        for (i = l = 0; l <= 3; i = ++l) {
          line_points.push(box_points[plane_indices[plane_i][i]]);
        }
        line_points.push(box_points[plane_indices[plane_i][0]]);
        result.push(new IMGPlotter.Line(line_color, line_points));
      }
      origin_colors = [(new IMGPlotter.Color).setHSL(0, HSL_SATURATION, HSL_LIGHTNESS), (new IMGPlotter.Color).setHSL(0.33, HSL_SATURATION, HSL_LIGHTNESS), (new IMGPlotter.Color).setHSL(0.66, HSL_SATURATION, HSL_LIGHTNESS)];
      origin_plane_points = [
        ((function() {
          var len, m, ref, results;
          ref = [0, 4, 5, 1];
          results = [];
          for (m = 0, len = ref.length; m < len; m++) {
            i = ref[m];
            results.push(box_points[i]);
          }
          return results;
        })()).map(function(v) {
          return new IMGPlotter.Vector3(0, v.y, v.z);
        }), ((function() {
          var len, m, ref, results;
          ref = [0, 1, 2, 3];
          results = [];
          for (m = 0, len = ref.length; m < len; m++) {
            i = ref[m];
            results.push(box_points[i]);
          }
          return results;
        })()).map(function(v) {
          return new IMGPlotter.Vector3(v.x, 0, v.z);
        }), ((function() {
          var len, m, ref, results;
          ref = [0, 3, 7, 4];
          results = [];
          for (m = 0, len = ref.length; m < len; m++) {
            i = ref[m];
            results.push(box_points[i]);
          }
          return results;
        })()).map(function(v) {
          return new IMGPlotter.Vector3(v.x, v.y, 0);
        })
      ];
      if (zero_plane >= 0 && zero_plane <= 2) {
        for (i = m = 0, ref = NUM_GRID_LINES; 0 <= ref ? m < ref : m > ref; i = 0 <= ref ? ++m : --m) {
          line_geom = [];
          line_geom.push(origin_plane_points[zero_plane][0].clone().lerp(origin_plane_points[zero_plane][3], i / (NUM_GRID_LINES - 1)));
          line_geom.push(origin_plane_points[zero_plane][1].clone().lerp(origin_plane_points[zero_plane][2], i / (NUM_GRID_LINES - 1)));
          result.push(new IMGPlotter.Line(origin_colors[zero_plane], line_geom));
        }
        for (i = n = 0, ref1 = NUM_GRID_LINES; 0 <= ref1 ? n < ref1 : n > ref1; i = 0 <= ref1 ? ++n : --n) {
          line_geom = [];
          line_geom.push(origin_plane_points[zero_plane][0].clone().lerp(origin_plane_points[zero_plane][1], i / (NUM_GRID_LINES - 1)));
          line_geom.push(origin_plane_points[zero_plane][3].clone().lerp(origin_plane_points[zero_plane][2], i / (NUM_GRID_LINES - 1)));
          result.push(new IMGPlotter.Line(origin_colors[zero_plane], line_geom));
        }
      }
      return result;
    };

    return BoundingVolume;

  })();
  this.update_plot_colors = function() {
    var color_mode;
    color_mode = this.scope.color_taxon_level.value;
    this.color_map = make_color_map(color_mode, this.data.contigs);
    this.scope.update_legend(this.color_map);
    if (this.dataSeries != null) {
      this.dataSeries.updateColors();
    }
    if (this.plotter != null) {
      this.plotter.render();
    }
  };
  return this.init = function(data, scope) {
    var bgcolor, component, j, len, ref;
    this.data = data;
    this.scope = scope;
    this.contig_points = this.data.contigs.map(function(v) {
      return parse_point(v);
    });
    this.selected = void 0;
    bgcolor = new IMGPlotter.Color;
    bgcolor.setHSL(0, 0, 1);
    this.update_plot_colors();
    this.dataSeries = new IMGPlotter.DynamicDataSeries(this.contig_points, (function(_this) {
      return function(p, i) {
        return _this.color_map[get_hash(_this.scope.color_taxon_level.value)(_this.data.contigs[i])];
      };
    })(this), (function(_this) {
      return function(p, i) {
        if (_this.data.contigs[i].is_contam != null) {
          return 16;
        } else {
          return 32;
        }
      };
    })(this), function() {
      return false;
    }, (function(_this) {
      return function(p, i, cmp) {
        if (_this.selected != null) {
          cmp.setSelection(_this.selected, false);
        }
        _this.selected = i;
        cmp.setSelection(i, true);
        _this.scope.contig = _this.data.contigs[i];
        _this.scope.$apply();
        return true;
      };
    })(this), null, null);
    this.bvol = new BoundingVolume(this.contig_points);
    this.plotter = new IMGPlotter.Plotter;
    ref = make_axes(this.contig_points, this.bvol.box);
    for (j = 0, len = ref.length; j < len; j++) {
      component = ref[j];
      this.plotter.addComponent(component);
    }
    this.plotter.addComponent(this.dataSeries);
    this.plotter.init(1024, 1024, bgcolor, 'plot_area');
    this.update_projection();
    this.plotter.run();
  };
});
