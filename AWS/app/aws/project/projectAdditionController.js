angular.module('aws.project')
.controller("projectAdditionController", function($scope, queryService){
	
	var project = "";
	var user = "";
	var queryObjectJsons = []; //array of uploaded queryObject jsons
	
	
	$scope.$watch('projectName', function(){
		 project = $scope.projectName;
	});
	
	$scope.$watch('userName', function(){
		 user = $scope.userName;
	});
	
	
	 $scope.saveNewProjectToDatabase = function(){
		
		 console.log("saving to database");
		 var queryObjectTitle = []; //array of titles extracted from the queryObjectJsons
		 var queryObjectContent = [];//array of stringifed json objects
		 
		 
		 for(var i in queryObjectJsons){
			 
			var currentTitle = queryObjectJsons[i].title;//get title
			queryObjectTitle.push(currentTitle);
			var singleQueryObject = JSON.stringify(quesryObjectJsons[i]); //stringify object
			queryObjectContent.push(singleQueryObject);
			 
			}
		 
		 
		// queryService.addQueryObjectToProject(user, project, queryObjectTitle, queryObjectContent);
		 
	 };
	
});