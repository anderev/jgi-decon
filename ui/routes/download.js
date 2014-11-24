var config = require('../config').Config;
var sqlite3 = require('sqlite3').verbose();
var db = new sqlite3.Database('scd.db');
var caliban = require('./caliban');
var fs = require('fs');

exports.checkEULA = function(req, res, next) {
  caliban.getSessionUser(req, function(err, user) {
    if(!err) {
      db.get('SELECT COUNT(*) FROM eula WHERE user_id = ?', [user.id[0]], function(err, row) {
        if(!err) {
          if(row['COUNT(*)'] > 0) {
            next();
          } else {
            res.cookie('eula_return', req.originalUrl, {domain: '.jgi-psf.org'});
            res.redirect('/eula');
          }
        } else {
          console.log(err);
          res.cookie('eula_return', req.originalUrl, {domain: '.jgi-psf.org'});
          res.redirect('/eula');
        }
      });
    } else {
      console.log(err);
      res.json(false);
    }
  });
};

exports.getClean = function(req, res) {
  getDownload('clean', req, res);
};

exports.getContam = function(req, res) {
  getDownload('contam', req, res);
};

exports.getSrc = function(req, res) {
  res.download(config.src_bundle);
};

getDownload = function(type, req, res) {
  var id = parseInt(req.params.id);
  db.get('SELECT user_id,is_public FROM job WHERE job_id = ?', [id], function(err, row) {
    if(!err) {
      caliban.getSessionUser(req, function(err, user) {
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

