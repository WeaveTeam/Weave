'use strict';

var app = angular.module('aws', ['aws.router',
                                 'aws.analysis', 
                                 'aws.analysisService',
                                 'aws.configure',
                                 'aws.directives', 
                                 'aws.queryObject',
                                 'aws.queryObjectEditor',
                                 'aws.project', 
                                 'ngAnimate',
                                 'ngSanitize',
                                 'mgcrea.ngStrap',
                                 'aws.visualization',
                                 'ui.select2',
                                 'ui.slider',
                                 'ui.sortable',
                                 'ngRoute',
                                 'ngGrid']); // from Amith's UI

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
		templateUrl : 'aws/configure/metadata/metadataManager.html',
		controller : 'MetadataManagerCtrl',
		activetab : 'metadata'
	}).when('/script_management', {
		templateUrl : 'aws/configure/script/scriptManager.html',
		controller : 'ScriptManagerCtrl',
		activetab : 'script_management'
	}).when('/project_management', {
		templateUrl : 'aws/project/projectManagementPanel.html',
		controller : 'LayoutCtrl',
		activetab : 'project_management'
	}).when('/old_analysis', {
		templateUrl : 'aws/analysis/oldAnalysis.html',
		controller : 'LayoutCtrl',
		activetab : 'old_analysis'
	});
});

angular.module('aws.analysis', ['aws.analysis.geography',
								'aws.analysis.indicator',
								'aws.analysis.timeperiod']);
angular.module('aws.directives', ['aws.directives.dualListBox',
                                  'aws.directives.fileUpload',
                                  'aws.directives.panel']);
angular.module('aws.configure', ['aws.configure.metadata',
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
