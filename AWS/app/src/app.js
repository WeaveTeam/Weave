'use strict';

var app = angular.module('aws', ['ngAnimate',
                                 'ngSanitize',
                                 'mgcrea.ngStrap',
                                 'ui.select2',
                                 'ui.select2.sortable',
                                 //'ui.bootstrap',
                                 'ui.sortable',
                                 'ngGrid',
                                 'ui.router',
                                 'mk.editablespan'
                                 ]); 

app.run(['$rootScope', function($rootScope){

}])
.config(['$stateProvider', '$urlRouterProvider', '$parseProvider', function($stateProvider, $urlRouterProvider, $parseProvider) {
	
}]);


/**********************Using ng-route***************************************/

app.controller('AWSController', ['$scope', '$state', function($scope, $state) {
	$scope.shweta = "hello";
	$scope.state = $state;
}]);
