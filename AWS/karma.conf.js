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
      'app/lib/jquery/matchers.js',
      //'app/lib/jquery/jasmine-jquery.js',
      'app/lib/jquery/jquery-ui.js',
      'app/lib/angular/angular.js',
      'app/lib/angular/angular-mocks.js',
      'app/lib/angular/ui-bootstrap-0.5.0.js',
      'app/lib/angular/angular-ui-select2.js',
      'app/lib/angular/slider.js',
      // 'app/js/app.js',
      // 'app/js/directives/directives.js',
      // 'app/js/controllers/controllers.js',
      'app/js/*.js',
      'app/js/**/*.js',
      'spec/*.js'
    ],


    // list of files to exclude
    exclude: [
      
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
