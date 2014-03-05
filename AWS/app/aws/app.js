'use strict';

var app = angular.module('aws', ['aws.router',
                                 'aws.analysis', 
                                 'aws.configure',
                                 'aws.directives', 
                                 'aws.project', 
                                 'aws.queryObject',
                                 'aws.visualization',
                                 'ui.bootstrap', // don't need?
                                 'ui.select2',
                                 'ui.slider',
                                 'ui.sortable',
                                 'ngRoute']); // from Amith's UI

app.run(['$rootScope', function($rootScope){
	$rootScope.$safeApply = function(fn, $scope) {
			if($scope == undefined){
				$scope = $rootScope;
			}
			
			fn = fn || function() {};
			if ( !$scope.$$phase ) {
        	$scope.$apply( fn );
    	}
    	else {
        	fn();
    	}
	};
}])
.config(function($parseProvider, $routeProvider){
	$parseProvider.unwrapPromises(true);
	
	// Also from Amith's UI
	$routeProvider.when('/analysis', {
		templateUrl : 'aws/analysis/analysis.tpl.html',
		controller : 'WidgetsController',
		activetab : 'analysis'
	}).when('/metadata', {
		templateUrl : 'aws/metadata/metadata.tpl.html',
		controller : 'WidgetsController',
		activetab : 'metadata'
	}).when('/script_management', {
		templateUrl : 'aws/scripts/script.tpl.html',
		controller : 'WidgetsController',
		activetab : 'script_management'
	}).when('/project_management', {
		templateUrl : 'aws/projects/project_management.tpl.html',
		controller : 'WidgetsController',
		activetab : 'project_management'
	});
});

angular.module('aws.analysis', ['aws.analysis.geography',
								'aws.analysis.indicator',
								'aws.analysis.timeperiod']);
angular.module('aws.directives', ['aws.directives.dualListBox',
                                  'aws.directives.fileUpload',
                                  'aws.directives.panel']);
angular.module('aws.configure', ['aws.configure.metadata',
                                 //'aws.configure.auth', 
                                 'aws.configure.script']);
angular.module('aws.visualization',['aws.visualization.tools',
                                    /*'aws.visualization.weave'*/]);

// From Amith's UI
app.controller('AWSController', function($scope, $route, $location) {
	
	$scope.$route = $route;
	
});
var navbar_ctrl = function($scope, $route, $location) {
	$scope.$route = $route;
};
