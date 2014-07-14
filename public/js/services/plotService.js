angular.module('myApp.services').service('plotService', function() {
	
  addAxes = function(scene) {
    var line_mat = new THREE.LineBasicMaterial({ color: 0x000000 });
    var line_geom = new THREE.Geometry();
    line_geom.vertices.push(new THREE.Vector3(0, 0, 0));
    line_geom.vertices.push(new THREE.Vector3(0.25, 0, 0));
    line = new THREE.Line(line_geom, line_mat);
    scene.add(line);
    line_geom = new THREE.Geometry();
    line_geom.vertices.push(new THREE.Vector3(0, 0, 0));
    line_geom.vertices.push(new THREE.Vector3(0, 0.25, 0));
    line = new THREE.Line(line_geom, line_mat);
    scene.add(line);
    line_geom = new THREE.Geometry();
    line_geom.vertices.push(new THREE.Vector3(0, 0, 0));
    line_geom.vertices.push(new THREE.Vector3(0, 0, 0.25));
    line = new THREE.Line(line_geom, line_mat);
    scene.add(line);
  }

  this.init = function(data, $scope) {
    var plot_area = document.getElementById("plot_area");
    //var renderer = new THREE.WebGLRenderer({clearAlpha:1});
    var renderer = new THREE.CanvasRenderer();
    var scene = new THREE.Scene();
    var width = 1024;
    var height = 1024;
    var camera = new THREE.PerspectiveCamera(60, width/height, 0.0001, 1000);
    var projector = new THREE.Projector();
    var contig_data = data;

    renderer.setSize(width, height);
    renderer.setClearColorHex(0xffffff, 1);
    plot_area.appendChild(renderer.domElement);

    var controls = new THREE.TrackballControls(camera, renderer.domElement);
    var PI2 = Math.PI * 2;

    controls.rotateSpeed = 5.0;
    controls.zoomSpeed = 1.0;
    controls.panSpeed = 1.0;
    controls.noZoom = false;
    controls.noPan = false;
    controls.staticMoving = true;
    controls.dynamicDampingFactor = 0.3;
    controls.keys = [65, 83, 68];

    var programFill = function(ctx) {
      ctx.beginPath();
      ctx.arc( 0, 0, 0.5, 0, PI2, true );
      ctx.fill();
    }

    var programStroke = function(ctx) {
      ctx.lineWidth = 0.025;
      ctx.beginPath();
      ctx.arc( 0, 0, 0.5, 0, PI2, true );
      ctx.stroke();
    }

    var mouse = {x:0, y:0};
    var INTERSECTED;

    var particles = new THREE.Geometry();
    for(var p_i=0; p_i<contig_data.points.length; ++p_i) {
    	var p = contig_data.points[p_i];
        var typeColor = null;
    	//particles.vertices.push(new THREE.Vector3(p.x, p.y, p.z));
        if( p.name.match(/clean/g) ) {
          typeColor = new THREE.Color(0,1,0);
        } else if( p.name.match(/hybrid/g) ) {
          typeColor = new THREE.Color(0,0,1);
        } else if( p.name.match(/contam/g) ) {
          typeColor = new THREE.Color(1,0,0);
        } else  {
          typeColor = new THREE.Color(1,1,0);
        }
        var particle = new THREE.Sprite( new THREE.SpriteCanvasMaterial( {color: typeColor, program: programFill} ) );
        particle.position.x = p.x;
        particle.position.y = p.y;
        particle.position.z = p.z;
        particle.scale.x = particle.scale.y = 0.001;
        particle.data_i = p_i;
        scene.add( particle );
    }

    var xlabel = makeTextSprite("PCA1", {fontsize: 24, fontface: "Georgia", borderColor: {r:0, g:0, b:0, a:1.0}, backgroundColor: {r:255, g:255, b:255, a:0.8} } );
    var ylabel = makeTextSprite("PCA2", {fontsize: 24, fontface: "Georgia", borderColor: {r:0, g:0, b:0, a:1.0}, backgroundColor: {r:255, g:255, b:255, a:0.8} } );
    var zlabel = makeTextSprite("PCA3", {fontsize: 24, fontface: "Georgia", borderColor: {r:0, g:0, b:0, a:1.0}, backgroundColor: {r:255, g:255, b:255, a:0.8} } );
    xlabel.position.set(0.25, 0, 0);
    ylabel.position.set(0, 0.25, 0);
    zlabel.position.set(0, 0, 0.25);
    scene.add(xlabel);
    scene.add(ylabel);
    scene.add(zlabel);
    
    addAxes(scene);

    camera.position.z = 0.2;
    var savedColor, selectedColor = new THREE.Color(1,1,0);

    var render = function() {
      var vector = new THREE.Vector3( mouse.x, mouse.y, 0.5 );
      projector.unprojectVector( vector, camera );
      var raycaster = new THREE.Raycaster( camera.position, vector.sub( camera.position ).normalize() );

      var intersects = raycaster.intersectObjects( scene.children );

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

      renderer.render(scene, camera);
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
    sprite.scale.set(0.1,0.05,1.0);
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

