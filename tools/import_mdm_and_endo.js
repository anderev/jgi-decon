var request = require('request');
var jar = request.jar();
var readline = require('readline');
var fs = require('fs');

var new_job_uri = 'http://prodege.jgi-psf.org/api/job';
var mdm_dir = '/global/projectb/sandbox/omics/sc-decontamination/Test/v1.3.1/mdm_75';
var endo_dir = '/global/projectb/sandbox/omics/sc-decontamination/Test/v1.5t/endos';
var mdm_regex = /^[0-9]+$/g;
var endo_regex = /^endo-.*$/g;
var data_dirs = [[mdm_dir, mdm_regex], [endo_dir, endo_regex]];

var rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

var files_to_parse = [];
var parse_next_config = function() {
  if(files_to_parse.length > 0) {
    var config_filename = files_to_parse.shift();
    console.log('Parsing: '+config_filename);
    fs.readFile(config_filename, function(err, data) {
      var job = {};
      var lines = data.toString().split('\n');
      for(var i=0; i<lines.length; ++i) {
        var key_value = lines[i].split('=');
        if(key_value.length >= 2) {
          job[key_value[0].trim().toLowerCase()] = key_value[1].trim();
        }
      }

      var filename_tokens = config_filename.split('/');
      job['notes'] = 'Automated import of \"'+filename_tokens[filename_tokens.length-2]+'\"';
      job['is_public'] = 1;
      job['taxon_display_name'] = job['taxon_display_name'] || job['job_name'];
      console.log('Creating job: '+job.job_name);
      request({
        uri: new_job_uri,
        method: 'POST',
        jar: jar,
        form: job
      }, function(err, res, body) {
        console.log(body);
        parse_next_config();
      });
    });
  } else {
    console.log('Closing.');
    rl.close();
  }
};


rl.question('SSO Username: ', function(username) {
  rl.question('Password: ', function(password) {
    console.log('Signing in as ' + username);
    request({
      uri: 'https://signon.jgi-psf.org/signon/create',
      method: 'POST',
      form: {
        login: username,
        password: password
      },
      jar: jar
    }, function(err, res, body) {
      if(err) {
        console.log(err);
      } else {
        var data_dirs_to_check = data_dirs.length;
        data_dirs.map(function(data_dir) {
          --data_dirs_to_check;
          fs.readdir(data_dir[0], function(err, files) {
            if(!err) {
              var job_dirs_to_check = files.length;
              files.map(function(filename) {
                --job_dirs_to_check;

                if( filename.match(data_dir[1])) {
                  files_to_parse.push(data_dir[0]+'/'+filename+'/config.cfg');
                }

                if(job_dirs_to_check == 0 && data_dirs_to_check == 0) {
                  files_to_parse.sort();
                  parse_next_config();
                }
              });
            }
          });
        });
      }
    });
  });
});


