angular.module('aws.project', [])
.controller("ProjectManagementCtrl", function($scope,queryService,projectService, QueryHandlerService){
	$scope.projectService = projectService;
	projectService.getListOfProjects();
	
	$scope.insertQueryObjectStatus = 0;//count changes when single queryObject or multiple are added to the database
	var nameOfQueryObjectToDelete = "";
	//external directives
	$scope.aside = {
			title : 'Query Object Editor'
			
		};
	$scope.aside2 = {
			title : 'New Project'
			
		};

	//TODO find way to identify button id in angular
	$scope.load = function(buttonid, item){
		if(buttonid == "newQueryObjectButton"){
			$scope.currentJson = "";
		}
			
		if(buttonid == "openQueryObjectButton"){
			$scope.currentJson = item;
		}
	};
	
	$scope.getListOfQueryObjects = function(){
		if(!(angular.isUndefined(projectService.data.projectSelectorUI)))
			projectService.getListOfQueryObjects(projectService.data.projectSelectorUI);
	};

     //Watch for when record is inserted in db
     $scope.$watch(function(){
     	return queryService.dataObject.insertQueryObjectStatus;
      }, function(){ 
     	 $scope.insertQueryObjectStatus = queryService.dataObject.insertQueryObjectStatus;
     	if(!(angular.isUndefined($scope.insertQueryObjectStatus)))
		 {
		 	if($scope.insertQueryObjectStatus != 0)
		 		{
    		 		alert("Query Object has been added");
    		 		queryService.dataObject.listofQueryObjectsInProject = [];
	    			queryService.getListOfQueryObjectsInProject($scope.projectSelectorUI);//makes a new call
		 		}
		 }
	 
     	queryService.dataObject.insertQueryObjectStatus = 0;//reset
      });
     
	/****************Button Controls***************************************************************************************************************************************/
     $scope.loadConstructedQueryObject = function(){
     	$scope.currentJson = queryService.queryObject; 
      };
     
	//deletes an entire Project along with all queryObjects within
	$scope.deleteEntireProject = function(){
		$scope.deleteProjectConfirmation($scope.currentProjectSelected);
	};
	
	
	//additional checks for confirming deletion
		$scope.deleteProjectConfirmation = function(currentProjectSelected){
			var deletePopup = confirm("Are you sure you want to delete project " + projectService.data.projectSelectorUI + "?");
			if(deletePopup == true){
				projectService.deleteProject(projectService.data.projectSelectorUI);
			}
			
		};
		
	$scope.deleteQueryConfirmation = function(currentProject, currentQueryFileName){
		var deletePopup = confirm("Are you sure you want to delete " + currentQueryFileName + " from " + currentProject + "?");
		if(deletePopup == true){
			projectService.deleteQueryObject(currentProject, currentQueryFileName);
		}
	};
	
	//deletes a single queryObject within the currently selected Project
	$scope.deleteSpecificQueryObject = function(item){
		nameOfQueryObjectToDelete = item.queryObjectName; 
		$scope.deleteQueryConfirmation(projectService.data.projectSelectorUI, nameOfQueryObjectToDelete);
	};
	
	$scope.runQueryInAnalysisBuilder = function(item){
		queryService.queryObject = item;//setting the queryObject to be handled by the QueryHandlerService
		QueryHandlerService.run(false);
		//queryHandler = new aws.QueryHandler(queryService.queryObject);//TO DO
		//queryHandler.runQuery();
		console.log("running query");
	};
	
	$scope.returnSessionState = function(queryObject){
		projectService.returnSessionState(queryObject);
	};
	
	$scope.loadInAnalysis = function(queryObject){
		console.log("setting queryObject");
		queryService.queryObject = queryObject;
	};
	
});

