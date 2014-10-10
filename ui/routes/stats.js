var fs = require('fs');
var parser = require('./parsers.js');

gc_percent = function(nucs) {
  var gc_count = 0;
  var nuc_count = 0;
  for(var gene_id in nucs) {
    var gene = nucs[gene_id];
    var nuc_chars = gene.split('\n')[1];
    nuc_count += nuc_chars.length;
    gc_count += nuc_chars.match(/[GCgc]/g).length;
  }
  return (100.0 * gc_count) / nuc_count;
};

num_bases = function(nucs) {
  var nuc_count = 0;
  for(var gene_id in nucs) {
    var gene = nucs[gene_id];
    nuc_count += gene.split('\n')[1].length;
  }
  return nuc_count;
};

num_contigs = function(nucs) {
  return Object.keys(nucs).length;
};

exports.parse_fna = function(fna_filename, cb_ok, cb_err) {
  fs.readFile(fna_filename, parser.parse_genes_fna(function(nucs, err) {
    if(!err) {
      var funcs = [[gc_percent, 'gc_percent'], [num_bases, 'num_bases'], [num_contigs, 'num_contigs']];
      var result = {};
      funcs.map(function(func) {
        result[func[1]] = func[0](nucs);
      });

      cb_ok(result);
    } else {
      cb_err(err);
    }
  }));
};

