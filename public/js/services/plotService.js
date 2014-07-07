angular.module('myApp.services').service('plotService', function() {
	
  addAxes = function(scene) {
    var line_mat = new THREE.LineBasicMaterial({ color: 0xffffff });
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

  this.init = function(data) {
    var plot_area = document.getElementById("plot_area");
    //var renderer = new THREE.WebGLRenderer({clearAlpha:1});
    var renderer = new THREE.CanvasRenderer();
    var scene = new THREE.Scene();
    var width = 512;
    var height = 512;
    var camera = new THREE.PerspectiveCamera(60, width/height, 0.0001, 1000);
    var projector = new THREE.Projector();

    renderer.setSize(width, height);
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
      ctx.arc( 0, 0, 0.5, PI2, true );
      ctx.stroke();
    }

    var mouse = {x:0, y:0};

    var particles = new THREE.Geometry();
    for(var p_i=0; p_i<data.points.length; ++p_i) {
    	var p = data.points[p_i];
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
        scene.add( particle );
    }

    addAxes(scene);

    camera.position.z = 0.2;

    var render = function() {
      renderer.render(scene, camera);
    };

    var animate = function() {
      render();
      requestAnimationFrame(animate);
      controls.update();
    };

    controls.addEventListener('change', render);
    plot_area.addEventListener('mousemove', onPlotMouseMove, false);

    animate();
  };

  function onPlotMouseMove(event) {
    event.preventDefault();
    mouse.x = (event.clientX / plot_area.innerWidth) * 2 - 1;
    mouse.y = - (event.clientY / plot_area.innerHeight) * 2 + 1;
  }

});

  
