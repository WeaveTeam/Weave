angular.module('aws.project', [])
.controller("ProjectManagementCtrl", function($scope, queryService){
	
	//$scope.currentProjectSelection = "";//displays in the UI the current selected Project
	
	$scope.listOfProjects =[];
	$scope.listOfProjects = queryService.getListOfProjects();
	$scope.listItems = [];//list of JSON Objects 
	$scope.finalListOfQueryObjects= [];//corresponding list for UI
	$scope.currentQuerySelected = {};

	//as soon as the UI is updated fetch the project and the list of queryObjects within
	$scope.$watch('projectSelectorUI', function(){
		if($scope.projectSelectorUI != undefined && $scope.projectSelectorUI != ""){
			queryService.queryObject.projectSelected = $scope.projectSelectorUI;//updates UI
			//$scope.currentProjectSeletion = $scope.projectSelectorUI;
			
			queryService.getListOfQueryObjectsInProject($scope.projectSelectorUI);
				
		}
	});
	
	

	$scope.$watch(function() {
		return queryService.dataObject.listofQueryObjectsInProject;
	}, function() {
		$scope.listItems = queryService.dataObject.listofQueryObjectsInProject;
		//for(var i in $scope.listItems){
		console.log("oneItem", $scope.listItems);
		//}
		
	});
	
	//updates the UI depending on the queryObject
	$scope.$watch(function(){
		return queryService.queryObject.projectSelected;
	}, function(){
		$scope.projectSelectorUI = queryService.queryObject.projectSelected;
	});
	
	
//	//as soon as project is selected create the list
//	$scope.$watch(function(){
//		return $scope.listItems;
//	}, function(){

//	});
	
     
	
	/****************Button Controls******************************/
	
	$scope.loadQueryInAnalysisBuilder = function(){
		//load that JSON queryObject
		console.log("loadScope", $scope.$id);
		//queryService.queryObject = $scope.currentQuerySelected;
		console.log("updatedQuery", $scope.currentQuerySelected);
	};
	
	$scope.runQueryInAnalysisBuilder = function(){
		//call the run query function for regular run button
	};
});