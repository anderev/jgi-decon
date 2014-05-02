var data = {
  "jobs": [
    {
      "title": "My Single Cell Project",
      "text": "CGTGTTGAGAGAGTGTGGCGCGCAGAGTGA"
    },
    {
      "title": "My 2nd Single Cell Project",
      "text": "CGTGTTGAAAAAGAGAGTGTGGCGCGCAGAGTGA"
    }
  ]
};

// GET

exports.jobs = function(req, res) {
  var jobs = [];
  data.jobs.forEach(function(job, i) {
    jobs.push({
      id: i,
      title: job.title,
      text: job.text.substr(0,50) + '...'
    });
  });
  res.json({
    jobs: jobs
  });
};

exports.job = function(req, res) {
  var id = req.params.id;
  if (id >= 0 && id < data.jobs.length) {
    res.json({
      job: data.jobs[id]
    });
  } else {
    res.json(false);
  }
};

// POST
exports.addJob = function(req, res) {
  data.jobs.push(req.body);
  res.json(req.body);
};

// DELETE
exports.deleteJob = function(req, res) {
  var id = req.params.id;

  if( id >= 0 && id < data.jobs.length) {
    data.jobs.splice(id, 1);
    res.json(true);
  } else {
    res.json(false);
  }
};

