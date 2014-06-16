var sqlite3 = require('sqlite3').verbose();
var db = new sqlite3.Database('scd.db');
var https = require('https');
var xml2js = require('xml2js');
var fs = require('fs');

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
  var id = parseInt(req.params.id);
  getWorkingDir( req, function(err, workingDir) {
    if(!err) {
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
      console.log(err);
      res.statusCode = 404;
      res.json(false);
    }
  });
};

redirectToCaliban = function(appPort, req, res) {
  var jgi_return = 'http://' + req.host + ':' + appPort + req.originalUrl;
  res.cookie('jgi_return', jgi_return, {domain: '.jgi-psf.org'});
  res.redirect('https://signon2.jgi-psf.org');
}

var session_cache = {}; // jgi_session_id -> expiration (when we refresh from Caliban)
exports.caliban = function(appPort) {
  return function(req, res, next) {

    //remove expired entries first
    for( var session in session_cache ) {
      if( session_cache[session] < Date.now() ) {
        delete session_cache[session];
      }
    }

    if( req.cookies && 'jgi_session' in req.cookies) {
      console.log('jgi_session: ' + req.cookies.jgi_session);
      var session_id = req.cookies.jgi_session.split('/')[3];
      if( session_id in session_cache ) {
        next();
      } else {
        var session_req = https.get({hostname:'signon.jgi-psf.org', path: req.cookies.jgi_session}, function(session_res) {
          if(session_res.statusCode == 200) {
              session_cache[session_id] = Date.now() + 60000;
              next();
          } else {
            console.log('session_res.statusCode: ' + session_res.statusCode);
            redirectToCaliban(appPort, req, res);
          }
        }).on('error', function(e) {
          console.log('Error checking session against Caliban: ' + e);
        });
      }
    } else {
      redirectToCaliban(appPort, req, res);
    }
  }
}
