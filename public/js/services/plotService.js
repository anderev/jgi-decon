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
    var renderer = new THREE.WebGLRenderer({clearAlpha:1});
    var scene = new THREE.Scene();
    var width = 512;
    var height = 512;
    var camera = new THREE.PerspectiveCamera(60, width/height, 0.0001, 1000);

    renderer.setSize(width, height);
    plot_area.appendChild(renderer.domElement);

    var controls = new THREE.TrackballControls(camera, renderer.domElement);

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
    	varying vec3 vColor;\
    	void main() {\
    		vColor = color;\
    		vec4 mvPosition = modelViewMatrix * vec4( position, 1.0 );\
    		gl_Position = projectionMatrix * mvPosition;\
    		gl_PointSize = 32.0;\
        }';
    var fragmentShaderSource = '\
    	varying vec3 vColor;\
    	void main() {\
                vec2 r = gl_PointCoord - vec2(0.5,0.5);\
                if(length(r) <= 0.45) {\
                  gl_FragColor = vec4(vColor, 1.0);\
                } else if(length(r) <= 0.5) {\
                  gl_FragColor = vec4(1,1,1, 1.0);\
                } else {\
                  gl_FragColor = vec4(0,0,0,0.0);\
                }\
        }';
    var attributes = {
    	color: { type: 'c', value: []}
    };
    var particles = new THREE.Geometry();
    for(var p_i=0; p_i<data.points.length; ++p_i) {
    	var p = data.points[p_i];
        var typeColor = null;
    	particles.vertices.push(new THREE.Vector3(p.x, p.y, p.z));
        if( p.name.match(/clean/g) ) {
          typeColor = new THREE.Color(0,1,0);
        } else if( p.name.match(/hybrid/g) ) {
          typeColor = new THREE.Color(0,0,1);
        } else if( p.name.match(/contam/g) ) {
          typeColor = new THREE.Color(1,0,0);
        } else  {
          typeColor = new THREE.Color(1,1,0);
        }
        attributes.color.value.push(typeColor);
    }
    var material = new THREE.ShaderMaterial({
    	attributes: attributes,
    	vertexShader: vertexShaderSource,
    	fragmentShader: fragmentShaderSource,
        transparent: true
    });
    var particleSystem = new THREE.ParticleSystem(particles, material);
    particleSystem.sortParticles = true;
    scene.add(particleSystem);

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

    animate();
  };
});

  
