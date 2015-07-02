# JGI Decontamination

### Running the app

Runs like a typical express app, run from the ui folder:

#### Staging/Development
    % node app.js

#### Production
    % NODE_ENV=production bash -c 'forever -a -l forever.txt -o log.txt -e error.txt app.js'