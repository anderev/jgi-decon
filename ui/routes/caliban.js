var https = require('https');
var xml2js = require('xml2js');
var caliban = require('./caliban');
var config = require('../config').Config;

var sessionExpirations = {}; // jgi_session_id -> expiration (when we refresh from Caliban)
var sessionCache = {}; // jgi_session_id -> userObject
var sessionRequestQueue = {}; // jgi_session_id -> [callback, callback, ...]
var userCache = {}; // sso_id -> userObject
var userRequestQueue = {}; // sso_id -> [callback, callback, ...]

exports.getUserInfo = function(user_id, callback) {
  if( user_id in userCache ) {
    callback( null, userCache[user_id]);
  } else {
    if( user_id in userRequestQueue ) {
      userRequestQueue[user_id].push(callback);
    } else {
      userRequestQueue[user_id] = [callback];
      var request = config.caliban_api_users(user_id, function(user_res) {
        user_res.on('data', function(user_chunk) {
          xml2js.parseString(user_chunk, function(err, user_info) {
            if(!err) {
              console.log('Caching SSO user: '+user_info.user.login);
              userCache[user_id] = user_info.user;
              userRequestQueue[user_id].map(function(cb) {
                cb( null, user_info.user );
              });
            } else {
              userRequestQueue[user_id].map(function(cb) {
                cb( err, null );
              });
            }
            delete userRequestQueue[user_id];
          });
        });
      });
    }
  }
};

exports.getSessionUser = function(req, callback) { // callback = function(err, user)
  var jgi_session_id = req.cookies.jgi_session.toString().split('/')[3];
  if( jgi_session_id in sessionCache ) {
    callback( null, sessionCache[jgi_session_id] );
  } else {
    if( jgi_session_id in sessionRequestQueue ) {
      sessionRequestQueue[jgi_session_id].push(callback);
    } else {
      sessionRequestQueue[jgi_session_id] = [callback];
      var session_req = config.caliban_api_session(req.cookies.jgi_session, function(session_res) {
        if(session_res.statusCode == 200) {
          session_res.on('data', function(chunk) {
            xml2js.parseString(chunk, function(err, session_info) {
              if(!err) {
                var user_id_tokens = session_info.session.user.toString().split('/');
                var user_id = user_id_tokens[user_id_tokens.length-1];
                exports.getUserInfo(user_id, function(err, user) {
                  if(!err) {
                    console.log('Caching session: '+jgi_session_id);
                    sessionCache[jgi_session_id] = user;
                    sessionRequestQueue[jgi_session_id].map(function(cb) {
                      cb(null, user);
                    });
                  } else {
                    sessionRequestQueue[jgi_session_id].map(function(cb) {
                      cb(err, null);
                    });
                  }
                  delete sessionRequestQueue[jgi_session_id];
                });
              } else {
                callback( err, null );
              }
            });
          });
        }
      });
    }
  }
};

exports.calibanRoute = function(req, res, next) {

  redirectToCaliban = function(req, res) {
    var jgi_return = config.caliban_return_URL;
    res.cookie('jgi_return', jgi_return, {domain: config.caliban_cookie_domain});
    res.redirect(config.caliban_signon_URL);
  }

  //remove expired entries first
  for( var session in sessionExpirations ) {
    if( sessionExpirations[session] < Date.now() ) {
      delete sessionExpirations[session];
    }
  }

  if( req.cookies && 'jgi_session' in req.cookies) {
    caliban.getSessionUser(req, function(err, user) {
      if(!err) {
        console.log('request from: ' + user.login);
      } else {
        console.log(err);
      }
    });

    var session_id = req.cookies.jgi_session.split('/')[3];
    if( session_id in sessionExpirations ) {
      next();
    } else {
      var session_req = config.caliban_api_session(req.cookies.jgi_session, function(session_res) {
        if(session_res.statusCode == 200) {
            sessionExpirations[session_id] = Date.now() + 60000;
            next();
        } else {
          console.log('session_res.statusCode: ' + session_res.statusCode);
          redirectToCaliban(req, res);
        }
      }).on('error', function(e) {
        console.log('Error checking session against Caliban: ' + e);
      });
    }
  } else {
    redirectToCaliban(req, res);
  }
}

exports.startCalibanStub = function(app) {
  var jstoxml = require('jstoxml');
  
  app.get('/caliban/api/users/:id', function(req, res) {
  	res.send(jstoxml.toXML({
  		user: {
  			login: 'stub_login',
  			email: 'stub_email',
  			id: req.params.id,
  			prefix: 'stub_prefix',
  			first_name: 'stub_first_name',
  			last_name: 'stub_last_name',
  			suffix: 'stub_suffix',
  			gender: 'stub_gender',
  			institution: 'stub_institution',
  			department: 'stub_department',
  			address_1: 'stub_address_1',
  			address_2: 'stub_address_2',
  			city: 'stub_city',
  			state: 'stub_state',
  			postal_code: 'stub_postal_code',
  			country: 'stub_country',
  			phone_number: 'stub_phone_number',
  			fax_number: 'stub_fax_number',
  			updated_at: 'stub_updated_at',
  			contact_id: 'stub_contact_id',
  			internal: 'stub_internal'
  		}
  	}));
  	res.status(200).end();
  });
  
  app.get('/caliban/api/sessions/:session_id', function(req, res) {
  	res.send(jstoxml.toXML({
  		session: {
  			location: '/api/sessions/stub',
  			user: '/api/users/stub',
  			ip: '0.0.0.0'
  		}
  	}));
  	res.status(200).end();
  });
  
  app.post('/caliban/api/sessions/:session_id', function(req, res) {
  	res.status(200).end();
  });
  
  app.get('/caliban/signon', function(req, res) {
  	var jgi_return = req.cookies.jgi_return;
  	console.log(req.cookies);
  	res.cookie('jgi_return', jgi_return, {domain: config.caliban_cookie_domain});
  	res.send('<html><body><h1>Caliban Stub</h1><form method="post">name: <input name="login"/><br>password: <input name="password" type="password"><br><input type="submit" value="Submit"/></body></html>');
  	res.status(200).end();
  });
  
  app.post('/caliban/signon', function(req, res) {
  	var jgi_return = req.cookies.jgi_return;
  	if(jgi_return) {
		res.cookie('jgi_session', '/api/sessions/stub', {domain: config.caliban_cookie_domain});
  		res.redirect(jgi_return);
  	} else {
  		res.send('<html><body><h1>Caliban Stub</h1>jgi_return cookie not set.</body></html>');
  		res.status(200).end();
  	}
  });

}

