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

var app = angular.module('myApp', ['ui.bootstrap','myApp.filters', 'myApp.services', 'myApp.directives', 'myApp.dataClient']);
// angular.module('myModule', ["ui.bootstrap"]);
// .config(['$routeProvider', function($routeProvider){
// 		$routeProvider.
// 			when('/phones', {templateUrl: 'partials/phone-list.html', controller: PhoneListCtrl}).
// 			when('/phones/:phoneId', {templateUrl: 'partials/phone-detail.html', controller: PhoneDetailCtrl}).
// 			when('/aws', {
// 				templateUrl: 'partials/genericPanel.html',
// 				controller: PanelGenericCtrl
// 			}).
// 			otherwise({redirectTo: '/aws'});
			
// 	}]);

