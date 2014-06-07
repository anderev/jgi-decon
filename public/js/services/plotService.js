angular.module('myApp.services').service('plotService', function() {
	
  this.init = function(data) {
    var plot_area = document.getElementById("plot_area");
    var renderer = new THREE.WebGLRenderer();
    var scene = new THREE.Scene();
    var width = 512;
    var height = 512;
    var camera = new THREE.PerspectiveCamera(75, width/height, 0.1, 1000);

    renderer.setSize(width, height);
    plot_area.appendChild(renderer.domElement);

    var vertexShaderSource = '\
    	attribute vec3 color;\
    	varying vec3 vColor;\
    	void main() {\
    		vColor = color;\
    		vec4 mvPosition = modelViewMatrix * vec4( position, 1.0 );\
    		gl_PointSize = 2.0;\
    		gl_Position = projectionMatrix * mvPosition;\
        }';
    var fragmentShaderSource = '\
    	varying vec3 vColor;\
    	void main() {\
    		gl_FragColor = vec4(vColor, 1.0);\
        }';
    var typeColors = [];
    var attributes = {
    	color: { type: 'c', value: []}
    };
    var particles = new THREE.Geometry();
    for(var type_i=0.0; type_i<data.points.length; ++type_i) {
    	var hue = type_i / data.points.length;
    	var typeColor = new THREE.Color();
    	typeColor.setHSL(hue, 0.75, 0.5);
        typeColors.push(typeColor);
    }
    for(var p_i=0; p_i<data.points.length; ++p_i) {
    	var p = data.points[p_i];
    	var particle = new THREE.Vector3(p.x, p.y, p.z);
    	particles.vertices.push(particle);
    	attributes.color.value.push(typeColors[p_i]);
    }
    var material = new THREE.ShaderMaterial({
    	attributes: attributes,
    	vertexShader: vertexShaderSource,
    	fragmentShader: fragmentShaderSource
    });
    var particleSystem = new THREE.ParticleSystem(particles, material);
    scene.add(particleSystem);

    camera.position.z = 0.25;

    var render = function() {
      requestAnimationFrame(render);

      particleSystem.rotation.x += 0.01;
      particleSystem.rotation.y += 0.01;

      renderer.render(scene, camera);
    };

    render();
  };
});

  
