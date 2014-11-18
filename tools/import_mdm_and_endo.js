var request = require('request');
var jar = request.jar();
var readline = require('readline');
var fs = require('fs');

var new_project_uri = 'http://prodege.jgi-psf.org/api/project';
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
        data_dirs.map(function(data_dir) {
          fs.readdir(data_dir[0], function(err, files) {
            if(!err) {
              files.map(function(filename) {

                if( filename.match(data_dir[1])) {
                  console.log('Parsing: '+data_dir[0]+'/'+filename+'/config.cfg');
                  fs.readFile(data_dir[0]+'/'+filename+'/config.cfg', function(err, data) {
                    var project = {};
                    var job = {};
                    var lines = data.toString().split('\n');
                    for(var i=0; i<lines.length; ++i) {
                      var key_value = lines[i].split('=');
                      if(key_value.length >= 2) {
                        if( lines[i].match(/^TAXON_/g) ) {
                          project[key_value[0].trim().toLowerCase()] = key_value[1].trim();
                        } else {
                          job[key_value[0].trim().toLowerCase()] = key_value[1].trim();
                        }
                      }
                    }
                    if(project.taxon_display_name.length == 0) {
                      project.taxon_display_name = job.job_name;
                    }
                    console.log('Creating project: '+project.taxon_display_name);

                    request({
                      uri: new_project_uri,
                      method: 'POST',
                      jar: jar,
                      form: project
                    }, function(err, res, body) {
                      var result = JSON.parse(body);
                      job['project_id'] = result.project_id;
                      job['notes'] = filename;
                      job['is_public'] = 1;
                      console.log('Creating job: '+job.job_name);
                      request({
                        uri: new_job_uri,
                        method: 'POST',
                        jar: jar,
                        form: job
                      }, function(err, res, body) {
                        console.log(body);
                      });

                    });

                  });
                }
              });
            }
          });
        });
      }
      rl.close();
    });
  });
});

