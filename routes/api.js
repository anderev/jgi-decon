var sqlite3 = require('sqlite3').verbose();
var db = new sqlite3.Database('scd.db');
var spawn = require('child_process').spawn;
var fs = require('fs');

db.serialize(function() {
  var install_location = '/global/homes/e/ewanders/scd-1.3.1';
  var nt_location = '/global/dna/shared/rqc/ref_databases/ncbi/CURRENT/nt/nt';
  var working_dir = '/global/homes/e/ewanders/dev/scd-viz/working_dirs';
  var scd_exe = 'qsub -N JOBNAME -j y -R y -V -o LOGFILE -l h_rt=12:00:00 -l ram.c=48G -pe pe_slots 8 /global/homes/e/ewanders/scd-1.3.2/bin/scd.sh';
  db.run("CREATE TABLE IF NOT EXISTS config (config_id INTEGER PRIMARY KEY, install_location TEXT, nt_location TEXT, working_dir TEXT, scd_exe TEXT)", function(err) {
    if(!err) {
      db.run("INSERT OR IGNORE INTO config VALUES (1,?,?,?,?)", [install_location, nt_location, working_dir, scd_exe]);
    }
  });
  db.run("CREATE TABLE IF NOT EXISTS project (project_id INTEGER PRIMARY KEY AUTOINCREMENT, taxon_display_name TEXT, taxon_domain TEXT, taxon_phylum TEXT, taxon_class TEXT, taxon_order TEXT, taxon_family TEXT, taxon_genus TEXT, taxon_species TEXT)", function(err) {
    if(!err) {
      db.run("INSERT OR IGNORE INTO project VALUES (1,?,?,?,?,?,?,?,?)", [
          'Propionibacteriaceae bacterium P6A17',
          'Bacteria',
          'Actinobacteria',
          'Actinobacteria',
          'Actinomycetales',
          'Propionibacteriaceae',
          null,
          null
        ]);
    }
  });
  db.run("CREATE TABLE IF NOT EXISTS job (job_id INTEGER PRIMARY KEY AUTOINCREMENT, project_id INT, process_id INT, start_time INT, in_fasta TEXT, notes TEXT)");
});

// GET
exports.projects = function(req, res) {
  var projects = [];
	db.each("SELECT project_id,taxon_display_name FROM project", function(err, row) {
    if(err) {
      console.log(err);
    } else {
      console.log(row);
    }
    projects.push(row);
    console.log(projects);
  }, function(err) {
      if(err) {
        console.log(err);
      }
      res.json({
        projects: projects
      })
    });
};

exports.project = function(req, res) {
  var id = req.params.id;
	db.each("SELECT * FROM project WHERE project_id = ?", [id], function(err, row) {
    if(!err) {
      res.json({
        project: row
      });
    } else {
      res.json(false);
    }
  });
};

exports.jobs = function(req, res) {
  var jobs = [];
	db.each("SELECT * FROM job", function(err, row) {
    if(err) {
      console.log(err);
    } else {
      console.log(row);
    }
    jobs.push(row);
    console.log(jobs);
  }, function(err) {
    if(err) {
      console.log(err);
    }
    res.json({
      jobs: jobs
      });
    });
};

exports.jobsInProject = function(req, res) {
  var id = req.params.id
  var jobs = [];
	db.each("SELECT * FROM job WHERE project_id = ?", [id], function(err, row) {
    if(err) {
      console.log(err);
    } else {
      console.log(row);
    }
    jobs.push(row);
    console.log(jobs);
  }, function(err) {
    if(err) {
      console.log(err);
    }
    res.json({
      jobs: jobs
      });
    });
};

exports.job = function(req, res) {
  var id = req.params.id;
	db.get("SELECT * FROM job NATURAL JOIN project WHERE job_id = ?", [id], function(err, row) {
    if(!err) {
      var process = spawn('qs', ['-j', row.process_id, '--style', 'json']);
      process.stdout.on('data', function(data) {
        console.log('qs stdout: ' + data);
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
          res.json({
            job: row
          });
        } else {
          var config;
          db.get("SELECT * FROM config", function(err,config) {
            if(!err) {
              if(fs.existsSync(config.working_dir+'/job_'+row.job_id)) {
                row.process_status = 'Complete';
              } else {
                row.process_status = 'unknown';
              }
              res.json({
                job: row
              });
            } else {
              console.log("Failed to read config from database.");
              res.json(false);
            }});
        }
      });
      process.stderr.on('data', function(data) {
        console.log('qs stderr: ' + data);
      });
      process.on('close', function(code) {
        console.log('qs exited with status: ' + code);
      });
    } else {
      res.json(false);
    }
  });
};

exports.getPCA = function(req, res) {
  db.get("SELECT * FROM config", function(err,config) {
    if(!err) {
      var job_name = 'job_' + req.params.id;
      var filename_pca = config.working_dir + '/' + job_name + '/' + job_name + '_Intermediate/' + job_name + '_contigs_9mer.pca';
      fs.readFile(filename_pca, function(err, data) {
        if(!err) {
          var lines = data.toString().split('\n');
          var pointData = [];
          var num_lines = lines.length;
          for(var i=0; i<num_lines; ++i) {
            var line = lines[i].split('\t');
            var point = {};
            point.x = line[0];
            point.y = line[1];
            point.z = line[2];
            pointData.push(point);
          }

          res.json({
            points: pointData
          })
        } else {
          console.log(err);
          console.log('While opening' + filename_pca);
          res.json(false);
        }
      });
    } else {
      console.log(err);
      res.json(false);
    }
  });
}
// POST
exports.addProject = function(req, res) {
  db.run("INSERT INTO project VALUES (NULL,?,?,?,?,?,?,?,?)", [req.body.taxon_display_name, req.body.taxon_domain, req.body.taxon_phylum, req.body.taxon_class, req.body.taxon_order, req.body.taxon_family, req.body.taxon_genus, req.body.taxon_species] );
  res.json(req.body);
};

exports.addJob = function(req, res) {
  db.get("SELECT * FROM config", function(err,config) {
    if(!err) {
      var now = new Date();
      var start_time = now.toDateString() + ' ' + now.toTimeString();
      db.run("INSERT INTO job VALUES (NULL,?,?,?,?,?)", [req.body.project_id,null,start_time,req.body.in_fasta,req.body.notes], function(err) {
        if(!err) {
        db.get("SELECT last_insert_rowid()", function(err,row) {
          if(row) {
          var job_id = row['last_insert_rowid()'];
          db.get("SELECT * FROM job natural join project WHERE job_id = ?", [job_id], function(err, row) {
            if(row) {
            var cfg = row;
            cfg.working_dir = config.working_dir;
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
            if(!fs.existsSync(cfg.working_dir)) {
              fs.mkdirSync(cfg.working_dir);
            }
            var new_config_filename = cfg.working_dir+'/'+cfg.job_name+'_config.cnf';
            var new_config = fs.openSync(new_config_filename, 'w');
            fs.writeSync(new_config, config_data);
            fs.closeSync(new_config);

            var cmd_line = config.scd_exe.replace("JOBNAME", "SCD_VIZ-"+cfg.job_name).replace("LOGFILE", cfg.working_dir+'/'+cfg.job_name+'-qsub.log')+' '+new_config_filename;
            var cmd_args = cmd_line.split(' ');
            var cmd_exe = cmd_args.shift();
            var process = spawn(cmd_exe, cmd_args);
            process.stdout.on('data', function(data) {
                console.log('stdout: ' + data);
                var parsed = (new String(data)).match(/Your job ([0-9]+)/);
                if(parsed.length == 2) {
                var process_id = parseInt(parsed[1]);
                console.log('Parsed job id: ' + process_id);
                db.run("UPDATE job SET process_id = ? WHERE job_id = ?", process_id, job_id, function(err) {
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
      console.log("Failed to read config from database.");
      res.json(false);
    }});
};

// DELETE
exports.deleteProject = function(req, res) {
  var id = req.params.id;
  db.run("DELETE FROM project WHERE project_id = ?", [id]);
  db.run("DELETE FROM job WHERE project_id = ?", [id]);
  res.json(true);
};

exports.deleteJob = function(req, res) {
  var id = req.params.id;
  db.run("DELETE FROM job WHERE job_id = ?", [id]);
  res.json(true);
};

