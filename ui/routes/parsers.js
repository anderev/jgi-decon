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
        contig_phylogeny[tokens[0]] = tokens[1];
      }

      for(var j=0; j<pointData.length; j++) {
        pointData[j].phylogeny = (contig_phylogeny[pointData[j].name] || 'Unknown').trim().replace('root;cellular organisms;', '');
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
      query_len: null,
      subject_len: null,
      query_start: blout[6],
      query_end: blout[7],
      subject_start: blout[8],
      subject_end: blout[9],
      e_value: blout[10],
      bit_score: blout[11],
      subject_genome: blout[12]
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
      console.log('Error parsing names file.');
      callback(err);
    }
  }
};

