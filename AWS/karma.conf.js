// Karma configuration
// Generated on Tue Jan 28 2014 16:58:50 GMT-0500 (Eastern Standard Time)

module.exports = function(config) {
  config.set({

    // base path, that will be used to resolve files and exclude
    basePath: '',


    // frameworks to use
    frameworks: ['jasmine'],


    // list of files / patterns to load in the browser
    files: [
      'app/lib/jquery/jquery.js',
      //'app/lib/jasmine/matchers.js',
      //'app/lib/jasmine/jasmine-jquery.js',
      //'app/lib/jquery/jquery-ui.js',
      'app/lib/angular/1.2/angular.js',
      'app/lib/angular/1.2/angular-mocks.js',
      //'app/lib/**/*.js',
      'app/lib/ng-grid/*.js',
      'app/lib/editablespan/*.js',
      'app/aws/configure/script/ScriptManagerCtrl.js',
      'app/aws/configure/script/scriptManagerService.js',
      'build/aws.js',
      //'app/aws/app.js',
      'spec/scriptManagement_spec.js'
    ],


    // list of files to exclude
    exclude: [

        'app/lib/jasmine/jasmine-jquery.js'
    ],


    // test results reporter to use
    // possible values: 'dots', 'progress', 'junit', 'growl', 'coverage'
    reporters: ['progress'],


    // web server port
    port: 9876,


    // enable / disable colors in the output (reporters and logs)
    colors: true,


    // level of logging
    // possible values: config.LOG_DISABLE || config.LOG_ERROR || config.LOG_WARN || config.LOG_INFO || config.LOG_DEBUG
    logLevel: config.LOG_INFO,


    // enable / disable watching file and executing tests whenever any file changes
    autoWatch: true,


    // Start these browsers, currently available:
    // - Chrome
    // - ChromeCanary
    // - Firefox
    // - Opera
    // - Safari (only Mac)
    // - PhantomJS
    // - IE (only Windows)
    browsers: ['Chrome'], //, 'Firefox', 'IE'],


    // If browser does not capture in given timeout [ms], kill it
    captureTimeout: 60000,


    // Continuous Integration mode
    // if true, it capture browsers, run tests and exit
    singleRun: false
  });
};
