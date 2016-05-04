const execSync = require('child_process').execSync;
process.env.FLEX_HOME="";
var command = process.env.FLEXJS_HOME + '/js/bin/mxmlc -remove-circulars -js-compiler-option="--compilation_level WHITESPACE_ONLY" -fb "' + __dirname + '"';
console.log(command);
execSync(command, {stdio: "inherit"});
