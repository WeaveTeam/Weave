'use strict';

var app = angular.module('aws', [//'aws.router', // for app structure (can be cleaned)
                                 //'aws.analysis', 
                                 'ngAnimate', // Angular Library
                                 'ngSanitize',
                                 'mgcrea.ngStrap',
                                 'ui.select2',
                                 'ui.select2.sortable',
                                 //'ui.slider',
                                 'ui.bootstrap',
                                 'ui.sortable', // Shweta Needs, comes from angular-strap???
                                 //'ngRoute',
                                 'ngGrid', // Angular UI library
                                 'ui.router',
                                 'mk.editablespan', // Directive for editing values.
                                 'aws.configure', //Both script and metadata managers
                                 'aws.dataStatistics',
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
.config(function($stateProvider, $urlRouterProvider, $parseProvider) {
	
	$parseProvider.unwrapPromises(true);
	
	$urlRouterProvider.otherwise("/index.html");
	
	$stateProvider
		.state('metadata', {
			url:'/metadata',
			templateUrl : 'src/configure/metadata/metadataManager.html',
			controller: 'MetadataManagerCtrl',
			data : {
				activetab : 'metadata'
			}
		})
	    .state('script_management', {
	    	url:'/scripts',
	    	templateUrl : 'src/configure/script/scriptManager.html',
	    	controller : 'ScriptManagerCtrl',
	    	data:{
	    		activetab : 'script_management'
	    	}
	    })
	    .state('analysis', {
	    	url:'/analysis',
	    	templateUrl : 'src/analysis/analysis.tpl.html',
	    	controller: 'AnalysisCtrl',
	    	data : {
	    		activetab : 'analysis'
	    	}
	    })
	    .state('project', {
	    	url:'/projects',
	    	templateUrl : 'src/project/projectManagementPanel.html',
	    	controller : 'ProjectManagementCtrl',
	    	data: {
	    		activetab : 'project'
	    	}
	    })
	    .state('data_stats',{
	    	url:'/dataStatistics',
	    	templateUrl : 'src/dataStatistics/dataStatisticsMain.tpl.html',
    		controller : 'dataStatsCtrl',
    		data :{
    			activetab : 'data_stats'
    		}
	    })
	    .state('data_stats.summary_stats',{
	    	url:'/summary_stats',
	    	templateUrl: 'src/dataStatistics/summary_stats.tpl.html',
	    	data :{
    			activetab : 'summary_stats'
    		}
	    })
	    .state('data_stats.correlations', {
	    	url:'/correlations',
	    	templateUrl : 'src/dataStatistics/correlation_matrices.tpl.html',
	    	data :{
    			activetab : 'correlations'
    		}
	    })
	    .state('data_stats.regression', {
	    	url:'/regression',
	    	templateUrl :'src/dataStatistics/regression_analysis.tpl.html',
	    	data:{
	    		activetab: 'regression'
	    	}
	    });
		
	    
});

/**********************Using ng-route***************************************/
//.config(function($parseProvider, $routeProvider){
//	$parseProvider.unwrapPromises(true);
//	
//	$routeProvider.when('/analysis', {
//		templateUrl : 'src/analysis/analysis.tpl.html',
//		controller : 'AnalysisCtrl',
//		activetab : 'analysis'
//	}).when('/metadata', {
//		templateUrl : 'src/configure/metadata/metadataManager.html',
//		controller : 'MetadataManagerCtrl',
//		activetab : 'metadata'
//	}).when('/script_management', {
//		templateUrl : 'src/configure/script/scriptManager.html',
//		controller : 'ScriptManagerCtrl',
//		activetab : 'script_management'
//	}).when('/project_management', {
//		templateUrl : 'src/project/projectManagementPanel.html',
//		controller : 'ProjectManagementCtrl',
//		activetab : 'project_management'
//	}).when('/data_stats', {
//		templateUrl : 'src/dataStatistics/dataStatisticsMain.tpl.html',
//		controller : 'dataStatsCtrl',
//		activetab : 'data_stats'
//	}).otherwise({
//        redirectTo: '/analysis'
//    });
//
//});
/**********************Using ng-route***************************************/

angular.module('aws.directives', ['aws.directives.dualListBox',
                                  'aws.directives.fileUpload',
                                  'aws.directives.popover-with-tpl']);
angular.module('aws.configure', ['aws.configure.auth',
                                 'aws.configure.metadata',
                                 'aws.configure.script']);

//using the value provider recipe 
app.value("dataServiceURL", '/WeaveServices/DataService');
app.value('adminServiceURL', '/WeaveServices/AdminService');
app.value('projectManagementURL', '/WeaveAnalystServices/ProjectManagementServlet');
app.value('scriptManagementURL', '/WeaveAnalystServices/ScriptManagementServlet');
app.value('computationServiceURL', '/WeaveAnalystServices/ComputationalServlet');

app.controller('AWSController', function($scope, $state, authenticationService) {
	//for ng-route
	//$scope.$route = $route;
	$scope.state = $state;
	$scope.authenticationService = authenticationService;

});
