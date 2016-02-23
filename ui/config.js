var process = require('process');
var https = require('https');
var fs = require('fs');
var Q = require('q');
var ssh_client = require('node-sshclient');

var Production = function() {
  this.install_location = '/global/projectb/sandbox/omics/sc-decontamination/Production/prodege-2.0';
  this.nt_location = '';
  this.bundle_src = '/dna/shared/data/gbp/prodege/production/Releases/prodege-2.2.tgz';
  this.bundle_src_name = 'prodege-2.2.tgz';
  this.version = '2.0';

  //Overrides
  this.job_start = function(job_id, temp_config_filename, temp_fasta_filename, user_id) { return job_start(job_id, temp_config_filename, temp_fasta_filename, user_id, this.remote_working_dir); };
  this.job_status = function(job_id, process_id, user_id) { return job_status(job_id, process_id, user_id, this.local_working_dir); };
  this.remote_working_dir = '/global/projectb/scratch/ewanders/prodege/production';
  this.local_working_dir = '/dna/shared/data/gbp/prodege/production';
  this.env = 'production';
  this.port = 3051;
  this.caliban_return_URL = 'https://prodege.jgi.doe.gov/';
  this.caliban_signon_URL = 'https://signon2.jgi.doe.gov';
  this.caliban_signoff_URL = 'https://signon.jgi.doe.gov/signon/destroy';
  this.caliban_api_users = function(user_id, cb) { return https.get({hostname:'signon.jgi.doe.gov', path: '/api/users/'+user_id}, cb); };
  this.caliban_api_session = function(session, cb) { return https.get({hostname:'signon.jgi.doe.gov', path: session}, cb); };
  this.caliban_cookie_domain = '.jgi.doe.gov';
};

var Staging = function() {
  Production.call(this);

  this.remote_working_dir = '/global/projectb/scratch/ewanders/prodege/staging';
  this.local_working_dir = '/dna/shared/data/gbp/prodege/staging';
  this.env = 'staging';
  this.port = 3052;
  this.caliban_return_URL = 'http://prodege-dev.jgi.doe.gov/';
  this.job_start = function(job_id, temp_config_filename, temp_fasta_filename, user_id) { return job_start(job_id, temp_config_filename, temp_fasta_filename, user_id, this.remote_working_dir); };
  this.job_status = function(job_id, process_id, user_id) { return job_status(job_id, process_id, user_id, this.local_working_dir); };
  this.caliban_api_users = function(user_id, cb) { return https.get({hostname:'signon.jgi.doe.gov', port: 4444, path: '/api/users/'+user_id}, cb); };
  this.caliban_api_session = function(session, cb) { return https.get({hostname:'signon.jgi.doe.gov', port: 4444, path: session}, cb); };
};
Staging.prototype = Object.create(Production.prototype);
Staging.prototype.constructor = Staging;

function ssh_promise(command) {
  console.log('ssh gp '+command);
  var deferred = Q.defer();
  var ssh = new ssh_client.SSH({hostname: 'gp'});
  ssh.command(command, function(result) {
    if( result.exitCode === 0 ) {
      console.log('ssh success');
      deferred.resolve(result.stdout);
    } else {
      console.log('ssh fail');
      deferred.reject(result.stderr);
    }
  });
  return deferred.promise;
}

function scp_promise(src, dest) {
  console.log('scp '+src+' @gp:'+dest);
  var deferred = Q.defer();
  var scp = new ssh_client.SCP({hostname: 'gp'});
  scp.upload(src, dest, function(result) {
    if( result.exitCode === 0 ) {
      console.log('scp success');
      deferred.resolve(result.stdout);
    } else {
      console.log('scp fail');
      deferred.reject(result.stderr);
    }
  });
  return deferred.promise;
}

function qsub_promise(command) {
  var deferred = Q.defer();
  ssh_promise(command)
  .then(function(output) {
    var parsed = (new String(output)).match(/Your job ([0-9]+)/);
    if(parsed.length == 2) {
      var process_id = parseInt(parsed[1]);
      deferred.resolve(process_id);
    } else {
      deferred.reject('Failed to parse qsub job');
    }
  }, function(reason) {
    deferred.reject(reason);
  });

  return deferred.promise;
}

function job_status(jid, pid, user_id, working_dir) {
  var deferred = Q.defer();
  ssh_promise('/usr/common/usg/bin/qs -j '+pid+' --style json')
  .then(function(output) {
    var parsed_job_status = JSON.parse(new String(output).split('\n')[0]);
    if(parsed_job_status.length === 1) {
      var str_status = '';
      if(parsed_job_status[0].state.match(/qw/)) {
        str_status = 'Waiting in Queue';
      } else if(parsed_job_status[0].state.match(/r/)) {
        str_status = 'Running';
      } else if(parsed_job_status[0].state.match(/t/)) {
        str_status = 'Transfer';
      } else {
        str_status = 'Unknown';
      }
      if(parsed_job_status[0].state.match(/E/)) {
        str_status = str_status + ' (ERROR)';
      }
      /*if(parsed_job_status[0].state.match(/h/)) {
        str_status = str_status + ' (HOLD)';
      }*/
      if(parsed_job_status[0].state.match(/R/)) {
        str_status = str_status + ' (RESUBMITTED)';
      }
      deferred.resolve(str_status);
    } else {
      console.log('no current job');
      console.log('checking: '+working_dir+'/sso_'+user_id+'/job_'+jid);
      fs.exists(working_dir+'/sso_'+user_id+'/job_'+jid, function(exists) {
        if(exists) {
          console.log('exists');
          deferred.resolve('Complete');
        } else {
          console.log('not exists');
          deferred.resolve('Unknown');
        }
      });
    }
  }, function(reason) {
    deferred.reject(reason);
  });

  return deferred.promise;
}

function job_start(job_id, temp_config_filename, temp_fasta_filename, user_id, working_dir) {
  var deferred = Q.defer();
  var user_working_dir = working_dir+'/sso_'+user_id;
  var remote_config_filename = user_working_dir+'/job_'+job_id+'.cnf';
  var remote_fasta_filename = user_working_dir+'/job_'+job_id+'.fna';
  ssh_promise('mkdir -p '+user_working_dir)
  .then(function() {
    console.log('User dir exists: '+user_working_dir);
    Q.allSettled([
      scp_promise( temp_config_filename, remote_config_filename ),
      scp_promise( temp_fasta_filename, remote_fasta_filename )
      ]).spread(function(config, fasta) {
        console.log('scp successful');
        var cmd_line = 'qsub -N $JOBNAME -j y -V -o $LOGFILE -l exclusive.c -l h_rt=12:00:00 -pe pe_slots 8 /global/projectb/sandbox/omics/sc-decontamination/Production/prodege-2.0/bin/prodege.sh $CONF_FILE'
        .replace('$JOBNAME', 'SCD-job_'+job_id)
        .replace('$LOGFILE', user_working_dir+'/job_'+job_id+'-qsub.log')
        .replace('$CONF_FILE', remote_config_filename);
        qsub_promise(cmd_line)
        .then(function(jid) {
          console.log('compute job: ' + jid);
          qsub_promise('qsub -q xfer.q -hold_jid '+jid+' ~/rsync_prodege_data.sh ~/rsync_'+jid+'.log')
          .then(function(jid) { console.log('rsync job: '+jid); deferred.resolve(jid); }, function(reason) { deferred.reject(reason); });
        },
        function(reason) {
          deferred.reject(reason);
        });
      }, function(scp_rejection) {
        console.log(scp_rejection);
      });
  }, function(reason) {
    console.log('User mkdir failed: '+user_working_dir);
    console.log(reason);
  });

  return deferred.promise;
}

exports.Config = global.process.env.NODE_ENV === 'production' ? new Production() : new Staging();

