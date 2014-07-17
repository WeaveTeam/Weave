'use strict';

var app = angular.module('aws', [//'aws.router', // for app structure (can be cleaned)
                                 //'aws.analysis', 
                                 
                                 'aws.configure', //Both script and metadata managers
                                 'aws.directives', // high level directives don't agree with current location

                                 'aws.queryObject', // queryService.. this needs to be reconciled                               
                                 'aws.queryObjectEditor', // Shweta's module
                                 'aws.project',  // shweta's module
                                 'aws.outputView',
                                 'aws.bioWeave',
                                 'ngAnimate', // Angular Library
                                 'ngSanitize',
                                 'mgcrea.ngStrap',
                                 //'aws.visualization', 
                                 'ui.select2',
                                 //'ui.slider',
                                 
                                 'ui.sortable', // Shweta Needs, comes from angular-strap???
                                 'ngRoute',
                                 'ngGrid', // Angular UI library
                                 'mk.editablespan', // Directive for editing values. 
                                 'aws.analysisService', 
                                 'aws.AnalysisModule'
                               ]); 

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
		controller : 'MetadataCtrl',
		activetab : 'metadata'
	}).when('/script_management', {
		templateUrl : 'aws/configure/script/scriptManager.html',
		controller : 'ScriptManagerCtrl',
		activetab : 'script_management'
	}).when('/project_management', {
		templateUrl : 'aws/project/projectManagementPanel.html',
		controller : 'ProjectManagementCtrl',
		activetab : 'project_management'
	}).when('/output_view', {
		templateUrl : 'aws/outputView/outputViewManagementPanel.html',
		controller : 'OutputViewManagementController',
		activetab : 'output_view'
	}).when('/BioWeave_management', {
		templateUrl : 'aws/bioWeave/BioWeaveManager.html',
		controller : 'BioWeaveController',
		activetab : 'BioWeave_management'
	});
});


angular.module('aws.directives', ['aws.directives.dualListBox',
                                  'aws.directives.fileUpload']);
angular.module('aws.configure', ['aws.configure.metadata',
                                 'aws.configure.script']);

// From Amith's UI
app.controller('AWSController', function($scope, $route, $location) {
	
	$scope.$route = $route;
	
});
//var navbar_ctrl = function($scope, $route, $location) {
//	$scope.$route = $route;
//};
