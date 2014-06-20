
/**
 * Module dependencies
 */

var express = require('express'),
  routes = require('./routes'),
  api = require('./routes/api'),
  http = require('http'),
  path = require('path'),
  cookie_parser = require('cookie-parser');

var app = module.exports = express();


/**
 * Configuration
 */

// all environments
app.set('port', process.env.PORT || 3051);
app.set('views', __dirname + '/views');
app.set('view engine', 'jade');
app.use(express.logger('dev'));
app.use(express.bodyParser());
app.use(express.methodOverride());
app.use(express.static(path.join(__dirname, 'public')));
app.use(app.router);

// development only
if (app.get('env') === 'development') {
  app.use(express.errorHandler());
}

// production only
if (app.get('env') === 'production') {
  // TODO
}


/**
 * Routes
 */

var cookieParser = cookie_parser('secret string');
var caliban = routes.caliban;
app.get('*', cookieParser);
app.get('*', caliban);
app.post('*', cookieParser);
app.post('*', caliban);
app.delete('*', cookieParser);
app.delete('*', caliban);

app.get('/', routes.index);
app.get('/partials/:name', routes.partials);

// JSON API

app.get('/api/getCleanFasta/:id', api.getCleanFasta);
app.get('/api/getContamFasta/:id', api.getContamFasta);
app.get('/api/jobs', api.jobs);
app.get('/api/jobsInProject/:id', api.jobsInProject);
app.get('/api/job/:id', api.job);
app.get('/api/getPCA/:id', api.getPCA);
app.get('/api/ssoUser', api.getSsoUser);
app.post('/api/job', api.addJob);
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
  console.log('SCD server listening on port ' + app.get('port'));
});
