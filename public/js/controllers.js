'use strict';

/* Controllers */

function IndexCtrl($scope, $http) {
  $http.get('/api/ssoUser').
    success(function(data, status, headers, config) {
        $scope.ssoUser = data;
        });
}

function MyJobsCtrl($scope, $http) {
  $http.get('/api/jobs').
    success(function(data, status, headers, config) {
        $scope.jobs = data.jobs;
        });
}

function PublicJobsCtrl($scope, $http) {
  $http.get('/api/jobs?is_public=1').
    success(function(data, status, headers, config) {
        $scope.jobs = data.jobs;
        });
}

function AddJobCtrl($scope, $http, $upload, $location) {
  $scope.form = {};
  $http.get('/api/projects').
    success(function(data, status, headers, config) {
        $scope.projects = data.projects;
        });
  $scope.onFileSelect = function($files) {
    console.log('onFileSelect');
    for(var i = 0; i < $files.length; i++) {
      var file = $files[i];
      $scope.upload = $upload.upload({
        url: '/api/uploadFasta',
        method: 'POST',
        data: {in_fasta: $scope.form.in_fasta},
        file: file
      }).progress(function(evt) {
        console.log('percent: ' + parseInt(100.0 * evt.loaded / evt.total));
      }).success(function(data, status, headers, config) {
        console.log(data);
      });
    }
  };
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
                  if(data.points) {
                    $scope.plotService.init(data);
                  }
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

