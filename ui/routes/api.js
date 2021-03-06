var sqlite3 = require('sqlite3').verbose();
var db = new sqlite3.Database('scd.db');
var fs = require('fs');
var config = require('../config').Config;
var parser = require('./parsers');
var stats = require('./stats');
var caliban = require('./caliban');
var temp = require('temp');
var Q = require('q');

var user_uploads = {};
var qReaddir = Q.nfbind(fs.readdir);
var qReadFile = Q.nfbind(fs.readFile);

db.serialize(function() {

  db.run("CREATE TABLE IF NOT EXISTS job (job_id INTEGER PRIMARY KEY AUTOINCREMENT, taxon_display_name TEXT, taxon_domain TEXT, taxon_phylum TEXT, taxon_class TEXT, taxon_order TEXT, taxon_family TEXT, taxon_genus TEXT, taxon_species TEXT, user_id INTEGER, process_id INT, start_time TEXT, in_fasta TEXT, notes TEXT, is_public INT, status INT, gc_percent REAL, num_bases INTEGER, num_contigs INTEGER, version TEXT)");
  db.run("CREATE TABLE IF NOT EXISTS eula (user_id INTEGER PRIMARY KEY, time_stamp TEXT)");
  db.run("CREATE TABLE IF NOT EXISTS admin (user_id INTEGER PRIMARY KEY)");
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
                jobs.sort(function(job_a, job_b) {
                  if(job_a.notes === null || job_b.notes === null) {
                    return job_b.job_id - job_a.job_id;
                  }

                  if(job_a.notes.match(/endo-.*/) && !job_b.notes.match(/endo-.*/)) {
                    return -1;
                  } else if (!job_a.notes.match(/endo-.*/) && job_b.notes.match(/endo-.*/)) {
                    return 1;
                  } else {
                    return job_b.job_id - job_a.job_id;
                  }
                });
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
        var query_str = "SELECT * FROM job WHERE user_id = ? OR EXISTS (SELECT * FROM admin WHERE user_id = ?) ORDER BY job_id DESC";
        var query_param = [user.id[0], user.id[0]];
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
      db.get("SELECT * FROM job WHERE job_id = ? AND (user_id = ? OR is_public = 1 OR EXISTS (SELECT * FROM admin WHERE user_id = ?))", [id, user.id[0], user.id[0]], function(err, row) {
        if(!err && row) {
          config.job_status(row.job_id, row.process_id, row.user_id)
          .then(function(str_status) {
            row.process_status = str_status;
            res.json({job: row});
          }, function(reason) {
            console.log('job status error: '+reason);
            res.json(false);
          });
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
  caliban.getSessionUser(req, function(err, user) {
    if(!err) {
      db.get('SELECT user_id FROM job WHERE job_id = ? AND ( user_id = ? OR is_public = 1 OR EXISTS (SELECT * FROM admin WHERE user_id = ?))', [req.params.id, user.id[0], user.id[0]], function(err, row) {
        if(!err) {
          if( undefined !== row ) {
            var contigs = [];
            var workingDir = config.local_working_dir + '/sso_' + row.user_id;
            var job_name = 'job_' + req.params.id;
            var jobDir = workingDir + '/' + job_name;
            var intermediate_dir = jobDir + '/' + job_name + '_Intermediate';
            var filename_lca = intermediate_dir + '/' + job_name + '_contigs.LCA';
            var filename_blout = intermediate_dir + '/' + job_name + '_genes.blout';
            var filename_genes_fna = intermediate_dir + '/' + job_name + '_genes.fna';
            var filename_contam_fna = jobDir + '/' + job_name + '_output_contam.fna';

            var filename_names;
            var filename_pca;
            qReaddir(intermediate_dir)
            .then(function(filenames) {
              filenames.map(function(filename) {
                if(filename.match(/_contigs_kmervecs_.*_names/)) {
                  filename_names = intermediate_dir + '/' + filename;
                } else if(filename.match(/_contigs_.*mer\.pca/)) {
                  filename_pca = intermediate_dir + '/' + filename;
                }
              })

              parser.parse_pca(filename_pca).then(function(contigs) {
                parser.parse_names(filename_names, contigs).then(function(contigs) {
                  parser.parse_lca(filename_lca, contigs).then(function(contigs) {
                    parser.parse_blout(filename_blout, contigs).then(function(contigs) {
                      parser.parse_genes_fna(filename_genes_fna).then(function(nuc_seqs) {
                        parser.parse_fna(filename_contam_fna).then(function(contam_contigs) {
                          var contam_map = {}
                          contam_contigs.map(function(contig) { var id = contig.id.split(' ')[0]; contam_map[id] = true; })
                          contigs.map(function(contig) { if (contig.name in contam_map) { contig.is_contam = true; } })
                          cb_ok(contigs, nuc_seqs);
                        })
                      })
                    })
                  });
                });
              }).catch(function(reason){
                cb_err(reason)
              });
            })
            .fail(function(err) {
              cb_err(err)
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
      req.pipe(req.busboy);
      req.busboy.on('file', function(fieldname, file, filename) {
        console.log('Receiving file: ' + filename);
        var fstream = temp.createWriteStream();
        file.pipe(fstream);
        fstream.on('close', function() {
          user_uploads[user.id[0]] = fstream.path;
          console.log('Finished receiving: ' + filename + ' at ' + fstream.path );
          res.json(req.body);
        });
      });
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
        db.run("INSERT INTO job VALUES (NULL,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)", [(req.body.taxon_display_name || '').trim(), (req.body.taxon_domain || '').trim(), (req.body.taxon_phylum || '').trim(), (req.body.taxon_class || '').trim(), (req.body.taxon_order || '').trim(), (req.body.taxon_family || '').trim(), (req.body.taxon_genus || '').trim(), (req.body.taxon_species || '').trim(), user.id[0],null,start_time, req.body.in_fasta, (req.body.notes || '').trim(),req.body.is_public,null,null,null,null, config.version], function(err) {
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
                var temp_fasta_filename = user_uploads[user.id[0]];

                fs.exists(temp_fasta_filename, function(exists) {
                  if(exists) {
                    var parse_promise = stats.parse_fna(temp_fasta_filename)
                    .then( function(fasta_stats) {
                      db.run("UPDATE job SET gc_percent = ?, num_bases = ?, num_contigs = ? WHERE job_id = ?", [fasta_stats.gc_percent, fasta_stats.num_bases, fasta_stats.num_contigs, job_id], function(err) {
                        if(!err) {
                          console.log('Updated job_id ' + job_id + ' with ' + JSON.stringify(fasta_stats));
                        } else {
                          console.log(err);
                        }
                      });
                    }, function(err) {
                      console.log('Error getting stats on fasta: ' + temp_fasta_filename + ' ERROR: ' + err);
                    });
                    cfg.working_dir = config.remote_working_dir + '/sso_' + user.id[0];
                    cfg.in_fasta = cfg.working_dir + '/job_' + job_id + '.fna';
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

                    temp.open('c-', function(err, info) {
                      if(!err) {
                        console.log('Starting job for config: '+info.path);
                        fs.write(info.fd, config_data);
                        fs.close(info.fd, function(err) {
                          if(!err) {
                            var job_start_promise = config.job_start(job_id, info.path, temp_fasta_filename, user.id[0])
                            .then( function(process_id) {
                              db.run("UPDATE job SET process_id = ? WHERE job_id = ?", [process_id, job_id], function(err) {
                                if(!err) {
                                  res.json(req.body);
                                } else {
                                  console.log('Failed to update job with process_id and working_dir.');
                                  console.log(err);
                                  res.json(false);
                                }
                              });
                            }, function(reason) {
                              console.log('job_start error: '+err);
                            });
                            Q.allSettled([parse_promise, job_start_promise]).done(function() {
                              fs.unlink(info.path);
                              fs.unlink(temp_fasta_filename);
                            });
                          }
                        });
                      }
                    });
                  } else {
                    console.log('Missing fasta: '+temp_fasta_filename);
                    res.json(false);
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

exports.imgProject = function(req, res) {
  var taxon = req.params.taxon;
  //Currently assumes display name is IMG taxon.
  db.get("SELECT job_id FROM job WHERE taxon_display_name = ?", [taxon], function(err, row) {
    if(!err) {
      if(row) {
        res.json({url: '/readJob/'+row.job_id})
      } else {
        res.json({})
      }
    } else {
      console.log(err);
      res.json({error: err})
    }
  })
};

