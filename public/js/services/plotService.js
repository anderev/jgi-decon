angular.module('myApp.services').service('plotService', function() {
	function HSVtoRGB(h, s, v) {
	    var r, g, b, i, f, p, q, t;
	    if (h && s === undefined && v === undefined) {
	        s = h.s, v = h.v, h = h.h;
	    }
	    i = Math.floor(h * 6);
	    f = h * 6 - i;
	    p = v * (1 - s);
	    q = v * (1 - f * s);
	    t = v * (1 - (1 - f) * s);
	    switch (i % 6) {
	        case 0: r = v, g = t, b = p; break;
	        case 1: r = q, g = v, b = p; break;
	        case 2: r = p, g = v, b = t; break;
	        case 3: r = p, g = q, b = v; break;
	        case 4: r = t, g = p, b = v; break;
	        case 5: r = v, g = p, b = q; break;
	    }
	    return {
	        r: Math.floor(r * 255),
	        g: Math.floor(g * 255),
	        b: Math.floor(b * 255)
	    };
	}

	function rgbToHex(r, g, b) {
	    return "#" + ((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1);
	}	

	function HSVtoHex(h, s, v) {
		var rgb = HSVtoRGB(h,s,v);
		return rgbToHex(rgb.r, rgb.g, rgb.b);
	}

  this.init = function(data) {
    var plot_area = document.getElementById("plot_area");
    var renderer = new THREE.WebGLRenderer();
    var scene = new THREE.Scene();
    var width = 512;
    var height = 512;
    var camera = new THREE.PerspectiveCamera(75, width/height, 0.1, 1000);

    renderer.setSize(width, height);
    plot_area.appendChild(renderer.domElement);

    var particles = new THREE.Geometry();
    var material = [];
    for(var type_i=0.0; type_i<data.numTypes; ++type_i) {
    	var hue = type_i / data.numTypes;
        material.push(new THREE.ParticleBasicMaterial({color: HSVtoHex(hue,0.5,1.0), size: 0.05}));
    }
    for(var p_i=0; p_i<data.points.length; ++p_i) {
    	var p = data.points[p_i];
    	var particle = new THREE.Vector3(p.x, p.y, p.z);
    	particles.vertices.push(particle);
    }
    var particleSystem = new THREE.ParticleSystem(particles, material[0]);
    scene.add(particleSystem);

    camera.position.z = 5;

    var render = function() {
      requestAnimationFrame(render);

      particleSystem.rotation.x += 0.1;
      particleSystem.rotation.y += 0.1;

      renderer.render(scene, camera);
    };

    render();
  };
});

  
