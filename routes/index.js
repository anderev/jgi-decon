var sqlite3 = require('sqlite3').verbose();
var db = new sqlite3.Database('scd.db');

/*
 * GET home page.
 */

exports.index = function(req, res){
  res.render('index');
};

exports.partials = function (req, res) {
  var name = req.params.name;
  res.render('partials/' + name);
};

exports.getCleanFasta = function(req, res) {
  getFasta('clean', req, res);
};

exports.getContamFasta = function(req, res) {
  getFasta('contam', req, res);
};

getFasta = function(type, req, res) {
  var id = req.params.id;
	db.get("SELECT * FROM job NATURAL JOIN project WHERE job_id = ?", [id], function(err, row) {
    if(!err) {
      res.download(row.working_dir+'/job_'+row.job_id+'_output_'+type+'.fna');
    } else {
      res.json(false);
    }
  });
};

