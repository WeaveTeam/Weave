angular.module('aws.project')
.controller("projectAdditionController", function($scope, queryService){
	
	
	$scope.$watch('projectName', function(){
		var project = $scope.projectName;
	});
	
	$scope.$watch('userName', function(){
		var user = $scope.userName;
	});
	
	
	 $scope.saveNewProjectToDatabase = function(){
		
		 console.log("saving to database");
		 
		// queryService.
		 
	 };
	
});