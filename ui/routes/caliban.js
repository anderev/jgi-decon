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
      console.log('caliban_api_session call'); 
      var session_req = config.caliban_api_session(req.cookies.jgi_session, function(session_res) {
        console.log('caliban_api_session returned'); 
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
