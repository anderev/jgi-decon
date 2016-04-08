
/**
 * IMG Plotter
 * @author Evan Andersen
 * Refactored from ProDeGe (https://prodege.jgi.doe.gov/)
 */
var IMGPlotter, getLayerXY, getTextWidth,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

IMGPlotter = {
  version: '0.1'
};

getTextWidth = function(text, font) {
  var ctx, metricsCanvas;
  metricsCanvas = document.createElement('canvas');
  ctx = metricsCanvas.getContext('2d');
  ctx.font = font;
  return ctx.measureText(text).width;
};

getLayerXY = function(event) {
  var el, x, y;
  el = event.target;
  x = 0;
  y = 0;
  while (el && !isNaN(el.offsetLeft) && !isNaN(el.offsetTop)) {
    x += el.offsetLeft - el.scrollLeft;
    y += el.offsetTop - el.scrollTop;
    el = el.offsetParent;
  }
  return {
    x: event.clientX - x,
    y: event.clientY - y
  };
};

IMGPlotter.Component = (function() {
  function Component(name1) {
    this.name = name1;
  }

  Component.prototype.addSelf = function(plotter) {};

  Component.prototype.removeSelf = function(plotter) {};

  Component.prototype.onClick = function(i) {};

  Component.prototype.onHover = function(i) {};

  Component.prototype.onRender = function(plotter) {};

  return Component;

})();

IMGPlotter.SceneComponent = (function(superClass) {
  extend(SceneComponent, superClass);

  function SceneComponent(name, position1) {
    this.position = position1;
    SceneComponent.__super__.constructor.call(this, name);
  }

  return SceneComponent;

})(IMGPlotter.Component);

IMGPlotter.SceneLabel = (function(superClass) {
  extend(SceneLabel, superClass);

  function SceneLabel(position, text1) {
    this.text = text1;
    SceneLabel.__super__.constructor.call(this, "IMGPlotter.HUDLabel", position);
  }

  SceneLabel.prototype.addSelf = function(plotter) {
    this.labelSprite = this.makeTextSprite(this.text);
    this.labelSprite.position.copy(this.position);
    plotter.addToRenderables(this.labelSprite, this);
  };

  SceneLabel.prototype.removeSelf = function(plotter) {
    plotter.removeFromRenderables(this.labelSprite);
  };

  SceneLabel.prototype.makeTextSprite = function(message, parameters) {
    var backgroundColor, borderColor, borderThickness, canvas, ctx, font, fontface, fontsize, sprite, spriteMaterial, textWidth, texture;
    if (parameters === void 0) {
      parameters = {};
    }
    fontface = parameters.hasOwnProperty('fontface') ? parameters['fontface'] : 'Arial';
    fontsize = parameters.hasOwnProperty('fontsize') ? parameters['fontsize'] : 18;
    borderThickness = parameters.hasOwnProperty('borderThickness') ? parameters['borderThickness'] : 4;
    borderColor = parameters.hasOwnProperty('borderColor') ? parameters['borderColor'] : {
      r: 0,
      g: 0,
      b: 0,
      a: 1.0
    };
    backgroundColor = parameters.hasOwnProperty('backgroundColor') ? parameters['backgroundColor'] : {
      r: 255,
      g: 255,
      b: 255,
      a: 1.0
    };
    font = 'Bold ' + fontsize + 'px ' + fontface;
    textWidth = getTextWidth(message, font);
    canvas = document.createElement('canvas');
    canvas.width = Math.floor(textWidth + 4 * borderThickness);
    canvas.height = canvas.width;
    ctx = canvas.getContext('2d');
    ctx.font = font;
    ctx.fillStyle = 'rgba(' + backgroundColor.r + ',' + backgroundColor.g + ',' + backgroundColor.b + ',' + backgroundColor.a + ')';
    ctx.strokeStyle = 'rgba(' + borderColor.r + ',' + borderColor.g + ',' + borderColor.b + ',' + borderColor.a + ')';
    ctx.lineWidth = borderThickness;
    this.roundRect(ctx, borderThickness / 2, 0.5 * textWidth + borderThickness / 2, textWidth + borderThickness, fontsize * 1.4 + borderThickness, 6);
    ctx.fillStyle = 'rgba(0, 0, 0, 1.0)';
    ctx.fillText(message, borderThickness, 0.5 * textWidth + fontsize + borderThickness);
    texture = new THREE.Texture(canvas);
    texture.minFilter = THREE.LinearFilter;
    texture.needsUpdate = true;
    spriteMaterial = new THREE.SpriteMaterial({
      map: texture
    });
    sprite = new THREE.Sprite(spriteMaterial);
    sprite.textWidth = textWidth;
    return sprite;
  };

  SceneLabel.prototype.roundRect = function(ctx, x, y, w, h, r) {
    ctx.beginPath();
    ctx.moveTo(x + r, y);
    ctx.lineTo(x + w - r, y);
    ctx.quadraticCurveTo(x + w, y, x + w, y + r);
    ctx.lineTo(x + w, y + h - r);
    ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
    ctx.lineTo(x + r, y + h);
    ctx.quadraticCurveTo(x, y + h, x, y + h - r);
    ctx.lineTo(x, y + r);
    ctx.quadraticCurveTo(x, y, x + r, y);
    ctx.closePath();
    ctx.fill();
    ctx.stroke();
  };

  SceneLabel.prototype.onRender = function(plotter) {
    var d;
    d = plotter.sceneCamera.position.distanceTo(this.position);
    this.labelSprite.scale.set(0.001 * d * this.labelSprite.textWidth, 0.001 * d * this.labelSprite.textWidth, 1.0);
  };

  return SceneLabel;

})(IMGPlotter.SceneComponent);

IMGPlotter.Line = (function(superClass) {
  extend(Line, superClass);

  function Line(color1, points) {
    this.color = color1;
    this.points = points;
  }

  Line.prototype.addSelf = function(plotter) {
    var geometry, j, len, material, p, ref;
    geometry = new THREE.Geometry();
    material = new THREE.LineBasicMaterial({
      color: this.color.getHex()
    });
    ref = this.points;
    for (j = 0, len = ref.length; j < len; j++) {
      p = ref[j];
      geometry.vertices.push(p);
    }
    this.line = new THREE.Line(geometry, material);
    plotter.addToRenderables(this.line, this);
  };

  Line.prototype.removeSelf = function(plotter) {
    plotter.removeFromRenderables(this.line);
  };

  return Line;

})(IMGPlotter.SceneComponent);

IMGPlotter.DataSeries = (function(superClass) {
  extend(DataSeries, superClass);

  function DataSeries(samples1, colorCB1, pointSizeCB, highlightCB, onClickCB1, onHoverCB1) {
    var color, fragmentShaderSource, i, j, len, p, ref, vertexShaderSource;
    this.samples = samples1;
    this.colorCB = colorCB1;
    this.onClickCB = onClickCB1;
    this.onHoverCB = onHoverCB1;
    DataSeries.__super__.constructor.call(this, "IMGPlotter.DataSeries", {
      x: 0,
      y: 0,
      z: 0
    });
    vertexShaderSource = "attribute float pointSize;\nattribute vec3 color;\nattribute float highlight;\nvarying vec3 frag_color;\nvarying float frag_highlight;\nvoid main() {\n  vec4 mvPosition = modelViewMatrix * vec4( position, 1.0 );\n  gl_Position = projectionMatrix * mvPosition;\n  gl_PointSize = pointSize;\n  frag_color = color;\n  frag_highlight = highlight;\n}";
    fragmentShaderSource = "varying vec3 frag_color;\nvarying float frag_highlight;\nvoid main() {\n  vec2 r = 2.0 * (gl_PointCoord - vec2(0.5,0.5));\n  float x = length(r);\n  float x_2 = x * x;\n  if( bool(frag_highlight) && (x <= 1.0 && x >= 0.8) ) {\n    gl_FragColor = vec4(0,0,0,1);\n  } else if(x < 0.8) {\n    float opacity = 1.0 - exp(-sqrt(1.0 - x_2));\n    gl_FragColor = vec4(frag_color, max(frag_highlight, opacity));\n  } else {\n    discard;\n  }\n }";
    this.geometry = new THREE.BufferGeometry();
    this.attributes = {
      position: new Float32Array(this.samples.length * 3),
      color: new Float32Array(this.samples.length * 3),
      pointSize: new Float32Array(this.samples.length),
      highlight: new Float32Array(this.samples.length)
    };
    ref = this.samples;
    for (i = j = 0, len = ref.length; j < len; i = ++j) {
      p = ref[i];
      this.attributes.position[i * 3] = p.x;
      this.attributes.position[i * 3 + 1] = p.y;
      this.attributes.position[i * 3 + 2] = p.z;
      color = this.colorCB(p, i, this);
      this.attributes.color[i * 3] = color.r;
      this.attributes.color[i * 3 + 1] = color.g;
      this.attributes.color[i * 3 + 2] = color.b;
      this.attributes.pointSize[i] = pointSizeCB(p, i, this);
      this.attributes.highlight[i] = highlightCB(p, i, this);
    }
    this.geometry.addAttribute('position', new THREE.BufferAttribute(this.attributes.position, 3));
    this.geometry.addAttribute('color', new THREE.BufferAttribute(this.attributes.color, 3));
    this.geometry.addAttribute('pointSize', new THREE.BufferAttribute(this.attributes.pointSize, 1));
    this.geometry.addAttribute('highlight', new THREE.BufferAttribute(this.attributes.highlight, 1));
    this.geometry.computeBoundingBox();
    this.material = new THREE.ShaderMaterial({
      vertexShader: vertexShaderSource,
      fragmentShader: fragmentShaderSource,
      transparent: true
    });
    this.particleSystem = new THREE.Points(this.geometry, this.material);
    this.particleSystem.plotComponent = this;
  }

  DataSeries.prototype.addSelf = function(plotter) {
    plotter.addDataSeries(this);
  };

  DataSeries.prototype.removeSelf = function(plotter) {
    plotter.removeDataSeries(this);
  };

  DataSeries.prototype.onClick = function(i) {
    if (this.onClickCB != null) {
      return this.onClickCB(this.samples[i], i, this);
    }
  };

  DataSeries.prototype.onHover = function(i) {
    if (this.onHoverCB != null) {
      return this.onHoverCB(this.samples[i], i, this);
    }
  };

  DataSeries.prototype.onRender = function(plotter) {
    var array, i, index, indices, j, k, l, length, mat, positions, ref, ref1, ref2, sortArray, v;
    v = new THREE.Vector3();
    mat = new THREE.Matrix4();
    mat.multiplyMatrices(plotter.sceneCamera.projectionMatrix, plotter.sceneCamera.matrixWorldInverse);
    mat.multiply(this.particleSystem.matrixWorld);
    index = this.geometry.getIndex();
    positions = this.geometry.getAttribute('position').array;
    length = positions.length / 3;
    if (index === null) {
      array = new Uint16Array(length);
      for (i = j = 0, ref = length - 1; 0 <= ref ? j <= ref : j >= ref; i = 0 <= ref ? ++j : --j) {
        array[i] = i;
      }
      index = new THREE.BufferAttribute(array, 1);
      this.geometry.setIndex(index);
    }
    sortArray = [];
    for (i = k = 0, ref1 = length - 1; 0 <= ref1 ? k <= ref1 : k >= ref1; i = 0 <= ref1 ? ++k : --k) {
      v.fromArray(positions, i * 3);
      v.applyProjection(mat);
      sortArray.push([v.z, i]);
    }
    sortArray.sort(function(a, b) {
      return b[0] - a[0];
    });
    indices = index.array;
    for (i = l = 0, ref2 = length - 1; 0 <= ref2 ? l <= ref2 : l >= ref2; i = 0 <= ref2 ? ++l : --l) {
      indices[i] = sortArray[i][1];
    }
    return this.geometry.index.needsUpdate = true;
  };

  return DataSeries;

})(IMGPlotter.SceneComponent);

IMGPlotter.DynamicDataSeries = (function(superClass) {
  extend(DynamicDataSeries, superClass);

  function DynamicDataSeries(samples, colorCB, pointSizeCB, highlightCB, onClickCB, onHoverCB, onUpdateCB) {
    this.onUpdateCB = onUpdateCB;
    DynamicDataSeries.__super__.constructor.call(this, samples, colorCB, pointSizeCB, highlightCB, onClickCB, onHoverCB);
  }

  DynamicDataSeries.prototype.onRender = function(plotter) {
    if (this.onUpdateCB != null) {
      this.onUpdateCB(this.samples, this);
    }
    DynamicDataSeries.__super__.onRender.call(this, plotter);
    this.geometry.getAttribute('position').needsUpdate = true;
  };

  DynamicDataSeries.prototype.updateGeometry = function() {
    var i, j, len, p, ref;
    ref = this.samples;
    for (i = j = 0, len = ref.length; j < len; i = ++j) {
      p = ref[i];
      this.attributes.position[i * 3] = p.x;
      this.attributes.position[i * 3 + 1] = p.y;
      this.attributes.position[i * 3 + 2] = p.z;
    }
  };

  DynamicDataSeries.prototype.updateColors = function() {
    var color, i, j, len, p, ref;
    ref = this.samples;
    for (i = j = 0, len = ref.length; j < len; i = ++j) {
      p = ref[i];
      color = this.colorCB(p, i, this);
      this.attributes.color[i * 3] = color.r;
      this.attributes.color[i * 3 + 1] = color.g;
      this.attributes.color[i * 3 + 2] = color.b;
    }
    return this.geometry.getAttribute('color').needsUpdate = true;
  };

  DynamicDataSeries.prototype.setSelection = function(i, value) {
    this.attributes.highlight[i] = value;
    return this.geometry.getAttribute('highlight').needsUpdate = true;
  };

  return DynamicDataSeries;

})(IMGPlotter.DataSeries);

IMGPlotter.Plotter = (function() {
  function Plotter() {
    this.renderScene = new THREE.Scene();
    this.pickingArray = [];
    this.raycaster = new THREE.Raycaster();
    this.screen = {};
    this.mouse = {
      loc: new THREE.Vector2(),
      dragged: false,
      down: false
    };
    this.projector = new THREE.Projector();
  }

  Plotter.prototype.addComponent = function(component) {
    component.addSelf(this);
  };

  Plotter.prototype.removeComponent = function(component) {
    component.removeSelf(this);
  };

  Plotter.prototype.addToRenderables = function(geometry, component) {
    geometry.plotComponent = component;
    this.renderScene.add(geometry);
  };

  Plotter.prototype.removeFromRenderables = function(geometry) {
    this.renderScene.remove(geometry);
  };

  Plotter.prototype.addToPickables = function(geometry) {
    this.pickingArray.push(geometry);
  };

  Plotter.prototype.removeFromPickables = function(geometry) {
    this.pickingArray.splice(this.pickingArray.indexOf(geometry), 1);
  };

  Plotter.prototype.addDataSeries = function(dataSeries) {
    this.addToPickables(dataSeries.particleSystem);
    this.addToRenderables(dataSeries.particleSystem, dataSeries);
  };

  Plotter.prototype.removeDataSeries = function(dataSeries) {
    this.removeFromPickables(dataSeries.particleSystem);
    this.removeFromRenderables(dataSeries.particleSystem);
  };

  Plotter.prototype.run = function() {
    this.render();
    requestAnimationFrame((function(_this) {
      return function() {
        return _this.animate();
      };
    })(this));
  };

  Plotter.prototype.animate = function() {
    requestAnimationFrame((function(_this) {
      return function() {
        return _this.animate();
      };
    })(this));
    this.controls.update();
  };

  Plotter.prototype.render = function() {
    var j, len, object, ref;
    ref = this.renderScene.children;
    for (j = 0, len = ref.length; j < len; j++) {
      object = ref[j];
      if (object.plotComponent != null) {
        object.plotComponent.onRender(this);
      }
    }
    this.renderer.clear();
    this.renderer.render(this.renderScene, this.sceneCamera);
  };

  Plotter.prototype.handleResize = function() {
    var box, doc;
    box = this.renderer.domElement.getBoundingClientRect();
    doc = this.plotArea.ownerDocument.documentElement;
    this.screen.left = box.left + window.pageXOffset - doc.clientLeft;
    this.screen.top = box.top + window.pageYOffset - doc.clientTop;
    this.screen.width = box.width;
    this.screen.height = box.height;
  };

  Plotter.prototype.onMouseDown = function(mouseEvent) {
    if (mouseEvent.button === 0) {
      this.mouse.dragged = false;
      this.mouse.down = true;
    }
  };

  Plotter.prototype.onMouseMove = function(mouseEvent) {
    if (mouseEvent.button === 0) {
      if (this.mouse.down && !this.mouse.dragged) {
        this.mouse.dragged = true;
      }
    }
    if (this.hover(this.raycast(mouseEvent))) {
      this.render();
    }
  };

  Plotter.prototype.onMouseUp = function(mouseEvent) {
    if (mouseEvent.button === 0) {
      if (!this.mouse.dragged) {
        this.onMouseClick(mouseEvent);
      }
    }
  };

  Plotter.prototype.onMouseClick = function(mouseEvent) {
    if (this.pick(this.raycast(mouseEvent))) {
      this.render();
    }
  };

  Plotter.prototype.raycast = function(mouseEvent) {
    var rel;
    rel = getLayerXY(mouseEvent);
    mouseEvent.preventDefault();
    this.mouse.loc.x = (rel.x / this.screen.width) * 2 - 1;
    this.mouse.loc.y = -(rel.y / this.screen.height) * 2 + 1;
    this.raycaster.setFromCamera(this.mouse.loc, this.sceneCamera);
    this.raycaster.params.Points.threshold = 0.01 * this.sceneCamera.position.length();
    return this.raycaster.intersectObjects(this.pickingArray);
  };

  Plotter.prototype.pick = function(intersections) {
    var rerender;
    rerender = false;
    if (intersections.length > 0) {
      rerender = intersections[0].object.plotComponent.onClick(intersections[0].index);
    }
    return rerender;
  };

  Plotter.prototype.hover = function(intersections) {
    var rerender;
    rerender = false;
    if (intersections.length > 0) {
      rerender = intersections[0].object.plotComponent.onHover(intersections[0].index);
    }
    return rerender;
  };

  Plotter.prototype.init = function(width, height, bgcolor, plotElementId) {
    this.width = width;
    this.height = height;
    this.plotArea = document.getElementById(plotElementId);
    this.renderer = new THREE.WebGLRenderer({
      clearAlpha: 1
    });
    this.axisData = [new THREE.Vector3(1, 0, 0), new THREE.Vector3(0, 1, 0), new THREE.Vector3(0, 0, 1)];
    this.renderer.setSize(this.width, this.height);
    this.renderer.setClearColor(bgcolor.getHex(), 1);
    this.renderer.autoClear = false;
    this.renderer.domElement.style.border = '2px solid';
    this.plotArea.appendChild(this.renderer.domElement);
    this.sceneCamera = new THREE.PerspectiveCamera(60, this.width / this.height, 0.1, 10000);
    this.sceneCamera.position.x = 0;
    this.sceneCamera.position.y = 0;
    this.sceneCamera.position.z = 200;
    this.sceneCamera.up.set(0, 1, 0);
    this.handleResize();
    this.renderer.domElement.addEventListener('mousedown', (function(_this) {
      return function(event) {
        return _this.onMouseDown(event);
      };
    })(this));
    this.renderer.domElement.addEventListener('mousemove', (function(_this) {
      return function(event) {
        return _this.onMouseMove(event);
      };
    })(this));
    this.renderer.domElement.addEventListener('mouseup', (function(_this) {
      return function(event) {
        return _this.onMouseUp(event);
      };
    })(this));
    this.controls = new THREE.TrackballControls(this.sceneCamera, this.renderer.domElement);
    this.controls.rotateSpeed = 1.5;
    this.controls.zoomSpeed = 1.2;
    this.controls.panSpeed = 0.8;
    this.controls.noZoom = false;
    this.controls.noPan = false;
    this.controls.staticMoving = true;
    this.controls.dynamicDampingFactor = 0.3;
    this.controls.keys = [65, 83, 68];
    this.controls.addEventListener('change', (function(_this) {
      return function() {
        return _this.render();
      };
    })(this));
  };

  return Plotter;

})();

IMGPlotter.Color = (function(superClass) {
  extend(Color, superClass);

  function Color() {
    return Color.__super__.constructor.apply(this, arguments);
  }

  return Color;

})(THREE.Color);

IMGPlotter.Vector3 = (function(superClass) {
  extend(Vector3, superClass);

  function Vector3() {
    return Vector3.__super__.constructor.apply(this, arguments);
  }

  return Vector3;

})(THREE.Vector3);
