'use strict';

/* Controllers */

function IndexCtrl($scope, $http) {
  $http.get('/api/ssoUser').
    success(function(data, status, headers, config) {
        $scope.ssoUser = data;
        });
}

var isIMG = function(name) {
  if(name) {
    if( name.match(/\d{9,10}/) ) {
      return '[IMG]';
    } else {
      return '';
    }
  } else {
    return '';
  }
};

function MyJobsCtrl($scope, $http) {
  $scope.isIMG = isIMG;
  $http.get('/api/jobs').
    success(function(data, status, headers, config) {
        $scope.jobs = data.jobs;
        });
}

function PublicJobsCtrl($scope, $http) {
  $scope.isIMG = isIMG;
  $http.get('/api/jobs?is_public=1').
    success(function(data, status, headers, config) {
        $scope.jobs = data.jobs;
        });
}

function AddJobCtrl($scope, $http, $upload, $location) {
  $scope.form = {};
  $scope.updateTaxonomy = function() {
    var fields = $scope.form.taxonomy_string.split(';');
    $scope.form.taxon_domain = fields[0] || '';
    $scope.form.taxon_phylum = fields[1] || '';
    $scope.form.taxon_class = fields[2] || '';
    $scope.form.taxon_order = fields[3] || '';
    $scope.form.taxon_family = fields[4] || '';
    $scope.form.taxon_genus = fields[5] || '';
    $scope.form.taxon_species = fields[6] || '';
  };
  $scope.file_selected = null;
  $scope.file_uploaded = false;
  $scope.onFileSelect = function($files) {
    $scope.file_selected = $files[0];
    $scope.file_uploaded = false;
    console.log('file_selected: '+$scope.file_selected);
  };
  $scope.upload_file = function() {
    console.log('upload_file');
    var file = $scope.file_selected;
    $scope.upload = $upload.upload({
      url: '/api/uploadFasta',
      method: 'POST',
      data: {in_fasta: $scope.form.in_fasta},
      file: file
    }).success(function(data, status, headers, config) {
      $scope.file_uploaded = true;
    });
  };
  $scope.submitJob = function() {
    $http.post('/api/job', $scope.form).
      success(function(data) {
          $location.path('/');
          });
  };
}

function ReadJobCtrl($scope, $http, $routeParams, plotService) {
  $scope.isIMG = isIMG;
  $http.get('/api/job/' + $routeParams.id).
    success(function(data) {
        $scope.projection_modes = [
          {name: 'PCA2-PCA3', value: 0},
          {name: 'PCA1-PCA3', value: 1},
          {name: 'PCA1-PCA2', value: 2},
          {name: 'None', value: 3}
        ];
        $scope.color_modes = [
          {name: 'Domain', value: 0},
          {name: 'Phylum', value: 1},
          {name: 'Class', value: 2},
          {name: 'Order', value: 3},
          {name: 'Family', value: 4},
          {name: 'Genus', value: 5},
          {name: 'Species', value: 6},
          {name: 'Clean/Contam', value: 7}
        ];
        $scope.job = data.job;
        $scope.plotService = plotService;
        $scope.color_taxon_level = $scope.color_modes[5];
        $scope.projection_mode = $scope.projection_modes[3];
        $scope.update_plot_colors = function() { plotService.update_plot_colors(); };
        $scope.update_projection = function() { plotService.update_projection(); };
        $scope.update_legend = function(color_map) { $scope.color_map = color_map; };
        $scope.contig = null;
        $scope.nuc_seqs = null;
        if(data.job.process_status === 'Complete') {
          window.Pace.restart(); //Added for issue #33
          $http.get('/api/getPCA/' + $routeParams.id).
            success(function(data) {
              if(data.nuc_seqs) {
                $scope.nuc_seqs = data.nuc_seqs;
              }
              if(data.contigs) {
                $scope.plotService.init(data, $scope);
              }
            });
        }
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

