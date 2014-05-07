var sqlite3 = require('sqlite3').verbose();
var db = new sqlite3.Database('scd.db');
var spawn = require('child_process').spawn;
var fs = require('fs');

db.serialize(function() {
  var install_location = '/global/homes/e/ewanders/scd-1.3.1';
  var nt_location = '/global/dna/shared/rqc/ref_databases/ncbi/CURRENT/nt/nt';
  var working_dir = '/global/homes/e/ewanders/dev/scd-viz-3/working_dirs';
  db.run("CREATE TABLE IF NOT EXISTS config (config_id INTEGER PRIMARY KEY, install_location TEXT, nt_location TEXT, working_dir TEXT)", function(err) {
    if(!err) {
      db.run("INSERT OR IGNORE INTO config VALUES (1,?,?,?)", [install_location, nt_location, working_dir]);
    }
  });
  db.run("CREATE TABLE IF NOT EXISTS project (project_id INTEGER PRIMARY KEY AUTOINCREMENT, taxon_display_name TEXT, taxon_domain TEXT, taxon_phylum TEXT, taxon_class TEXT, taxon_order TEXT, taxon_family TEXT, taxon_genus TEXT, taxon_species TEXT)");
  db.run("CREATE TABLE IF NOT EXISTS job (job_id INTEGER PRIMARY KEY AUTOINCREMENT, project_id INT, process_id INT, start_time INT, end_time INT, working_dir TEXT, in_fasta TEXT, job_name TEXT, run_genecall INT, run_blast INT, run_classify INT, run_accuracy INT, blast_threads INT)");
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
	db.get("SELECT * FROM job WHERE job_id = ?", [id], function(err, row) {
    if(!err) {
      res.json({
        job: row
      });
    } else {
      res.json(false);
    }
  });
};

// POST
exports.addProject = function(req, res) {
  db.run("INSERT INTO project VALUES (NULL,?,?,?,?,?,?,?,?)", [req.body.taxon_display_name, req.body.taxon_domain, req.body.taxon_phylum, req.body.taxon_class, req.body.taxon_order, req.body.taxon_family, req.body.taxon_genus, req.body.taxon_species] );
  res.json(req.body);
};

exports.addJob = function(req, res) {
  var config;
  db.get("SELECT * FROM config", function(err,row) {
    if(!err) {
      config = row;
    } else {
      console.log("Failed to read config from database.");
      res.json(false);
    }});
  var now = new Date();
  var start_time = now.toDateString() + ' ' + now.toTimeString();
  db.run("INSERT INTO job VALUES (NULL,?,?,?,?,?,?,?,?,?,?,?,?)", [req.body.project_id,null,start_time,null,null,req.body.in_fasta,'',req.body.run_genecall,req.body.run_blast,req.body.run_classify,req.body.run_accuracy,req.body.blast_threads], function(err) {
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

              var process = spawn('/global/homes/e/ewanders/scd-1.3.1/bin/scd.sh', [new_config_filename]);
              process.stdout.on('data', function(data) {
                console.log('stdout: ' + data);
              });
              process.stderr.on('data', function(data) {
                console.log('stderr: ' + data);
              });
              process.on('close', function(code) {
                console.log('child process exited with status: ' + code);
              });
              var pid = process.pid;
              db.run("UPDATE job SET process_id = ?, working_dir = ?, job_name = ? WHERE job_id = ?", pid, cfg.working_dir+'/'+cfg.job_name, cfg.job_name, job_id, function(err) {
                if(!err) {
                  res.json(req.body);
                } else {
                  res.jason(false);
                }
              });
            } else {
              console.log('Failed to find new row.');
            }
          });
      } else {
        console.log('Failed to get last inserted row id.');
      }
    });
  } else {
    console.log('Failed to insert new job into table.');
  }
  });
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

