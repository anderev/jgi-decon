'use strict';

/* Controllers */

function IndexCtrl($scope, $http) {
	$http.get('/api/jobs').
		success(function(data, status, headers, config) {
			$scope.jobs = data.jobs;
		});
}

function AddJobCtrl($scope, $http, $location) {
	$scope.form = {};
	$scope.submitJob = function() {
    $http.post('/api/job', $scope.form).
      success(function(data) {
          $location.path('/');
        });
  };
}

function ReadJobCtrl($scope, $http, $routeParams) {
	$http.get('/api/job/' + $routeParams.id).
		success(function(data) {
			$scope.job = data.job;
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

