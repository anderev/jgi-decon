var staging = {
  install_location: '/global/projectb/sandbox/omics/sc-decontamination/Production/scd-1.3.4',
  nt_location: '',
  working_dir: '/global/homes/e/ewanders/dev/scd-viz/working_dirs',
  scd_exe: 'qsub -N JOBNAME -j y -V -o LOGFILE -l exclusive.c -l h_rt=12:00:00 -pe pe_slots 8 /global/projectb/sandbox/omics/sc-decontamination/Production/scd-1.3.4/bin/scd.sh',
  env: global.process.env.NODE_ENV || 'staging',
  port: 8091
};

  
var production = {
  install_location: '/global/projectb/sandbox/omics/sc-decontamination/Production/scd-1.3.4',
  nt_location: '',
  working_dir: '/global/homes/e/ewanders/prod/scd-viz/working_dirs',
  scd_exe: 'qsub -N JOBNAME -j y -V -o LOGFILE -l exclusive.c -l h_rt=12:00:00 -pe pe_slots 8 /global/projectb/sandbox/omics/sc-decontamination/Production/scd-1.3.4/bin/scd.sh',
  env: global.process.env.NODE_ENV || 'production',
  port: 3051
};

exports.Config = global.process.env.NODE_ENV === 'production' ? production : staging;

