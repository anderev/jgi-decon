var https = require('https');
var xml2js = require('xml2js');

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
      var user_req = https.get({hostname:'signon.jgi-psf.org', path: '/api/users/'+user_id}, function(user_res) {
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
      var session_req = https.get({hostname:'signon.jgi-psf.org', path: req.cookies.jgi_session}, function(session_res) {
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

