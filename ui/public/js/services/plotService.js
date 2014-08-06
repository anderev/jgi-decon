angular.module('myApp.services').service('plotService', function() {
	
  var axis_camera_ratio = 0.4;
  var contig_data = null;
  var particles = new THREE.Geometry();
  var mat_ps = null;
  var attributes = {
   color: { type: 'c', value: []},
   outline: { type: 'c', value: []}
  };

  addAxes = function(scene, label_scene, camera) {
    var line_mat = new THREE.LineBasicMaterial({ color: 0x000000 });
    var line_geom = [new THREE.Geometry(),new THREE.Geometry(),new THREE.Geometry()];
    var axisLength = camera.position.length() * axis_camera_ratio;
    line_geom[0].vertices.push(new THREE.Vector3(0, 0, 0));
    line_geom[0].vertices.push(new THREE.Vector3(axisLength, 0, 0));
    line_geom[1].vertices.push(new THREE.Vector3(0, 0, 0));
    line_geom[1].vertices.push(new THREE.Vector3(0, axisLength, 0));
    line_geom[2].vertices.push(new THREE.Vector3(0, 0, 0));
    line_geom[2].vertices.push(new THREE.Vector3(0, 0, axisLength));
    line = new THREE.Line(line_geom[0], line_mat);
    scene.add(line);
    line = new THREE.Line(line_geom[1], line_mat);
    scene.add(line);
    line = new THREE.Line(line_geom[2], line_mat);
    scene.add(line);

    var labels = [makeTextSprite("PCA1", {fontsize: 24, fontface: "Georgia", borderColor: {r:0, g:0, b:0, a:1.0}, backgroundColor: {r:255, g:255, b:255, a:0.8} } ),
                  makeTextSprite("PCA2", {fontsize: 24, fontface: "Georgia", borderColor: {r:0, g:0, b:0, a:1.0}, backgroundColor: {r:255, g:255, b:255, a:0.8} } ),
                  makeTextSprite("PCA3", {fontsize: 24, fontface: "Georgia", borderColor: {r:0, g:0, b:0, a:1.0}, backgroundColor: {r:255, g:255, b:255, a:0.8} } ) ];
    labels[0].position = line_geom[0].vertices[1].clone();
    labels[1].position = line_geom[1].vertices[1].clone();
    labels[2].position = line_geom[2].vertices[1].clone();
    label_scene.add(labels[0]);
    label_scene.add(labels[1]);
    label_scene.add(labels[2]);

    return line_geom;
  }

  updateAxes = function(axes, camera) {
    var axisLength = camera.position.length() * axis_camera_ratio;
    axes[0].vertices[1].x = axes[1].vertices[1].y = axes[2].vertices[1].z = axisLength;
    axes[0].verticesNeedUpdate = axes[1].verticesNeedUpdate = axes[2].verticesNeedUpdate = true;
  }

  get_hash = function(phylo_level) {
    return function(contig) {
      var phylo_array = contig.phylogeny.split(';');
      var end = (phylo_array.length > phylo_level) ? (phylo_level) : (phylo_array.length);
      return phylo_array.slice(0, end+1).join(';');
    };
  };

  this.update_plot_colors = function(phylo_level) {
    console.log('update_plot_colors');
    color_map = {};
    var f_hash = get_hash(phylo_level);
    for(var p_i=0; p_i<contig_data.points.length; ++p_i) {
      color_map[f_hash(contig_data.points[p_i])] = new THREE.Color();
    }

    var num_colors = 0;
    for(var phylo in color_map) {
      num_colors++;
    }

    var phylo_i = 0;
    for(var phylo in color_map) {
      color_map[phylo].setHSL(phylo_i / num_colors, 0.75, 0.6);
      phylo_i++;
    }

    if(mat_ps) {
      attributes.color.value = [];
      for(var p_i=0; p_i<contig_data.points.length; ++p_i) {
        attributes.color.value.push(color_map[f_hash(contig_data.points[p_i])]);
        //attributes.color.value.push(new THREE.Color(0,0,0));
      }
      mat_ps.needsUpdate = true;
    }
    
  };

  this.init = function(data, $scope) {
    var plot_area = document.getElementById("plot_area");
    var renderer = new THREE.WebGLRenderer({clearAlpha:1});
    //var renderer = new THREE.CanvasRenderer();
    var scene = new THREE.Scene();
    var hud_scene = new THREE.Scene();
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

    renderer.setSize(width, height);
    renderer.setClearColorHex(0xffffff, 1);
    renderer.autoClear = false;
    plot_area.appendChild(renderer.domElement);

    var controls = new THREE.TrackballControls(camera, renderer.domElement);
    var PI2 = Math.PI * 2;

    camera.position.z = 0.2;

    controls.rotateSpeed = 5.0;
    controls.zoomSpeed = 1.0;
    controls.panSpeed = 1.0;
    controls.noZoom = false;
    controls.noPan = false;
    controls.staticMoving = true;
    controls.dynamicDampingFactor = 0.3;
    controls.keys = [65, 83, 68];

    var vertexShaderSource = '\
      attribute vec3 color;\
      attribute vec3 outline;\
      varying vec3 vColor;\
      varying vec3 vOutline;\
      void main() {\
        vec4 mvPosition = modelViewMatrix * vec4( position, 1.0 );\
        gl_Position = projectionMatrix * mvPosition;\
        gl_PointSize = 64.0;\
        vColor = color;\
        vOutline = outline;\
      }';
    var fragmentShaderSource = '\
      varying vec3 vColor;\
      varying vec3 vOutline;\
      void main() {\
        vec2 r = gl_PointCoord - vec2(0.5,0.5);\
        float len_r = length(r);\
        if(len_r <= 0.25) {\
         gl_FragColor = vec4(vColor, 1.0);\
        } else if(len_r <= 0.4) {\
         gl_FragColor = vec4(vOutline, 1.0);\
        } else if(len_r <= 0.5) {\
         gl_FragColor = vec4(0,0,0, 0.75*(1.0 - 10.0*(len_r-0.4)));\
        } else {\
         discard;\
        }\
       }';
    var mouse = {x:0, y:0};
    var INTERSECTED;

    this.update_plot_colors(6);


    var clean  = new THREE.Color();
    var contam  = new THREE.Color();
    var hybrid  = new THREE.Color();
    var unknown  = new THREE.Color();
    clean.setHSL( 0.333, 0.75, 0.6 );
    contam.setHSL( 0, 0.75, 0.6 );
    hybrid.setHSL( 0.5, 0.75, 0.6 );
    unknown.setHSL( 0.1666, 0.75, 0.6 );

    attributes.color.value = [];
    var f_hash = get_hash(6);
    for(var p_i=0; p_i<contig_data.points.length; ++p_i) {
    	var p = contig_data.points[p_i];

        //particle system (rendered)
        particles.vertices.push(new THREE.Vector3(p.x, p.y, p.z));
        attributes.color.value.push(color_map[f_hash(p)]);
        if(p.name.match(/clean/g)) {
          status_color = clean;
        } else if(p.name.match(/contam/g)) {
          status_color = contam;
        } else if(p.name.match(/hybrid/g)) {
          status_color = hybrid;
        } else {
          status_color = unknown;
        }
        attributes.outline.value.push(status_color);

        //sprites (picked)
        var particle = new THREE.Sprite( new THREE.SpriteMaterial({opacity:0}) );
        particle.position.x = p.x;
        particle.position.y = p.y;
        particle.position.z = p.z;
        particle.scale.x = particle.scale.y = 32;
        particle.data_i = p_i;
        hud_scene.add( particle );
    }

    mat_ps = new THREE.ShaderMaterial({
      attributes: attributes,
      vertexShader: vertexShaderSource,
      fragmentShader: fragmentShaderSource,
      transparent: true
    });
    var particle_system = new THREE.ParticleSystem(particles, mat_ps);
    particle_system.sortParticles = true;
    scene.add(particle_system);

    var axes = addAxes(scene, label_scene, camera);

    var savedColor, selectedColor = new THREE.Color(1,1,0);

    var render = function() {
      var vector = new THREE.Vector3( mouse.x, mouse.y, 0.5 );
      projector.unprojectVector( vector, hud_camera );
      //var raycaster = new THREE.Raycaster( camera.position, vector.sub( camera.position ).normalize() );
      vector.z = 0;
      var raycaster = new THREE.Raycaster( vector, new THREE.Vector3(0,0,-1) );

      for(var child_i=0; child_i < hud_scene.children.length; child_i++) {
        var point = contig_data.points[hud_scene.children[child_i].data_i];
        vector = new THREE.Vector3(point.x, point.y, point.z);
        projector.projectVector(vector, camera);
        projector.unprojectVector(vector, hud_camera);
        hud_scene.children[child_i].position = vector;
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

      var intersects = raycaster.intersectObjects( hud_scene.children );

      if( intersects.length > 0 ) {
        if( INTERSECTED != intersects[ 0 ].object ) {
          if( INTERSECTED ) INTERSECTED.material.color = savedColor;

          INTERSECTED = intersects[0].object;
          savedColor = INTERSECTED.material.color;
          INTERSECTED.material.color = selectedColor;
          $scope.contig = contig_data.points[INTERSECTED.data_i];
          $scope.$apply();
        }
      } else {
        if( INTERSECTED ) INTERSECTED.material.color = savedColor;
        INTERSECTED = null;
      }

      updateAxes(axes, camera);

      renderer.clear();
      renderer.render(scene, camera);
      renderer.clearDepth();
      renderer.render(hud_scene, hud_camera);
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

    var screen = {};

    function onPlotMouseMove(event) {
      var relx = ( event.pageX - screen.left ) / screen.width;
      var rely = ( event.pageY - screen.top ) / screen.height;
      event.preventDefault();
      mouse.x = relx * 2 - 1;
      mouse.y = - rely * 2 + 1;
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
  
});

