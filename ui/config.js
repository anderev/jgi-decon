var process = require('process');
var https = require('https');
var http = require('http');

var common = {
  install_location: '/global/projectb/sandbox/omics/sc-decontamination/Production/scd-1.3.4',
  nt_location: '',
  scd_exe: 'qsub -N JOBNAME -j y -V -o LOGFILE -l exclusive.c -l h_rt=12:00:00 -pe pe_slots 8 /global/projectb/sandbox/omics/sc-decontamination/Production/scd-1.3.4/bin/scd.sh',
  caliban_signon_URL: 'https://signon2.jgi-psf.org',
  caliban_api_users: function(user_id, cb) { https.get({hostname:'signon.jgi-psf.org', path: '/api/users/'+user_id}, cb) },
  caliban_api_session: function(session, cb) { https.get({hostname:'signon.jgi-psf.org', path: session}, cb) },
  caliban_cookie_domain: '.jgi-psf.org',
  bundle_src: '/global/projectb/sandbox/omics/sc-decontamination/Releases/scd-1.3.4.tgz',
  bundle_src_name: 'prodege-1.3.4.tgz'
};

var staging = {
  install_location: common.install_location,
  nt_location: common.nt_location,
  working_dir: process.cwd()+'/working_dirs',
  scd_exe: common.scd_exe,
  env: 'staging',
  port: 80,
  caliban_return_URL: 'http://staging.localdomain/',
  caliban_signon_URL: 'http://staging.localdomain/caliban/signon',
  caliban_signoff_URL: 'http://staging.localdomain/caliban/signoff',
  caliban_api_users: function(user_id, cb) { return http.get({hostname:'staging.localdomain', path: '/caliban/api/users/'+user_id}, cb); },
  caliban_api_session: function(session, cb) { return http.get({hostname:'staging.localdomain', path: '/caliban'+session}, cb); },
  caliban_cookie_domain: 'staging.localdomain',
  bundle_src: common.bundle_src,
  bundle_src_name: common.bundle_src_name
};

var production = {
  install_location: common.install_location,
  nt_location: common.nt_location,
  working_dir: '/global/homes/g/gbp/ProDeGe/working_dirs',
  scd_exe: common.scd_exe,
  env: 'production',
  port: 3051,
  caliban_return_URL: 'http://prodege.jgi-psf.org/',
  caliban_signon_URL: common.caliban_signon_URL,
  caliban_signoff_URL: 'https://signon.jgi-psf.org/signon/destroy',
  caliban_api_users: function(user_id, cb) { return https.get({hostname:'signon.jgi-psf.org', path: '/api/users/'+user_id}, cb); },
  caliban_api_session: function(session, cb) { return https.get({hostname:'signon.jgi-psf.org', path: session}, cb); },
  caliban_cookie_domain: '.jgi-psf.org',
  bundle_src: common.bundle_src,
  bundle_src_name: common.bundle_src_name
};

exports.Config = global.process.env.NODE_ENV === 'production' ? production : staging;
