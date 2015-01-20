var process = require('process');
var https = require('https');
var http = require('http');

var Production = function() {
  this.install_location = '/global/projectb/sandbox/omics/sc-decontamination/Production/scd-1.3.4';
  this.nt_location = '';
  this.scd_exe = 'qsub -N JOBNAME -j y -V -o LOGFILE -l exclusive.c -l h_rt=12:00:00 -pe pe_slots 8 /global/projectb/sandbox/omics/sc-decontamination/Production/scd-1.3.4/bin/scd.sh';
  this.bundle_src = '/global/projectb/sandbox/omics/sc-decontamination/Releases/scd-1.3.4.tgz';
  this.bundle_src_name = 'prodege-1.3.4.tgz';

  //Overrides
  this.working_dir = '/global/homes/g/gbp/ProDeGe/working_dirs';
  this.env = 'production';
  this.port = 3051;
  this.caliban_return_URL = 'http://prodege.jgi-psf.org/';
  this.caliban_signon_URL = 'https://signon2.jgi-psf.org';
  this.caliban_signoff_URL = 'https://signon.jgi-psf.org/signon/destroy';
  this.caliban_api_users = function(user_id, cb) { return https.get({hostname:'signon.jgi-psf.org', path: '/api/users/'+user_id}, cb); };
  this.caliban_api_session = function(session, cb) { return https.get({hostname:'signon.jgi-psf.org', path: session}, cb); };
  this.caliban_cookie_domain = '.jgi-psf.org';
};

var Staging = function() {
  Production.call(this);

  this.working_dir = process.cwd()+'/working_dirs';
  this.env = 'staging';
  this.port = 80;
  this.caliban_return_URL = 'http://staging.localdomain/';
  this.caliban_signon_URL = 'http://staging.localdomain/caliban/signon';
  this.caliban_signoff_URL = 'http://staging.localdomain/caliban/signoff';
  this.caliban_api_users = function(user_id, cb) { return http.get({hostname:'staging.localdomain', path: '/caliban/api/users/'+user_id}, cb); };
  this.caliban_api_session = function(session, cb) { return http.get({hostname:'staging.localdomain', path: '/caliban'+session}, cb); };
  this.caliban_cookie_domain = 'staging.localdomain';
};
Staging.prototype = Object.create(Production.prototype);
Staging.prototype.constructor = Staging;

exports.Config = global.process.env.NODE_ENV === 'production' ? new Production() : new Staging();
