'use strict';

/* Controllers */

function IndexCtrl($scope, $http) {
  $http.get('/api/ssoUser').
    success(function(data, status, headers, config) {
        $scope.ssoUser = data.user;
        });
  $http.get('/api/projects').
    success(function(data, status, headers, config) {
        $scope.projects = data.projects;
        });
}

function AddJobCtrl($scope, $http, $location) {
  $scope.form = {};
  $http.get('/api/projects').
    success(function(data, status, headers, config) {
        $scope.projects = data.projects;
        });
  $scope.submitJob = function() {
    $http.post('/api/job', $scope.form).
      success(function(data) {
          $location.path('/');
          });
  };
}

function ReadJobCtrl($scope, $http, $routeParams, plotService) {
  $http.get('/api/job/' + $routeParams.id).
    success(function(data) {
        $scope.job = data.job;
        $scope.plotService = plotService;
        $http.get('/api/getPCA/' + $routeParams.id).
        	success(function(data) {
                $scope.plotService.init(data);
        	});
        });
}

function DeleteJobCtrl($scope, $http, $location, $routeParams) {
  $http.get('/api/job/' + $routeParams.id).
    success(function(data) {
        $scope.job = data.job;
        });

  $scope.deleteJob = function() {
    $http.delete('/api/job/' + $routeParams.id).
      success(function(data) {
          $location.url('/');
          });
  };

  $scope.home = function() {
    $location.url('/');
  };
}

function AddProjectCtrl($scope, $http, $location) {
  $scope.form = {};
  $scope.submitProject = function() {
    $http.post('/api/project', $scope.form).
      success(function(data) {
          $location.path('/');
          });
  };
}

function ReadProjectCtrl($scope, $http, $routeParams) {
  $http.get('/api/jobsInProject/' + $routeParams.id).
    success(function(data) {
        $scope.jobs = data.jobs;
        });
  $http.get('/api/project/' + $routeParams.id).
    success(function(data) {
        $scope.project = data.project;
        });
}

function DeleteProjectCtrl($scope, $http, $location, $routeParams) {
  $http.get('/api/project/' + $routeParams.id).
    success(function(data) {
        $scope.project = data.project;
        });

  $scope.deleteProject = function() {
    $http.delete('/api/project/' + $routeParams.id).
      success(function(data) {
          $location.url('/');
          });
  };

  $scope.home = function() {
    $location.url('/');
  };
}

