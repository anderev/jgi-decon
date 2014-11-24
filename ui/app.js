
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
  cookie_parser = require('cookie-parser');

var app = module.exports = express();
var config = require('./config.js').Config;


/**
 * Configuration
 */

// all environments
app.set('port', config.port);
app.set('views', __dirname + '/views');
app.set('view engine', 'jade');
app.use(express.logger('dev'));
app.use(express.bodyParser());
app.use(express.methodOverride());
app.use(express.static(path.join(__dirname, 'public')));
app.use(app.router);

// development only
if (config.env === 'development') {
  app.use(express.errorHandler());
}

// production only
if (config.env === 'production') {
  // TODO
}


/**
 * Routes
 */

var cookieParser = cookie_parser('secret string');
var calibanRoute = caliban.calibanRoute;
app.get('*', cookieParser);
app.get('*', calibanRoute);
app.post('*', cookieParser);
app.post('*', calibanRoute);
app.delete('*', cookieParser);
app.delete('*', calibanRoute);

app.get('/', routes.index);
app.get('/partials/:name', routes.partials);
app.get('/eula', routes.EULA);

// DOWNLOADS

app.get('/download/*', download.checkEULA);
app.get('/download/clean/:id', download.getClean);
app.get('/download/contam/:id', download.getContam);
app.get('/download/src', download.getSrc);

// JSON API

app.get('/api/acceptEULA', api.acceptEULA);
app.get('/api/jobs', api.jobs);
app.get('/api/jobsInProject/:id', api.jobsInProject);
app.get('/api/job/:id', api.job);
app.get('/api/getPCA/:id', api.getPCA);
app.get('/api/ssoUser', api.getSsoUser);
app.post('/api/job', api.addJob);
app.post('/api/uploadFasta', api.uploadFasta);
app.delete('/api/job/:id', api.deleteJob);

app.get('/api/projects', api.projects);
app.get('/api/project/:id', api.project);
app.post('/api/project', api.addProject);
app.delete('/api/project/:id', api.deleteProject);

// redirect all others to the index (HTML5 history)
app.get('*', routes.index);


/**
 * Start Server
 */

http.createServer(app).listen(app.get('port'), function () {
  console.log(config.env + ' ProDeGe server listening on port ' + app.get('port'));
});
