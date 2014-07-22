var weave_mod = angular.module('aws.WeaveModule', []);


weave_mod.service("WeaveService", function() {
	
	
	
	
});

weave_mod.controller('WeaveModuleCtrl', function($scope, queryService, QueryHandlerService, WeaveService) {

	$scope.service = queryService;
	
});