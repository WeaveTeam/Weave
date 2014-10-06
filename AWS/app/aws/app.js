'use strict';

var app = angular.module('aws', [//'aws.router', // for app structure (can be cleaned)
                                 //'aws.analysis', 
                                 'ngAnimate', // Angular Library
                                 'ngSanitize',
                                 'mgcrea.ngStrap',
                                 //'aws.visualization', 
                                 'ui.select2',
                                 //'ui.slider',
                                 'ui.bootstrap',
                                 'ui.sortable', // Shweta Needs, comes from angular-strap???
                                 'ngRoute',
                                 'ngGrid', // Angular UI library
                                 'mk.editablespan', // Directive for editing values.
                                 'aws.configure', //Both script and metadata managers
                                 'aws.directives', // high level directives don't agree with current location
                                 'aws.queryObject', // queryService.. this needs to be reconciled                               
                                 'aws.queryObjectEditor', // Shweta's module
                                 'aws.project',  // shweta's module
                                 'aws.errorLog',
                                 'aws.AnalysisModule',
                                 'aws.WeaveModule',
                                 'aws.QueryHandlerModule'
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
		controller : 'AnalysisCtrl',
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
		controller : 'ProjectManagementCtrl',
		activetab : 'project_management'
	}).otherwise({
        redirectTo: '/analysis'
    });

});


angular.module('aws.directives', ['aws.directives.dualListBox',
                                  'aws.directives.fileUpload']);
angular.module('aws.configure', ['aws.configure.auth',
                                 'aws.configure.metadata',
                                 'aws.configure.script']);

//using the value provider recipe 
app.value("dataServiceURL", '/WeaveServices/DataService');
app.value('adminServiceURL', '/WeaveServices/AdminService');
app.value('projectManagementURL', '/WeaveAnalystServices/ProjectManagementServlet');
app.value('scriptManagementURL', '/WeaveAnalystServices/ScriptManagementServlet');
app.value('computationServiceURL', '/WeaveAnalystServices/ComputationalServlet');

// From Amith's UI
app.controller('AWSController', function($scope, $route, $location, authenticationService) {
	$scope.$route = $route;
	$scope.authenticationService = authenticationService;

});



//var navbar_ctrl = function($scope, $route, $location) {
//	$scope.$route = $route;
//};
