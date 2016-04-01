module.exports = function(grunt) {

  grunt.initConfig({
    coffee: {
      compile: {
        options: {
          bare: true,
        },
        files: {
          'public/js/services/plotService.js': 'plotService.coffee'
        }
      }
    }
  });

  grunt.loadNpmTasks('grunt-contrib-coffee');

  grunt.registerTask('default', ['coffee']);

};

