'use strict';

/* Directives */

angular.module('myApp.directives', ['ui.bootstrap']).
directive('appVersion', function (version) {
  return function(scope, elm, attrs) {
    elm.text(version);
  };
});
