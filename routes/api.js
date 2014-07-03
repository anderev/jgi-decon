var sqlite3 = require('sqlite3').verbose();
var db = new sqlite3.Database('scd.db');
var spawn = require('child_process').spawn;
var fs = require('fs');
var https = require('https');
var xml2js = require('xml2js');

var userCache = {}; // jgi_session_id -> userObject
var getUser = function(req, callback) { // callback = function(err, user)
  var jgi_session_id = req.cookies.jgi_session.split('/')[3];
  if( jgi_session_id in userCache ) {
    callback( null, userCache[jgi_session_id] );
  } else {
    var session_req = https.get({hostname:'signon.jgi-psf.org', path: req.cookies.jgi_session}, function(session_res) {
      if(session_res.statusCode == 200) {
        session_res.on('data', function(chunk) {
          xml2js.parseString(chunk, function(err, session_info) {
            if(!err) {
              var user_url = session_info.session.user;
              var user_req = https.get({hostname:'signon.jgi-psf.org', path: user_url}, function(user_res) {
                user_res.on('data', function(user_chunk) {
                  xml2js.parseString(user_chunk, function(err2, user_info) {
                    if(!err2) {
                      userCache[jgi_session_id] = user_info.user;
                      callback( null, user_info.user );
                    } else {
                      callback( err2, null );
                    }
                  });
                });
              });
            } else {
              callback( err, null );
            }
          });
        });
      }
    });
  }
};

/*
db.on('trace', function(query) {
  console.log('SQLite: ' + query);
});
*/

var config = null;

db.serialize(function() {

  var install_location = '/global/homes/e/ewanders/scd-1.3.2';
  var nt_location = '/global/dna/shared/rqc/ref_databases/ncbi/CURRENT/nt/nt';
  var working_dir = '/global/homes/e/ewanders/prod/scd-viz/working_dirs';
  fs.exists(working_dir, function(exists) {
    if(!exists) {
      fs.mkdir(working_dir, function(err) {
        if(err) {
          console.log(err);
        }
      });
    }
  });
  var scd_exe = 'qsub -N JOBNAME -j y -R y -V -o LOGFILE -l h_rt=12:00:00 -l ram.c=48G -pe pe_slots 8 /global/homes/e/ewanders/scd-1.3.2/bin/scd.sh';
  db.run("CREATE TABLE IF NOT EXISTS config (config_id INTEGER PRIMARY KEY, install_location TEXT, nt_location TEXT, working_dir TEXT, scd_exe TEXT)", function(err) {
    if(!err) {
      db.run("INSERT OR IGNORE INTO config VALUES (1,?,?,?,?)", [install_location, nt_location, working_dir, scd_exe]);
      db.get("SELECT * FROM config", function(err, config_row) {
        if(!err) {
          config = config_row;
          console.log('Config: ' + JSON.stringify(config));
        } else {
          console.log(err);
        }
      });
    }
  });
  db.run("CREATE TABLE IF NOT EXISTS project (project_id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, taxon_display_name TEXT, taxon_domain TEXT, taxon_phylum TEXT, taxon_class TEXT, taxon_order TEXT, taxon_family TEXT, taxon_genus TEXT, taxon_species TEXT)", function(err) {
    if(!err) {
      db.run("INSERT OR IGNORE INTO project VALUES (1,?,?,?,?,?,?,?,?,?)", [
          5381,
          'Bradyrhizobium sp. JGI 001005-E20',
          'Bacteria',
          'Proteobacteria',
          'Alphaproteobacteria',
          'Rhizobiales',
          'Bradyrhizobiaceae',
          'Bradyrhizobium',
          null
        ]);
    }
  });
  db.run("CREATE TABLE IF NOT EXISTS job (job_id INTEGER PRIMARY KEY AUTOINCREMENT, project_id INT, user_id INTEGER, process_id INT, start_time INT, in_fasta TEXT, notes TEXT, is_public INT)");
});

// GET
exports.projects = function(req, res) {
  getUser(req, function(user_err, user) {
    if(!user_err) {
      var projects = [];
      db.each("SELECT project_id,taxon_display_name FROM project WHERE user_id = ?", [user.id[0]], function(err, row) {
        if(err) {
          console.log(err);
        } else {
          projects.push(row);
        }
      }, function(err) { // called last
        if(err) {
          console.log(err);
        }
        res.json({ projects: projects });
      });
    } else {
      console.log(user_err);
      res.json(false);
    }
  });
};

exports.project = function(req, res) {
  getUser(req, function(user_err, user) {
    if(!user_err) {
      var id = req.params.id;
      db.each("SELECT * FROM project WHERE project_id = ? AND user_id = ?", [id, user.id[0]], function(err, row) {
        if(!err) {
          res.json({ project: row });
        } else {
          res.json(false);
        }
      });
    } else {
      console.log(user_err);
      res.json(false);
    }
  });
};

exports.jobs = function(req, res) {

  var getJobs = function(req, res, query, params) {
    var jobs = [];
    /*
    console.log('query: '+query);
    console.log('params: '+params);
    */
    db.each(query, params, function(err, row) {
      if(err) {
        console.log(err);
      /*
      } else {
        console.log(row);
        */
      }
      jobs.push(row);
      //console.log(jobs);
    }, function(err) {
      if(err) {
        console.log(err);
      }
      res.json({ jobs: jobs });
    });
  };

  if( req.query.is_public ) {
    var query_str = "SELECT * FROM job NATURAL JOIN project WHERE is_public = 1";
    var query_param = [];
    getJobs(req, res, query_str, query_param);
  } else {
    getUser(req, function(user_err, user) {
      if(!user_err) {
        var query_str = "SELECT * FROM job NATURAL JOIN project WHERE user_id = ?";
        var query_param = [user.id[0]];
        getJobs(req, res, query_str, query_param);
      } else {
        console.log(user_err);
        res.json(false);
      }
    });
  }
};

exports.jobsInProject = function(req, res) {
  getUser(req, function(user_err, user) {
    if(!user_err) {
      var id = req.params.id
      var jobs = [];
        db.each("SELECT * FROM job WHERE project_id = ? AND user_id = ?", [id, user.id[0]], function(err, row) {
        if(err) {
          console.log(err);
        /*
        } else {
          console.log(row);
          */
        }
        jobs.push(row);
        //console.log(jobs);
      }, function(err) {
        if(err) {
          console.log(err);
        }
        res.json({ jobs: jobs });
        });
    } else {
      console.log(user_err);
      res.json(false);
    }
  });
};

exports.job = function(req, res) {
  getUser(req, function(user_err, user) {
    if(!user_err) {
      var id = req.params.id;
      db.get("SELECT * FROM job NATURAL JOIN project WHERE job_id = ? AND (user_id = ? OR is_public = 1)", [id, user.id[0]], function(err, row) {
        if(!err && row) {
          var process = spawn('qs', ['-j', row.process_id, '--style', 'json']);
          process.stdout.on('data', function(data) {
            //console.log('qs stdout: ' + data);
            var status = JSON.parse(new String(data).split('\n')[0]);
            if(status.length == 1) {
              if(status[0].state.match(/qw/)) {
                row.process_status = 'Waiting in Queue';
              } else if(status[0].state.match(/r/)) {
                row.process_status = 'Running';
              } else if(status[0].state.match(/t/)) {
                row.process_status = 'Transfer';
              } else {
                row.process_status = 'Unknown';
              }
              if(status[0].state.match(/E/)) {
                row.process_status = row.process_status + ' (ERROR)';
              }
              if(status[0].state.match(/h/)) {
                row.process_status = row.process_status + ' (HOLD)';
              }
              if(status[0].state.match(/R/)) {
                row.process_status = row.process_status + ' (RESUBMITTED)';
              }
              res.json({ job: row });
            } else {
              fs.exists(config.working_dir+'/sso_'+user.id[0]+'/job_'+row.job_id, function(exists) {
                if(exists) {
                  row.process_status = 'Complete';
                } else {
                  row.process_status = 'unknown';
                }
                res.json({ job: row });
              });
            }
          });
          process.stderr.on('data', function(data) {
            console.log('qs stderr: ' + data);
          });
          /*
          process.on('close', function(code) {
            console.log('qs exited with status: ' + code);
          });
          */
        } else {
          res.json(false);
        }
      });
    } else {
      console.log(user_err);
      res.json(false);
    }
  });
};

exports.getSsoUser = function(req, res) {
  getUser(req, function(user_err, user) {
    if(!user_err) {
      res.json(user);
    } else {
      res.json(false);
      console.log('error: ' + err);
    }
  });
};

getWorkingDir = function(req, callback) { // callback(err,workingdir)
  getUser(req, function(user_err, user) {
    if(!user_err) {
      callback(null, config.working_dir + '/sso_' + user.id[0]);
    } else {
      callback(user_err, null);
    }
  });
};

exports.getCleanFasta = function(req, res) {
  getFasta('clean', req, res);
};

exports.getContamFasta = function(req, res) {
  getFasta('contam', req, res);
};

getFasta = function(type, req, res) {
  var id = parseInt(req.params.id);
  db.get('SELECT user_id,is_public FROM job WHERE job_id = ?', [id], function(err, row) {
    if(!err) {
      getUser(req, function(err, user) {
        if(!err) {
          if( user.id[0] == row.user_id || row.is_public ) {
            var workingDir = config.working_dir + '/sso_' + row.user_id;
            var filename = workingDir+'/job_'+id+'/job_'+id+'_output_'+type+'.fna';
            fs.exists(filename, function(exists) {
              if(exists) {
                res.download(filename);
              } else {
                console.log('getFasta: ' + filename + ' does not exist.');
                res.statusCode = 404;
                res.json(false);
              }
            });
          } else {
            console.log(user.id[0] + ' attempted to access fasta for job ' + req.params.id + ', owned by ' + row.user_id);
            res.statusCode = 404;
            res.json(false);
          }
        } else {
          console.log(err);
          res.json(false);
        }
      });
    } else {
      console.log(err);
      res.statusCode = 404;
      res.json(false);
    }
  });
};

exports.getPCA = function(req, res) {
  db.get('SELECT user_id,is_public FROM job WHERE job_id = ?', [req.params.id], function(err, row) {
    if(!err) {
      getUser(req, function(err, user) {
        if(!err) {
          if( user.id[0] == row.user_id || row.is_public ) {
            var pointData = [];
            var workingDir = config.working_dir + '/sso_' + row.user_id;
            var job_name = 'job_' + req.params.id;
            var intermediate_dir = workingDir + '/' + job_name + '/' + job_name + '_Intermediate/';
            fs.readdir(intermediate_dir, function(err, files) {
              var filename_pca = null;
              var filename_names = null;
              files.map(function(filename) {

                if(filename.match(/\.pca$/g)) {
                  filename_pca = intermediate_dir + filename;
                } else if (filename.match(/_names$/g)) {
                  filename_names = intermediate_dir + filename;
                }
              });

              fs.readFile(filename_pca, function(err, data) {
                if(!err) {
                  var lines = data.toString().split('\n');
                  var num_lines = lines.length;
                  for(var i=0; i<num_lines; ++i) {
                    var line = lines[i].split('\t');
                    var point = {};
                    point.x = line[0];
                    point.y = line[1];
                    point.z = line[2];
                    pointData.push(point);
                  }

                  fs.readFile(filename_names, function(err, data) {
                    if(!err) {
                      var lines = data.toString().split('\n');
                      var num_lines = lines.length;
                      for(var i=0; i<num_lines; ++i) {
                        pointData[i].name = lines[i];
                      }

                      res.json({
                        points: pointData
                      });

                    } else {
                      console.log(err);
                      console.log('While opening' + filename_names);
                      res.json(false);
                    }
                  });

                } else {
                  console.log(err);
                  console.log('While opening' + filename_pca);
                  res.json(false);
                }

              });

            });


          } else {
            console.log(user.id[0] + ' attempted to access PCA for job ' + req.params.id + ', owned by ' + row.user_id);
            res.statusCode = 401;
            res.json(false);
          }
        } else {
          console.log(err);
          res.json(false);
        }
      });
    }
  });
}
// POST
exports.addProject = function(req, res) {
  getUser(req, function(user_err, user) {
    if(!user_err) {
      db.run("INSERT INTO project VALUES (NULL,?,?,?,?,?,?,?,?,?)", [user.id[0], req.body.taxon_display_name, req.body.taxon_domain, req.body.taxon_phylum, req.body.taxon_class, req.body.taxon_order, req.body.taxon_family, req.body.taxon_genus, req.body.taxon_species] );
      res.json(req.body);
    } else {
      console.log(user_err);
      res.json(false);
    }
  });
};

exports.addJob = function(req, res) {
  getUser(req, function(user_err, user) {
    if(!user_err) {
      var now = new Date();
      var start_time = now.toDateString() + ' ' + now.toTimeString();
      db.run("INSERT INTO job VALUES (NULL,?,?,?,?,?,?,?)", [req.body.project_id,user.id[0],null,start_time,req.body.in_fasta,req.body.notes,req.body.is_public], function(err) {
        if(!err) {
          db.get("SELECT last_insert_rowid()", function(err,row) {
            if(row) {
              var job_id = row['last_insert_rowid()'];
              db.get("SELECT * FROM job natural join project WHERE job_id = ? AND user_id = ?", [job_id, user.id[0]], function(err, row) {
                if(row) {
                  var cfg = row;
                  cfg.working_dir = config.working_dir + '/sso_' + user.id[0];
                  cfg.job_name = 'job_'+job_id;
                  cfg.install_location = config.install_location;
                  cfg.nt_location = config.nt_location;
                  cfg.run_genecall = 1;
                  cfg.run_blast = 1;
                  cfg.run_classify = 1;
                  cfg.run_accuracy = 0;
                  cfg.blast_threads = 8;
                  var config_data = "";
                  var config_keys = ['taxon_display_name','taxon_domain','taxon_phylum','taxon_class','taxon_order','taxon_family','taxon_genus','taxon_species','install_location','nt_location','working_dir','in_fasta','job_name','run_genecall','run_blast','run_classify','run_accuracy','blast_threads'];
                  for (var k=0; k<config_keys.length; ++k) {
                    var key = config_keys[k];
                    var value = cfg[key];
                    if(value || (key.indexOf('run_' >= 0) || key.indexOf('taxon_') >= 0)) {
                      config_data = config_data + key.toUpperCase() + '=';
                      if(value != null) {
                        config_data = config_data + '"' + value + '"\n';
                      } else {
                        config_data = config_data + '\n';
                      }
                    } else {
                      res.json(false);
                      console.log(key+'='+value);
                      console.log(cfg);
                      return;
                    }
                  }

                  var startJob = function() {
                    var new_config_filename = cfg.working_dir+'/'+cfg.job_name+'_config.cnf';
                    fs.writeFile(new_config_filename, config_data, function(err) {
                      if(!err) {
                        var cmd_line = config.scd_exe.replace("JOBNAME", "SCD_VIZ-"+cfg.job_name).replace("LOGFILE", cfg.working_dir+'/'+cfg.job_name+'-qsub.log')+' '+new_config_filename;
                        var cmd_args = cmd_line.split(' ');
                        var cmd_exe = cmd_args.shift();
                        var process = spawn(cmd_exe, cmd_args);
                        process.stdout.on('data', function(data) {
                          //console.log('stdout: ' + data);
                          var parsed = (new String(data)).match(/Your job ([0-9]+)/);
                          if(parsed.length == 2) {
                            var process_id = parseInt(parsed[1]);
                            console.log('Parsed job id: ' + process_id);
                            db.run("UPDATE job SET process_id = ? WHERE job_id = ?", [process_id, job_id], function(err) {
                              if(!err) {
                                res.json(req.body);
                              } else {
                                console.log('Failed to update job with process_id and working_dir.');
                                console.log(err);
                                res.json(false);
                              }
                            });
                          }
                        });
                        process.stderr.on('data', function(data) {
                          console.log('stderr: ' + data);
                        });
                        /*
                        process.on('close', function(code) {
                          console.log('child process exited with status: ' + code);
                        });
                        */
                      }
                    });
                  }

                  fs.exists(cfg.working_dir, function(exists) {
                    if(!exists) {
                      fs.mkdir(cfg.working_dir, function(err) {
                        if(!err) {
                          startJob();
                        }
                      });
                    } else {
                      startJob();
                    }
                  });

                } else {
                  console.log('Failed to find new row.');
                }
              });
            } else {
              console.log('Failed to get last inserted row id.');
              console.log(err);
            }
          });
        } else {
          console.log('Failed to insert new job into table.');
          console.log(err);
        }
      });
    } else {
      console.log(user_err);
      res.json(false);
    }
  });
};

// DELETE
exports.deleteProject = function(req, res) {
  getUser(req, function(user_err, user) {
    if(!user_err) {
      var id = req.params.id;
      db.run("DELETE FROM project WHERE project_id = ? AND user_id = ?", [id, user.id[0]]);
      db.run("DELETE FROM job WHERE project_id = ? AND user_id = ?", [id, user.id[0]]);
      res.json(true);
    } else {
      console.log(user_err);
      res.json(false);
    }
  });
};

exports.deleteJob = function(req, res) {
  getUser(req, function(user_err, user) {
    if(!user_err) {
      var id = req.params.id;
      db.run("DELETE FROM job WHERE job_id = ? AND user_id = ?", [id, user.id[0]]);
      res.json(true);
    } else {
      console.log(user_err);
      res.json(false);
    }
  });
};

