exports.parse_pca = function(contigs, callback) {
  return function(err, data) {

    if(!err) {
      var lines = data.toString().split('\n');
      var num_lines = lines.length;
      for(var i=0; i<num_lines; ++i) {
        var line = lines[i].split('\t');
        var point = {};
        point.x = line[0];
        point.y = line[1];
        point.z = line[2];
        contigs.push(point);
      }

      callback(null);
    } else {
      console.log('Error parsing pca file.');
      callback(err);
    }
  }
};

exports.parse_names = function(contigs, callback) {
  return function(err, data) {

    if(!err) {
      var lines = data.toString().split('\n');
      var num_lines = lines.length;
      for(var i=0; i<num_lines; ++i) {
        contigs[i].name = lines[i];
      }

      callback(null);
    } else {
      console.log('Error parsing names file.');
      callback(err);
    }
  }
};

exports.parse_lca = function(contigs, callback) {
  return function(err, data) {

    if(!err) {

      var lines = data.toString().split('\n');
      var num_lines = lines.length;
      var contig_taxonomy = {};
      for(var i=0; i<num_lines; ++i) {
        var tokens = lines[i].split('\t');
        var cleaned_taxon = (tokens[1] || '').trim().replace('root;cellular organisms;', '');
        if(cleaned_taxon.length > 0) {
          contig_taxonomy[tokens[0]] = cleaned_taxon;
        }
      }

      for(var j=0; j<contigs.length; j++) {
        if(contigs[j].name in contig_taxonomy) {
          contigs[j].taxonomy = (contig_taxonomy[contigs[j].name]);
        } else {
          contigs[j].taxonomy = 'Unknown';
        }
      }

      callback(null);
    } else {
      console.log('Error parsing LCA file.');
      callback(err);
    }
  }
};

exports.parse_blout = function(contigs, callback) {

  var parseBloutLine = function(blout) {
    return {
      gene_id: blout[0],
      subject_id: blout[1],
      percent_identity: blout[2],
      strand: null,
      query_len: blout[4],
      subject_len: blout[5],
      query_start: blout[8],
      query_end: blout[9],
      subject_start: blout[10],
      subject_end: blout[11],
      e_value: blout[12],
      bit_score: blout[13],
      subject_genome: blout[14],
      coverage: 100.0*Math.abs(parseFloat(blout[9])-parseFloat(blout[8])) / parseFloat(blout[4])
    };
  };

  return function(err, data) {

    if(!err) {
      var contig_map = {};
      for(var i=0; i<contigs.length; i++) {
        contig_map[contigs[i].name] = i;
      }

      var lines = data.toString().split('\n');
      var num_lines = lines.length;
      for(var i=0; i<num_lines; i++) {
        var columns = lines[i].split('\t');
        var gene_name = columns[0].split('_');
        var contig_name = gene_name.slice(0, gene_name.length - 2).join('_');
        if(contig_name in contig_map) {
          var contig = contigs[contig_map[contig_name]];
          if(contig) {
            if('genes' in contig) {
              contig.genes[contig.genes.length] = parseBloutLine(columns);
            } else {
              contig.genes = [parseBloutLine(columns)];
            }
          }
        }
      }

      callback(null);
    } else {
      console.log('Error parsing blout file.');
      callback(err);
    }
  }
};

exports.parse_genes_fna = function(callback) {
  return function(err, data) {

    if(!err) {
      var nuc_seqs = {};
      var lines = data.toString().split('\n');
      var num_lines = lines.length;
      var i = 0;
      while(i<num_lines) {
        if(lines[i].charAt(0) === '>') {
          var nuc_seq = lines[i]+'\n';
          var j = 1;
          while(i+j < num_lines && lines[i+j].charAt(0) !== '>') {
            nuc_seq = nuc_seq.concat(lines[i+j]);
            ++j;
          }

          var gene_cols = lines[i].split(' ');
          var gene_name = gene_cols[0].substr(1);
          nuc_seqs[gene_name] = nuc_seq;
          
          i += j;
        } else {
          ++i;
        }
      }

      callback(nuc_seqs, null);
    } else {
      console.log('Error parsing names file.');
      callback(null, err);
    }
  }
};
