var sqlite3 = require('sqlite3').verbose();
var db = new sqlite3.Database('scd.db');
var spawn = require('child_process').spawn;
var fs = require('fs');
var config = require('../config').Config;
var parser = require('./parsers');
var stats = require('./stats');
var caliban = require('./caliban');

/*
db.on('trace', function(query) {
  console.log('SQLite: ' + query);
});
*/

fs.exists(config.working_dir, function(exists) {
  if(!exists) {
    console.log('Creating ' + config.working_dir);
    fs.mkdir(config.working_dir, function(err) {
      if(err) {
        console.log(err);
      }
    });
  }
});

db.serialize(function() {

  db.run("CREATE TABLE IF NOT EXISTS job (job_id INTEGER PRIMARY KEY AUTOINCREMENT, taxon_display_name TEXT, taxon_domain TEXT, taxon_phylum TEXT, taxon_class TEXT, taxon_order TEXT, taxon_family TEXT, taxon_genus TEXT, taxon_species TEXT, user_id INTEGER, process_id INT, start_time TEXT, in_fasta TEXT, notes TEXT, is_public INT, status INT, gc_percent REAL, num_bases INTEGER, num_contigs INTEGER)");
  db.run("CREATE TABLE IF NOT EXISTS eula (user_id INTEGER PRIMARY KEY, time_stamp TEXT)");
});

// GET
exports.jobs = function(req, res) {

  var getJobs = function(req, res, query, params) {
    var jobs = [];
    var id_count = 0;
    db.each(query, params, function(err, row) {
      if(!err) {
        jobs.push(row);
      } else {
        console.log(err);
      }
    }, function(err) {
      if(err) {
        console.log(err);
      }
      if( jobs.length > 0 ) {
        id_count = jobs.length;
        jobs.map(function(job) {
          caliban.getUserInfo(job.user_id, function(err, user) {
            if(!err) {
              job.user_id = user.first_name + ' ' + user.last_name;
              --id_count;
              if(id_count == 0) {
                res.json({ jobs: jobs });
              }
            } else {
              console.log(err);
              res.json(false);
            }
          });
        });
      } else {
        res.json({ jobs: jobs });
      }
    });
  };

  if( req.query.is_public ) {
    var query_str = "SELECT * FROM job WHERE is_public = 1 ORDER BY job_id DESC";
    var query_param = [];
    getJobs(req, res, query_str, query_param);
  } else {
    caliban.getSessionUser(req, function(user_err, user) {
      if(!user_err) {
        var query_str = "SELECT * FROM job WHERE user_id = ? ORDER BY job_id DESC";
        var query_param = [user.id[0]];
        getJobs(req, res, query_str, query_param);
      } else {
        console.log(user_err);
        res.json(false);
      }
    });
  }
};

exports.job = function(req, res) {
  caliban.getSessionUser(req, function(user_err, user) {
    if(!user_err) {
      var id = req.params.id;
      db.get("SELECT * FROM job WHERE job_id = ? AND (user_id = ? OR is_public = 1)", [id, user.id[0]], function(err, row) {
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
  caliban.getSessionUser(req, function(user_err, user) {
    if(!user_err) {
      res.json(user);
    } else {
      res.json(false);
      console.log('error: ' + user_err);
    }
  });
};

exports.getPCA = function(req, res) {
  exports.parseJobFiles(req, res,
    function(contigs, nucs) {
      res.json({
        contigs: contigs,
        nuc_seqs: nucs
      });
    }, function(err) {
      console.log(err);
      res.json(false);
    }
  );
};

exports.parseJobFiles = function(req, res, cb_ok, cb_err) {
  db.get('SELECT user_id,is_public FROM job WHERE job_id = ?', [req.params.id], function(err, row) {
    if(!err) {
      caliban.getSessionUser(req, function(err, user) {
        if(!err) {
          if( user.id[0] == row.user_id || row.is_public ) {
            var contigs = [];
            var workingDir = config.working_dir + '/sso_' + row.user_id;
            var job_name = 'job_' + req.params.id;
            var intermediate_dir = workingDir + '/' + job_name + '/' + job_name + '_Intermediate/';
            fs.readdir(intermediate_dir, function(err, files) {
              var filename_pca = null;
              var filename_names = null;
              var filename_lca = null;
              var filename_blout = null;
              var filename_genes_fna = null;

              if( !files ) {
                res.json(false);
                return;
              }

              files.map(function(filename) {

                if(filename.match(/\.pca$/g)) {
                  filename_pca = intermediate_dir + filename;
                } else if (filename.match(/_names$/g)) {
                  filename_names = intermediate_dir + filename;
                } else if (filename.match(/\.LCA$/g)) {
                  filename_lca = intermediate_dir + filename;
                } else if (filename.match(/\.blout$/g)) {
                  filename_blout = intermediate_dir + filename;
                } else if (filename.match(/_genes.fna$/g)) {
                  filename_genes_fna = intermediate_dir + filename;
                }
              });

              if( !(filename_pca && filename_names && filename_lca && filename_blout && filename_genes_fna) ) {
                res.json(false);
                return;
              }

              fs.readFile(filename_pca, parser.parse_pca(contigs, function(err) {
                if(!err) {
                  fs.readFile(filename_names, parser.parse_names(contigs, function(err) {
                    if(!err) {
                      fs.readFile(filename_lca, parser.parse_lca(contigs, function(err) {
                        if(!err) {
                          fs.readFile(filename_blout, parser.parse_blout(contigs, function(err) {
                            if(!err) {
                              fs.readFile(filename_genes_fna, parser.parse_genes_fna(function(nuc_seqs, err) {
                                if(!err) {
                                  cb_ok(contigs, nuc_seqs);
                                } else {
                                  cb_err(err);
                                }
                              }));
                            } else {
                              cb_err(err);
                            }
                          }));
                        } else {
                          cb_err(err);
                        }
                      }));
                    } else {
                      cb_err(err);
                    }
                  }));
                } else {
                  cb_err(err);
                }
              }));

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
exports.uploadFasta = function(req, res) {
  caliban.getSessionUser(req, function(user_err, user) {
    if(!user_err) {
      var file = req.files.file;
      var newFilename = config.working_dir + '/sso_' + user.id[0] + '/upload.fasta';
      console.log('rename: ' + file.path + ' => ' + newFilename);
      fs.createReadStream(file.path).pipe(fs.createWriteStream(newFilename).on('finish', function() {
        console.log('File upload received: ' + newFilename);
        res.json(req.body);
      }));
    } else {
      console.log(user_err);
      res.json(false);
    }
  });
};

exports.addJob = function(req, res) {
  caliban.getSessionUser(req, function(user_err, user) {
    if(!user_err) {
      var now = new Date();
      var start_time = now.toDateString() + ' ' + now.toTimeString();
      db.serialize(function() {
        db.run("INSERT INTO job VALUES (NULL,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)", [req.body.taxon_display_name, req.body.taxon_domain, req.body.taxon_phylum, req.body.taxon_class, req.body.taxon_order, req.body.taxon_family, req.body.taxon_genus, req.body.taxon_species,user.id[0],null,start_time,req.body.in_fasta,req.body.notes,req.body.is_public,null,null,null,null], function(err) {
          if(err) {
            console.log('Failed to insert new job into table.');
            console.log(err);
          }
        });
        db.get("SELECT last_insert_rowid()", function(err,row) {
          if(row) {
            var job_id = row['last_insert_rowid()'];
            db.get("SELECT * FROM job WHERE job_id = ? AND user_id = ?", [job_id, user.id[0]], function(err, row) {
              if(row) {
                var cfg = row;
                if(!req.body.in_fasta) {
                  var uploadedFilename = config.working_dir + '/sso_' + user.id[0] + '/upload.fasta';
                  fs.exists(uploadedFilename, function(exists) {
                    if(exists) {
                      var permanentFilename = config.working_dir + '/sso_' + user.id[0] + '/uploaded_job_' + job_id + '.fasta';
                      console.log('rename: ' + uploadedFilename + ' => ' + permanentFilename);
                      fs.rename(uploadedFilename, permanentFilename, function(err) {
                        if(err) {
                          console.log(err);
                          res.json(false);
                        } else {
                          prepareJob(permanentFilename);
                        }
                      });
                    } else {
                      console.log('Missing in_fasta.');
                      res.json(false);
                    }
                  });
                } else {
                  prepareJob(req.body.in_fasta);
                }

                function prepareJob(in_fasta) {
                  stats.parse_fna(in_fasta, function(fasta_stats) {
                    db.run("UPDATE job SET gc_percent = ?, num_bases = ?, num_contigs = ? WHERE job_id = ?", [fasta_stats.gc_percent, fasta_stats.num_bases, fasta_stats.num_contigs, job_id], function(err) {
                      if(!err) {
                        console.log('Updated job_id ' + job_id + ' with ' + JSON.stringify(fasta_stats));
                      } else {
                        console.log(err);
                      }
                    });
                  }, function(err) {
                    console.log('Error getting stats on fasta: ' + in_fasta);
                  });
                  cfg.in_fasta = in_fasta;
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
                    console.log('Starting job for config: '+new_config_filename);
                    fs.writeFile(new_config_filename, config_data, function(err) {
                      if(!err) {
                        var cmd_line = config.scd_exe.replace("JOBNAME", "SCD-"+cfg.job_name).replace("LOGFILE", cfg.working_dir+'/'+cfg.job_name+'-qsub.log')+' '+new_config_filename;
                        var cmd_args = cmd_line.split(' ');
                        var cmd_exe = cmd_args.shift();
                        var process = spawn(cmd_exe, cmd_args);
                        process.stdout.on('data', function(data) {
                          console.log('stdout: ' + data);
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
                        process.on('close', function(code) {
                          console.log('child process exited with status: ' + code);
                        });
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

                }
              } else {
                console.log('Failed to find new row.');
              }
            });
          } else {
            console.log('Failed to get last inserted row id.');
            console.log(err);
          }
        });
      });
    } else {
      console.log(user_err);
      res.json(false);
    }
  });
};

// DELETE
exports.deleteJob = function(req, res) {
  caliban.getSessionUser(req, function(user_err, user) {
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

exports.acceptEULA = function(req, res) {
  caliban.getSessionUser(req, function(err, user) {
    if(!err) {
      var now = new Date();
      var time_stamp = now.toDateString() + ' ' + now.toTimeString();
      db.run("INSERT INTO eula VALUES (?,?)", [user.id[0], time_stamp], function() {
        if('eula_return' in req.cookies) {
          res.redirect(req.cookies.eula_return);
        } else {
          res.redirect('/');
        }
      });
    } else {
      console.log(err);
      res.json(false);
    }
  });
};

