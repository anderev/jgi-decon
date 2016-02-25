
/**
 * Module dependencies
 */

var express = require('express'),
  routes = require('./routes'),
  api = require('./routes/api'),
  http = require('http'),
  path = require('path'),
  caliban = require('./routes/caliban'),
  download = require('./routes/download'),
  cookie_parser = require('cookie-parser'),
  morgan = require('morgan'),
  bodyParser = require('body-parser'),
  busboy = require('connect-busboy');

var app = module.exports = express();
var config = require('./config.js').Config;

var redirectToExternal = function(req, res, next) {
  console.log('Got request.')
  var oldDomainRE = /jgi-psf\.org/;
  if( req.get('host').match(oldDomainRE) || req.get('x-forwarded-host').match(oldDomainRE) ) {
    console.log('Redirecting jgi-psf.org to jgi.doe.gov.');
    res.redirect(config.caliban_return_URL.slice(0,-1)+req.originalUrl);
  } else {
    next();
  }
}

app.get('*', redirectToExternal);
app.post('*', redirectToExternal);
app.delete('*', redirectToExternal);

/**
 * Configuration
 */

// all environments
app.set('port', config.port);
app.set('views', __dirname + '/views');
app.set('view engine', 'jade');
app.use(morgan('combined'));
app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());
app.use(busboy());
app.use(express.static(path.join(__dirname, 'public')));


/**
 * Routes
 */

var cookieParser = cookie_parser('secret string');
var calibanRoute = caliban.calibanRoute;

app.get('/api/img/:taxon', api.imgProject);
app.get('*', cookieParser);
app.post('*', cookieParser);
app.delete('*', cookieParser);

// staging only
if (config.env === 'staging') {
  // TODO
}

// production only
if (config.env === 'production') {
  // TODO
}

app.get('*', calibanRoute);
app.post('*', calibanRoute);
app.delete('*', calibanRoute);

app.get('/', routes.index);
app.get('/partials/:name', routes.partials);
app.get('/eula', routes.EULA);

// DOWNLOADS

app.get('/downloads?/*', download.checkEULA);
app.get('/downloads?/clean/:id', download.getClean);
app.get('/downloads?/contam/:id', download.getContam);
app.get('/downloads?/src', download.getSrc);

// JSON API

app.get('/api/acceptEULA', api.acceptEULA);
app.get('/api/jobs', api.jobs);
app.get('/api/job/:id', api.job);
app.get('/api/getPCA/:id', api.getPCA);
app.get('/api/ssoUser', api.getSsoUser);
app.post('/api/job', api.addJob);
app.post('/api/uploadFasta', api.uploadFasta);
app.delete('/api/job/:id', api.deleteJob);

// redirect all others to the index (HTML5 history)
app.get('*', routes.index);


/**
 * Start Server
 */

http.createServer(app).listen(app.get('port'), function () {
  console.log(config.env + ' ProDeGe server listening on port ' + app.get('port'));
});

