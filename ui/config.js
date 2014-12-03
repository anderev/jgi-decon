var common = {
  install_location: '/global/projectb/sandbox/omics/sc-decontamination/Production/scd-1.3.4',
  nt_location: '',
  //working_dir: '/global/homes/e/ewanders/dev/scd-viz/working_dirs',
  scd_exe: 'qsub -N JOBNAME -j y -V -o LOGFILE -l exclusive.c -l h_rt=12:00:00 -pe pe_slots 8 /global/projectb/sandbox/omics/sc-decontamination/Production/scd-1.3.4/bin/scd.sh',
  //env: 'staging',
  //port: 8091,
  //caliban_return_URL: 'http://prodege.jgi-psf.org:8091/',
  caliban_signon_URL: 'https://signon2.jgi-psf.org',
  bundle_src: '/global/projectb/sandbox/omics/sc-decontamination/Releases/scd-1.3.4.tgz',
  bundle_src_name: 'prodege-1.3.4.tgz'
};

var staging = {
  install_location: common.install_location,
  nt_location: common.nt_location,
  working_dir: '/global/homes/e/ewanders/dev/scd-viz/working_dirs',
  scd_exe: common.scd_exe,
  env: 'staging',
  port: 8091,
  caliban_return_URL: 'http://prodege.jgi-psf.org:8091/',
  caliban_signon_URL: common.caliban_signon_URL,
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
  bundle_src: common.bundle_src,
  bundle_src_name: common.bundle_src_name
};

exports.Config = global.process.env.NODE_ENV === 'production' ? production : staging;
