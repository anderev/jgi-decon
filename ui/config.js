var staging = {
  install_location: '/global/homes/e/ewanders/scd-1.3.2',
  nt_location: '/global/dna/shared/rqc/ref_databases/ncbi/CURRENT/nt/nt',
  working_dir: '/global/homes/e/ewanders/dev/scd-viz/working_dirs',
  scd_exe: 'qsub -N JOBNAME -j y -R y -V -o LOGFILE -l h_rt=12:00:00 -l ram.c=48G -pe pe_slots 8 /global/homes/e/ewanders/scd-1.3.2/bin/scd.sh',
  env: global.process.env.NODE_ENV || 'staging',
  port: 8091
};

  
var production = {
  install_location: '/global/homes/e/ewanders/scd-1.3.2',
  nt_location: '/global/dna/shared/rqc/ref_databases/ncbi/CURRENT/nt/nt',
  working_dir: '/global/homes/e/ewanders/prod/scd-viz/working_dirs',
  scd_exe: 'qsub -N JOBNAME -j y -R y -V -o LOGFILE -l h_rt=12:00:00 -l ram.c=48G -pe pe_slots 8 /global/homes/e/ewanders/scd-1.3.2/bin/scd.sh',
  env: global.process.env.NODE_ENV || 'production',
  port: 3051
};

exports.Config = global.process.env.NODE_ENV === 'production' ? production : staging;

