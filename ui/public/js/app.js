'use strict';

// Declare app level module which depends on filters, and services

angular.module('myApp', [
  'myApp.filters',
  'myApp.services',
  'myApp.directives',
  'angularFileUpload'
]).
config(['$routeProvider', '$locationProvider', function ($routeProvider, $locationProvider) {
  $routeProvider.
    when('/', {
      templateUrl: 'partials/index',
      controller: 'IndexCtrl'
    }).
    when('/myJobs', {
      templateUrl: 'partials/jobs',
      controller: 'MyJobsCtrl'
    }).
    when('/publicJobs', {
      templateUrl: 'partials/jobs',
      controller: 'PublicJobsCtrl'
    }).
    when('/addJob', {
      templateUrl: 'partials/addJob',
      controller: 'AddJobCtrl'
    }).
    when('/readJob/:id', {
      templateUrl: 'partials/readJob',
      controller: 'ReadJobCtrl'
    }).
    when('/deleteJob/:id', {
      templateUrl: 'partials/deleteJob',
      controller: 'DeleteJobCtrl'
    }).
    otherwise({
      redirectTo: '/'
    });

  $locationProvider.html5Mode(true);
}]);

