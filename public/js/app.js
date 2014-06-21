'use strict';

// Declare app level module which depends on filters, and services

angular.module('myApp', [
  'myApp.filters',
  'myApp.services',
  'myApp.directives'
]).
config(['$routeProvider', '$locationProvider', function ($routeProvider, $locationProvider) {
  $routeProvider.
    when('/', {
      templateUrl: 'partials/index',
      controller: 'IndexCtrl'
    }).
    when('/myJobs', {
      templateUrl: 'partials/myJobs',
      controller: 'MyJobsCtrl'
    }).
    when('/publicJobs', {
      templateUrl: 'partials/publicJobs',
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
    when('/addProject', {
      templateUrl: 'partials/addProject',
      controller: 'AddProjectCtrl'
    }).
    when('/readProject/:id', {
      templateUrl: 'partials/readProject',
      controller: 'ReadProjectCtrl'
    }).
    when('/deleteProject/:id', {
      templateUrl: 'partials/deleteProject',
      controller: 'DeleteProjectCtrl'
    }).
    otherwise({
      redirectTo: '/'
    });

  $locationProvider.html5Mode(true);
}]);

