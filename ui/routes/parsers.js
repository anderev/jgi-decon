exports.parse_pca = function(pointData, callback) {
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
        pointData.push(point);
      }

      callback(null);
    } else {
      console.log('Error parsing pca file.');
      callback(err);
    }
  }
};

exports.parse_names = function(pointData, callback) {
  return function(err, data) {

    if(!err) {
      var lines = data.toString().split('\n');
      var num_lines = lines.length;
      for(var i=0; i<num_lines; ++i) {
        pointData[i].name = lines[i];
      }

      callback(null);
    } else {
      console.log('Error parsing names file.');
      callback(err);
    }
  }
};

exports.parse_lca = function(pointData, callback) {
  return function(err, data) {

    if(!err) {

      var lines = data.toString().split('\n');
      var num_lines = lines.length;
      var contig_phylogeny = {};
      for(var i=0; i<num_lines; ++i) {
        var tokens = lines[i].split('\t');
        if(tokens[1] && tokens[1].trim().length > 0) {
          contig_phylogeny[tokens[0]] = tokens[1].trim().replace('root;cellular organisms;', '');
        }
      }

      for(var j=0; j<pointData.length; j++) {
        if(pointData[j].name in contig_phylogeny) {
          pointData[j].phylogeny = (contig_phylogeny[pointData[j].name]);
        } else {
          pointData[j].phylogeny = 'Unknown';
        }
      }

      callback(null);
    } else {
      console.log('Error parsing LCA file.');
      callback(err);
    }
  }
};

exports.parse_blout = function(pointData, callback) {

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
      for(var i=0; i<pointData.length; i++) {
        contig_map[pointData[i].name] = i;
      }

      var lines = data.toString().split('\n');
      var num_lines = lines.length;
      for(var i=0; i<num_lines; i++) {
        var columns = lines[i].split('\t');
        var gene_name = columns[0].split('_');
        var contig_name = gene_name.slice(0, gene_name.length - 2).join('_');
        if(contig_name in contig_map) {
          var contig = pointData[contig_map[contig_name]];
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

exports.parse_genes_fna = function(pointData, callback) {
  return function(err, data) {

    if(!err) {
      var contig_map = {};
      for(var i=0; i<pointData.length; i++) {
        var gene_map = {};
        var genes = pointData[i].genes;
        if(genes) {
          for(var j=0; j<genes.length; ++j) {
            gene_map[genes[j].gene_id] = j;
          }
          contig_map[pointData[i].name] = {i: i, gene_map: gene_map};
        }
      }

      var lines = data.toString().split('\n');
      var num_lines = lines.length;
      var i = 0;
      while(i<num_lines) {
        if(lines[i].charAt(0) === '>') {
          var nuc_seq = '';
          var j = 1;
          while(i+j < num_lines && lines[i+j].charAt(0) !== '>') {
            nuc_seq = nuc_seq.concat(lines[i+j]);
            ++j;
          }
          var gene_cols = lines[i].split(' ');
          var gene_name = gene_cols[0].substr(1);
          var gene_strand = gene_cols[6];
          var gene_name_split = gene_name.split('_');
          var contig_name = gene_name_split.slice(0, gene_name_split.length - 2).join('_');
          if(contig_name in contig_map) {
            var contig = pointData[contig_map[contig_name].i];
            var gene_map = contig_map[contig_name].gene_map;
            if(contig) {
              if('genes' in contig) {
                var gene = contig.genes[gene_map[gene_name]];
                if(gene) {
                  gene.nuc_seq = nuc_seq;
                  gene.strand = gene_strand;
                  gene.gc = (100.0 * nuc_seq.match(/[GCgc]/g).length) / nuc_seq.length;
                }
              }
            }
          }
          
          i += j;
        } else {
          ++i;
        }
      }

      callback(null);
    } else {
      console.log('Error parsing names file.');
      callback(err);
    }
  }
};
