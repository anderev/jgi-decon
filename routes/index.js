var sqlite3 = require('sqlite3').verbose();
var db = new sqlite3.Database('scd.db');
var https = require('https');
var xml2js = require('xml2js');

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
  var id = parseInt(req.params.id);
  db.get("SELECT * FROM config", function(err, row) {
    if(!err) {
      res.download(row.working_dir+'/job_'+id+'/job_'+id+'_output_'+type+'.fna');
    } else {
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
    if( req.cookies && 'jgi_session' in req.cookies) {
      console.log('jgi_session: ' + req.cookies.jgi_session);
      var session_id = req.cookies.jgi_session.split('/')[3];
      if( session_id in session_cache && session_cache[session_id] > Date.now() ) {
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
