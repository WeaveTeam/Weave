var weaveAWSApp = angular.module('aws', [
										 'ngSanitize',
										 'mgcrea.ngStrap', 
										 'ngRoute',
										 'ui.select2',
										 'aws.services',
										 'aws.analysisService',
										 'aws.AnalysisModule'
										 ]);

weaveAWSApp.controller('AWSController', function($scope, $route, $location) {
	
	$scope.$route = $route;
	
});

var navbar_ctrl = function($scope, $route, $location) {
	$scope.$route = $route;
};

weaveAWSApp.config(function($routeProvider) {
	
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

