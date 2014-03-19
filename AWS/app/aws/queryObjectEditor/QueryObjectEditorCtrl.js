/**
 * This controller controls the queryObject (json ) Editor
 */
angular.module('aws.queryObjectEditor', [])
.controller("QueryObjectEditorCtrl", function($scope, queryService){
	$scope.$watch(function(){
		console.log("currentJSON", $scope.queryObjectJson);
		return $scope.queryObjectJson;
	}, function(){
		$scope.currentJson = $scope.queryObjectJson;
		
	});

	
	/*****************************BUTTON CONTROLS******************************/
	
	$scope.saveToCurrentProject = function(){
		var projectName = $scope.currentProjectSelected;
		console.log("sendingProject",$scope.currentProjectSelected);
		var queryObjectTitle = $scope.currentQuerySelected.title;
		console.log("sendingTitle",$scope.currentQuerySelected.title);
		var queryObjectContent = JSON.stringify($scope.currentQuerySelected);//the actual json
		console.log("sendingContent", $scope.currentQuerySelected);
		var userName = "USerNameFOO";
		
		//calling the service
		
		queryService.addQueryObjectToProject(userName, projectName, queryObjectTitle, queryObjectContent);
	};
});