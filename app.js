
/**
 * Module dependencies
 */

var express = require('express'),
  routes = require('./routes'),
  api = require('./routes/api'),
  http = require('http'),
  path = require('path'),
  cookieParser = require('cookie-parser');

var app = module.exports = express();


/**
 * Configuration
 */

// all environments
app.set('port', process.env.PORT || 2999);
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

app.get('*', cookieParser('secret string'));
app.get('*', function(req, res, next) {
  if( req.cookies && 'jgi_session' in req.cookies) {
    console.log(req.cookies);
    next();
  } else {
    console.log('Cookies: ' + JSON.stringify(req.cookies));
	var jgi_return = 'http://mgs.jgi-psf.org' + req.originalUrl;
	console.log('Redirecting with jgi_return: ' + jgi_return);
    res.cookie('jgi_return', jgi_return);
    res.redirect('https://signon2.jgi-psf.org');
  }
});
app.get('/', routes.index);
app.get('/partials/:name', routes.partials);
app.get('/getCleanFasta/:id', routes.getCleanFasta);
app.get('/getContamFasta/:id', routes.getContamFasta);

// JSON API

app.get('/api/jobs', api.jobs);
app.get('/api/jobsInProject/:id', api.jobsInProject);
app.get('/api/job/:id', api.job);
app.get('/api/getPCA/:id', api.getPCA);
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
  console.log('Express server listening on port ' + app.get('port'));
});
