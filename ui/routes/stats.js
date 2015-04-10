var fs = require('fs');
var parser = require('./parsers.js');
var Q = require('q');

gc_percent = function(nucs) {
  var gc_count = 0;
  var nuc_count = 0;
  for(var gene_id in nucs) {
    var gene = nucs[gene_id];
    var nuc_chars = gene.split('\n')[1];
    nuc_count += nuc_chars.length;
    var matched_nucs = nuc_chars.match(/[GCgc]/g);
    if(matched_nucs) gc_count += matched_nucs.length;
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

exports.parse_fna = function(fna_filename) {
  var deferred = Q.defer();
  fs.readFile(fna_filename, parser.parse_genes_fna(function(nucs, err) {
    if(!err) {
      var funcs = [[gc_percent, 'gc_percent'], [num_bases, 'num_bases'], [num_contigs, 'num_contigs']];
      var result = {};
      funcs.map(function(func) {
        result[func[1]] = func[0](nucs);
      });

      deferred.resolve(result);
    } else {
      deferred.reject(err);
    }
  }));

  return deferred.promise;
};

