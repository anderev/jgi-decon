var sqlite3 = require('sqlite3').verbose();
var db = new sqlite3.Database('scd.db');
var spawn = require('child_process').spawn;

db.serialize(function() {
  db.run("CREATE TABLE IF NOT EXISTS project (project_id INTEGER PRIMARY KEY AUTOINCREMENT, taxon_display_name TEXT, taxon_domain TEXT, taxon_phylum TEXT, taxon_class TEXT, taxon_order TEXT, taxon_family TEXT, taxon_genus TEXT, taxon_species TEXT)");
  db.run("CREATE TABLE IF NOT EXISTS job (job_id INTEGER PRIMARY KEY AUTOINCREMENT, project_id INT, process_id INT, start_time INT, end_time INT, install_location TEXT, nt_location TEXT, working_dir TEXT, in_fasta TEXT, job_name TEXT, run_genecall INT, run_blast INT, run_classify INT, run_accuracy INT, blast_threads INT)");
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
	db.each("SELECT * FROM job WHERE job_id = ?", [id], function(err, row) {
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
  var process = spawn('find', ['~ewanders']);
  var pid = process.pid;
  var now = new Date();
  var start_time = now.toDateString() + ' ' + now.toTimeString();
  db.run("INSERT INTO job VALUES (NULL,?,?,?,?,?,?,?,?,?,?,?,?,?,?)", [req.body.project_id,pid,start_time,null,req.body.install_location,req.body.nt_location,req.body.working_dir,req.body.in_fasta,req.body.job_name,req.body.run_genecall,req.body.run_blast,req.body.run_classify,req.body.run_accuracy,req.body.blast_threads] );
  res.json(req.body);
};

// DELETE
exports.deleteProject = function(req, res) {
  var id = req.params.id;
  db.run("DELETE FROM project WHERE project_id = ?", [id]);
  res.json(true);
};

exports.deleteJob = function(req, res) {
  var id = req.params.id;
  db.run("DELETE FROM job WHERE job_id = ?", [id]);
  res.json(true);
};

