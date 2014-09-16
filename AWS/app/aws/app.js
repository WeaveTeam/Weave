'use strict';

var app = angular.module('aws', [//'aws.router', // for app structure (can be cleaned)
                                 //'aws.analysis', 
                                 
                                 'aws.configure', //Both script and metadata managers
                                 'aws.directives', // high level directives don't agree with current location

                                 'aws.queryObject', // queryService.. this needs to be reconciled                               
                                 'aws.queryObjectEditor', // Shweta's module
                                 'aws.project',  // shweta's module
                                 'aws.outputView',
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
	});
});


angular.module('aws.directives', ['aws.directives.dualListBox',
                                  'aws.directives.fileUpload']);
angular.module('aws.configure', ['aws.configure.metadata',
                                 'aws.configure.script']);

app.service('errorLogService',[function(){
	
	this.logs = "";
	/**
	 *this is the function that will be used over all tabs to log errors to the error log
	 *@param the string you want to log to the error log
	 */
	this.logInErrorLog = function(error){
		this.logs= this.logs.concat("\n" + error + new Date().toLocaleTimeString());
	};
	
}]);


// From Amith's UI
app.controller('AWSController', function($scope, $route, $location, errorLogService) {
	$scope.$route = $route;
	
	$scope.errorLogService = errorLogService;
	$scope.errorAside = {
		title : "Error Log"	
	};
	//errorLogService.logInErrorLog("Zooooooop");
});

//var navbar_ctrl = function($scope, $route, $location) {
//	$scope.$route = $route;
//};
