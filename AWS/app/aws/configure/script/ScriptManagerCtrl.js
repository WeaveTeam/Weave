angular.module('aws.configure.script', ['ngGrid'])
.controller("ScriptManagerCtrl", function($scope, queryService){
				
		$scope.listOfScripts = [];
		$scope.uploadScript = false;
		$scope.textScript  = false;
		$scope.saveButton = false;
		queryService.getListOfScripts();
		
		
		$scope.$watch(function() {
			return queryService.dataObject.listOfScripts;
		}, function() {
			$scope.listOfScripts = queryService.dataObject.listOfScripts;
		});
		
		
		
});
			