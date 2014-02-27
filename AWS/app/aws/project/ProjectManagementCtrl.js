angular.module('aws.project', [])
.controller("ProjectManagementCtrl", function($scope, queryService){
	
	$scope.currentProjectSelected = "";//displays in the UI the current selected Project
	
	$scope.listOfProjects =[];
	$scope.listOfProjects = queryService.getListOfProjects();//fetches for Drop down
	
	$scope.listItems = [];//list of returned JSON Objects 
	$scope.currentQuerySelected = {};

	//as soon as the UI is updated fetch the project and the list of queryObjects within
	$scope.$watch('projectSelectorUI', function(){
		if($scope.projectSelectorUI != undefined && $scope.projectSelectorUI != ""){
			queryService.queryObject.projectSelected = $scope.projectSelectorUI;//updates query Object
			$scope.currentProjectSelected = $scope.projectSelectorUI;
			
			
			if(!(angular.isUndefined($scope.listItems))){
				$scope.listItems = [];
				//console.log("hello");
			}
			
			$scope.listItems = queryService.getListOfQueryObjectsInProject($scope.projectSelectorUI);
				
		}
	});
	
	

	$scope.$watch(function() {
		return queryService.dataObject.listofQueryObjectsInProject;
	}, function() {
		$scope.listItems = queryService.dataObject.listofQueryObjectsInProject;
				
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
		queryService.queryObject = $scope.currentQuerySelected;
		console.log("updatedQuery", $scope.currentQuerySelected);
	};
	
	$scope.deleteQuery = function(){
		console.log("currentProject", $scope.currentProjectSelected);
		var dlStatus = queryService.deleteProject($scope.currentProjectSelected);
		console.log("status", dlStatus);
	};
	
	$scope.runQueryInAnalysisBuilder = function(){
		queryService.queryObject = $scope.currentQuerySelected;
		queryHandler = new aws.QueryHandler(queryService.queryObject);//TO DO
		queryHandler.runQuery();
		console.log("running query");
	};

});

