'use strict';


// Declare app level module which depends on filters, and services
// angular.module('myApp', ['myApp.filters', 'myApp.services', 'myApp.directives', 'myApp.controllers']).
//   config(['$routeProvider', function($routeProvider) {
//     $routeProvider.when('/view1', {templateUrl: 'partials/partial1.html', controller: 'MyCtrl1'});
//     $routeProvider.when('/view2', {templateUrl: 'partials/partial2.html', controller: 'MyCtrl2'});
//     $routeProvider.otherwise({redirectTo: '/view1'});
//   }]);

/**
*  Module
*
* Description
*/

var app = angular.module('aws', ['aws.Main', 
                                 'ui.bootstrap',
                                 'ui.select2',
                                 'ngGrid',
                                 'aws.filters', 
                                 'aws.services', 
                                 'aws.directives', 
                                 'aws.project', 
                                 'aws.DataDialog', 
                                 'aws.leftPanel',
                                 'aws.IndicatorPanel',
                                 'aws.panelControllers']);

app.config(['$routeProvider', function($routeProvider){
 		$routeProvider.
 			when('/analysis', {templateUrl: 'tpls/analysis.tpls.html', controller: 'AnalysisCtrl'}).
 			when('/calculation', {templateUrl: 'tpls/calculation.tpls.html', controller: 'CalculationCtrl'}).
 			when('/visualization', {
 				templateUrl: 'tpls/visualization.tpls.html',
 				controller: 'VisualizationCtrl'
 			}).
 			otherwise({redirectTo: '/analysis'});
			
 	}]);

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
}]);


