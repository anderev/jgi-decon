angular.module('myApp.services').service('plotService', function() {
	
  var axis_camera_ratio = 0.3;
  var contig_data = null;
  var mat_ps = null;
  var color_map = {};
  var attributes = null;
  var DEFAULT_COLOR_BY = 6;
  var HSL_LIGHTNESS = 0.6;
  var HSL_SATURATION = 0.75;
  var bvol = null;
  var grid_scene = null;
  var plane_projection_scene = null;

  addAxisLabels = function(label_scene, camera) {
    var axisLength = camera.position.length() * axis_camera_ratio;

    var labels = [makeTextSprite("PCA1", {fontsize: 24, fontface: "Georgia", borderColor: {r:0, g:0, b:0, a:1.0}, backgroundColor: {r:255, g:255, b:255, a:0.8} } ),
                  makeTextSprite("PCA2", {fontsize: 24, fontface: "Georgia", borderColor: {r:0, g:0, b:0, a:1.0}, backgroundColor: {r:255, g:255, b:255, a:0.8} } ),
                  makeTextSprite("PCA3", {fontsize: 24, fontface: "Georgia", borderColor: {r:0, g:0, b:0, a:1.0}, backgroundColor: {r:255, g:255, b:255, a:0.8} } ) ];
    labels[0].position = new THREE.Vector3(axisLength, 0, 0);
    labels[1].position = new THREE.Vector3(0, axisLength, 0);
    labels[2].position = new THREE.Vector3(0, 0, axisLength);
    label_scene.add(labels[0]);
    label_scene.add(labels[1]);
    label_scene.add(labels[2]);
  }

  get_hash = function(phylo_level) {
    return function(contig) {
      var phylo_array = contig.phylogeny.split(';');
      var end = (phylo_array.length > phylo_level) ? (phylo_level) : (phylo_array.length-1);
      return phylo_array.slice(0, end+1).join(';');
    };
  };

  this.update_plot_colors = function(phylo_level) {
    console.log('update_plot_colors');
    color_map = {};
    var f_hash = get_hash(phylo_level);
    for(var p_i=0; p_i<contig_data.points.length; ++p_i) {
      var the_hash = f_hash(contig_data.points[p_i]);
      if(!(the_hash in color_map) && the_hash != 'Unknown') {
        color_map[the_hash] = new THREE.Color();
      }
    }

    var num_colors = 0;
    for(var phylo in color_map) {
      num_colors++;
    }

    var phylo_i = 0;
    for(var phylo in color_map) {
      color_map[phylo].setHSL(phylo_i / num_colors, HSL_SATURATION, HSL_LIGHTNESS);
      phylo_i++;
    }

    color_map.Unknown = new THREE.Color();
    color_map.Unknown.setHSL( 0.0, 0.0, HSL_LIGHTNESS );

    if(mat_ps) {
      attributes.color.value = [];
      for(var p_i=0; p_i<contig_data.points.length; ++p_i) {
        attributes.color.value.push(color_map[f_hash(contig_data.points[p_i])]);
      }
      mat_ps.needsUpdate = true;
    }
    
  };

  this.init = function(data, $scope) {
    var plot_area = document.getElementById("plot_area");
    var renderer = new THREE.WebGLRenderer({clearAlpha:1});
    var render_scene = new THREE.Scene();
    var picking_scene = new THREE.Scene();
    var label_scene = new THREE.Scene();
    var width = 1024;
    var height = 1024;
    var camera = new THREE.PerspectiveCamera(60, width/height, 0.0001, 1000);
    var hud_camera = new THREE.OrthographicCamera(width / -2, width / 2, height / 2, height / -2, 0.0001, 1000);
    var projector = new THREE.Projector();
    contig_data = data;
    var axis_data = [new THREE.Vector3(1,0,0),
                     new THREE.Vector3(0,1,0),
                     new THREE.Vector3(0,0,1)];
    attributes = {
      color: { type: 'c', value: []},
      pointSize: { type: 'f', value: []},
      highlight: { type: 'f', value: []}
    };

    renderer.setSize(width, height);
    renderer.setClearColorHex(0xffffff, 1);
    renderer.autoClear = false;
    plot_area.appendChild(renderer.domElement);

    var controls = new THREE.TrackballControls(camera, renderer.domElement);
    var PI2 = Math.PI * 2;

    camera.position.z = 0.01;
    camera.translateX(0.005);
    camera.translateY(0.005);

    controls.rotateSpeed = 5.0;
    controls.zoomSpeed = 1.0;
    controls.panSpeed = 1.0;
    controls.noZoom = false;
    controls.noPan = false;
    controls.staticMoving = true;
    controls.dynamicDampingFactor = 0.3;
    controls.keys = [65, 83, 68];

    var vertexShaderSource = '\
      attribute float pointSize;\
      attribute vec3 color;\
      attribute float highlight;\
      varying vec3 frag_color;\
      varying float frag_highlight;\
      void main() {\
        vec4 mvPosition = modelViewMatrix * vec4( position, 1.0 );\
        gl_Position = projectionMatrix * mvPosition;\
        gl_PointSize = pointSize;\
        frag_color = color;\
        frag_highlight = highlight;\
      }';
    var fragmentShaderSource = '\
      varying vec3 frag_color;\
      varying float frag_highlight;\
      void main() {\
        vec2 r = gl_PointCoord - vec2(0.5,0.5);\
        float len_r = length(r);\
        if( bool(frag_highlight) && (len_r <= 0.5 && len_r >= 0.4) ) {\
          gl_FragColor = vec4(0,0,0,1);\
        } else if(len_r < 0.4) {\
          gl_FragColor = vec4(frag_color, max(frag_highlight, 1.0 - sqrt(0.4 - len_r)));\
        } else {\
          discard;\
        }\
       }';
    var mouse = {x:0, y:0};
    var INTERSECTED;

    this.update_plot_colors(DEFAULT_COLOR_BY);

    attributes.color.value = [];
    var f_hash = get_hash(DEFAULT_COLOR_BY);
    var particles = new THREE.Geometry();
    var center_mass = null;
    var num_clean = 0;
    for(var p_i=0; p_i<contig_data.points.length; ++p_i) {
    	var p = contig_data.points[p_i];
        var vec3 = new THREE.Vector3(parseFloat(p.x), parseFloat(p.y), parseFloat(p.z));

        //particle system (rendered)
        particles.vertices.push(vec3);
        attributes.color.value.push(color_map[f_hash(p)]);
        if(p.name.match(/clean/g)) {
          status_size = 64.0;
          ++num_clean;
          if(center_mass) {
            center_mass.add(vec3);
          } else {
            center_mass = new THREE.Vector3().copy(vec3);
          }
        } else if(p.name.match(/contam/g)) {
          status_size = 16.0;
        } else if(p.name.match(/hybrid/g)) {
          status_size = 16.0;
        } else {
          status_size = 16.0;
        }
        attributes.pointSize.value.push(status_size);
        attributes.highlight.value.push(false);

        //sprites (picked)
        var particle = new THREE.Sprite( new THREE.SpriteMaterial({opacity:0}) );
        particle.position.x = p.x;
        particle.position.y = p.y;
        particle.position.z = p.z;
        particle.scale.x = particle.scale.y = 32;
        particle.data_i = p_i;
        picking_scene.add( particle );
    }

    bvol = new BoundingVolume(particles.vertices);
    grid_scene = bvol.getGridScene();
    plane_projection_scene = projectPointsOnPlane(particles, 2);
    if(center_mass) {
      controls.target = center_mass.multiplyScalar(1.0 / num_clean);
    }

    mat_ps = new THREE.ShaderMaterial({
      attributes: attributes,
      vertexShader: vertexShaderSource,
      fragmentShader: fragmentShaderSource,
      transparent: true
    });
    var particle_system = new THREE.ParticleSystem(particles, mat_ps);
    particle_system.sortParticles = true;
    render_scene.add(particle_system);

    addAxisLabels(label_scene, camera);

    var savedColor, selectedColor = new THREE.Color(1,1,0);

    var lock_selection = false, locked_selection = null;

    var render = function() {
      var vector = new THREE.Vector3( mouse.x, mouse.y, 0.5 );
      projector.unprojectVector( vector, hud_camera );
      vector.z = 0;
      var raycaster = new THREE.Raycaster( vector, new THREE.Vector3(0,0,-1) );

      for(var child_i=0; child_i < picking_scene.children.length; child_i++) {
        var point = contig_data.points[picking_scene.children[child_i].data_i];
        vector = new THREE.Vector3(point.x, point.y, point.z);
        projector.projectVector(vector, camera);
        projector.unprojectVector(vector, hud_camera);
        picking_scene.children[child_i].position = vector;
      }

      var axisLength = axis_camera_ratio * camera.position.length();
      for(var axis_i=0; axis_i < label_scene.children.length; axis_i++) {
        var point = axis_data[axis_i];
        vector = new THREE.Vector3(point.x, point.y, point.z);
        vector.multiplyScalar(axisLength);
        projector.projectVector(vector, camera);
        projector.unprojectVector(vector, hud_camera);
        label_scene.children[axis_i].position = vector;
      }

      if(!locked_selection) {
        var intersects = raycaster.intersectObjects( picking_scene.children );

        if( intersects.length > 0 ) {
          if( INTERSECTED != intersects[ 0 ].object ) {

            INTERSECTED = intersects[0].object;
            $scope.contig = contig_data.points[INTERSECTED.data_i];
            $scope.$apply();
          }

          if( lock_selection ) {
            locked_selection = INTERSECTED;
            attributes.highlight.value[locked_selection.data_i] = true;
          }
        } else {
          INTERSECTED = null;
          $scope.contig = null;
          $scope.$apply();
        }

        lock_selection = false;
      }

      renderer.clear();
      if(grid_scene) {
        renderer.render(grid_scene, camera);
      }
      if(plane_projection_scene) {
        renderer.render(plane_projection_scene, camera);
      }
      renderer.render(render_scene, camera);
      renderer.clearDepth();
      renderer.render(picking_scene, hud_camera);
      renderer.clearDepth();
      renderer.render(label_scene, hud_camera);
    };

    var animate = function() {
      render();
      requestAnimationFrame(animate);
      controls.update();
    };

    controls.addEventListener('change', render);
    renderer.domElement.addEventListener('mousemove', onPlotMouseMove, false);
    renderer.domElement.addEventListener('mousedown', onPlotMouseDown, false);
    renderer.domElement.addEventListener('mouseup', onPlotMouseUp, false);

    var screen = {};
    var mouse_is_down = false, mouse_was_dragged = false;

    function onPlotMouseDown(event) {
      console.log('event button: '+event.button);
      if( event.button == 0 ) {
        mouse_is_down = true;
        mouse_was_dragged = false;
      }
    }

    function onPlotMouseUp(event) {
      console.log('event button: '+event.button);
      if( event.button == 0 && !mouse_was_dragged ) {
        mouse_is_down = false;
        mouse_was_dragged = false;
        lock_selection = true;
        if( locked_selection ) {
          attributes.highlight.value[locked_selection.data_i] = false;
        }
        locked_selection = null;
      }
    }

    function onPlotMouseMove(event) {
      var relx = ( event.pageX - screen.left ) / screen.width;
      var rely = ( event.pageY - screen.top ) / screen.height;
      event.preventDefault();
      mouse.x = relx * 2 - 1;
      mouse.y = - rely * 2 + 1;
      if( mouse_is_down ) {
        mouse_was_dragged = true;
      }
    }

    function handleResize() {
      var box = renderer.domElement.getBoundingClientRect();
      var d = plot_area.ownerDocument.documentElement;
      screen.left = box.left + window.pageXOffset - d.clientLeft;
      screen.top = box.top + window.pageYOffset - d.clientTop;
      screen.width = box.width;
      screen.height = box.height;
    };

    handleResize();

    animate();

  };

  function makeTextSprite( message, parameters )
  {
    if ( parameters === undefined ) parameters = {};

    var fontface = parameters.hasOwnProperty("fontface") ? 
      parameters["fontface"] : "Arial";

    var fontsize = parameters.hasOwnProperty("fontsize") ? 
      parameters["fontsize"] : 18;

    var borderThickness = parameters.hasOwnProperty("borderThickness") ? 
      parameters["borderThickness"] : 4;

    var borderColor = parameters.hasOwnProperty("borderColor") ?
      parameters["borderColor"] : { r:0, g:0, b:0, a:1.0 };

    var backgroundColor = parameters.hasOwnProperty("backgroundColor") ?
      parameters["backgroundColor"] : { r:255, g:255, b:255, a:1.0 };

    var canvas = document.createElement('canvas');
    var context = canvas.getContext('2d');
    context.font = "Bold " + fontsize + "px " + fontface;

    // get size data (height depends only on font size)
    var metrics = context.measureText( message );
    var textWidth = metrics.width;

    // background color
    context.fillStyle   = "rgba(" + backgroundColor.r + "," + backgroundColor.g + ","
      + backgroundColor.b + "," + backgroundColor.a + ")";
    // border color
    context.strokeStyle = "rgba(" + borderColor.r + "," + borderColor.g + ","
      + borderColor.b + "," + borderColor.a + ")";

    context.lineWidth = borderThickness;
    roundRect(context, borderThickness/2, borderThickness/2, textWidth + borderThickness, fontsize * 1.4 + borderThickness, 6);
    // 1.4 is extra height factor for text below baseline: g,j,p,q.

    // text color
    context.fillStyle = "rgba(0, 0, 0, 1.0)";

    context.fillText( message, borderThickness, fontsize + borderThickness);

    // canvas contents will be used for a texture
    var texture = new THREE.Texture(canvas) 
      texture.needsUpdate = true;

    var spriteMaterial = new THREE.SpriteMaterial( 
        { map: texture } );
    var sprite = new THREE.Sprite( spriteMaterial );
    sprite.scale.set(200,100,200);
    return sprite;  
  }

  // function for drawing rounded rectangles
  function roundRect(ctx, x, y, w, h, r) {
    ctx.beginPath();
    ctx.moveTo(x+r, y);
    ctx.lineTo(x+w-r, y);
    ctx.quadraticCurveTo(x+w, y, x+w, y+r);
    ctx.lineTo(x+w, y+h-r);
    ctx.quadraticCurveTo(x+w, y+h, x+w-r, y+h);
    ctx.lineTo(x+r, y+h);
    ctx.quadraticCurveTo(x, y+h, x, y+h-r);
    ctx.lineTo(x, y+r);
    ctx.quadraticCurveTo(x, y, x+r, y);
    ctx.closePath();
    ctx.fill();
    ctx.stroke();   
  }
  
  function BoundingVolume(points) {
    this.box = new THREE.Box3();
    this.box.setFromPoints(points);
  }

  BoundingVolume.prototype.center = function() {
    return this.box.center();
  }

  BoundingVolume.prototype.getGridScene = function() {
    var result = new THREE.Scene();
    var line_mat = new THREE.LineBasicMaterial({ color: 0x000000 });
    var box_points = [
      new THREE.Vector3().copy(this.box.min),
      new THREE.Vector3(this.box.min.x, this.box.min.y, this.box.max.z),
      new THREE.Vector3(this.box.max.x, this.box.min.y, this.box.max.z),
      new THREE.Vector3(this.box.max.x, this.box.min.y, this.box.min.z),
      new THREE.Vector3(this.box.min.x, this.box.max.y, this.box.min.z),
      new THREE.Vector3(this.box.min.x, this.box.max.y, this.box.max.z),
      new THREE.Vector3().copy(this.box.max),
      new THREE.Vector3(this.box.max.x, this.box.max.y, this.box.min.z)];
    var plane_indices = [[0,4,5,1],[1,2,6,5],[2,3,7,6],[3,0,4,7],[0,1,2,3],[4,5,6,7]];

    //render bounding planes
    for(var plane_i=0; plane_i<6; ++plane_i) {
      var line_geom = new THREE.Geometry();
      for(var i=0; i<4; ++i)
        line_geom.vertices.push(box_points[plane_indices[plane_i][i]]);
      line_geom.vertices.push(box_points[plane_indices[plane_i][0]]);
      result.add(new THREE.Line(line_geom, line_mat));
    }

    //render origin planes
    var line_geom = new THREE.Geometry();
    line_geom.vertices.push(box_points[0].clone().setX(0));
    line_geom.vertices.push(box_points[4].clone().setX(0));
    line_geom.vertices.push(box_points[5].clone().setX(0));
    line_geom.vertices.push(box_points[1].clone().setX(0));
    line_geom.vertices.push(box_points[0].clone().setX(0));
    result.add(new THREE.Line(line_geom, line_mat));
    var line_geom = new THREE.Geometry();
    line_geom.vertices.push(box_points[0].clone().setY(0));
    line_geom.vertices.push(box_points[1].clone().setY(0));
    line_geom.vertices.push(box_points[2].clone().setY(0));
    line_geom.vertices.push(box_points[3].clone().setY(0));
    line_geom.vertices.push(box_points[0].clone().setY(0));
    result.add(new THREE.Line(line_geom, line_mat));
    var line_geom = new THREE.Geometry();
    line_geom.vertices.push(box_points[0].clone().setZ(0));
    line_geom.vertices.push(box_points[3].clone().setZ(0));
    line_geom.vertices.push(box_points[7].clone().setZ(0));
    line_geom.vertices.push(box_points[4].clone().setZ(0));
    line_geom.vertices.push(box_points[0].clone().setZ(0));
    result.add(new THREE.Line(line_geom, line_mat));

    //render origin lines
    var line_geom = new THREE.Geometry();
    line_geom.vertices.push(box_points[0].clone().setZ(0).setY(0));
    line_geom.vertices.push(box_points[3].clone().setZ(0).setY(0));
    result.add(new THREE.Line(line_geom, line_mat));
    var line_geom = new THREE.Geometry();
    line_geom.vertices.push(box_points[0].clone().setZ(0).setX(0));
    line_geom.vertices.push(box_points[4].clone().setZ(0).setX(0));
    result.add(new THREE.Line(line_geom, line_mat));
    var line_geom = new THREE.Geometry();
    line_geom.vertices.push(box_points[0].clone().setX(0).setY(0));
    line_geom.vertices.push(box_points[1].clone().setX(0).setY(0));
    result.add(new THREE.Line(line_geom, line_mat));

    return result;

  }

  function projectPointsOnPlane(points_geometry, zero_axis) {
    var projected_points = points_geometry.clone();
    if(zero_axis==0) {
      for(var i=0; i<projected_points.vertices.length; ++i) {
        projected_points.vertices[i].setX(0);
      }
    } else if (zero_axis==1) {
      for(var i=0; i<projected_points.vertices.length; ++i) {
        projected_points.vertices[i].setY(0);
      }
    } else {
      for(var i=0; i<projected_points.vertices.length; ++i) {
        projected_points.vertices[i].setZ(0);
      }
    }
    var result = new THREE.Scene();

    var vertexShaderSource = '\
      void main() {\
        vec4 mvPosition = modelViewMatrix * vec4( position, 1.0 );\
        gl_Position = projectionMatrix * mvPosition;\
        gl_PointSize = 8.0;\
      }';
    var fragmentShaderSource = '\
      void main() {\
        vec2 r = gl_PointCoord - vec2(0.5,0.5);\
        float len_r = length(r);\
        if(len_r < 0.5) {\
          gl_FragColor = vec4(0.25,0.25,0.25,0.25);\
        } else {\
          discard;\
        }\
       }';
    var mat = new THREE.ShaderMaterial({
      vertexShader: vertexShaderSource,
      fragmentShader: fragmentShaderSource,
      transparent: true
    });

    var particle_system = new THREE.ParticleSystem(projected_points, mat);
    particle_system.sortParticles = true;
    result.add(particle_system);
    return result;

  }

});

