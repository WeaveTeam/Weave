angular.module('aws.project', [])
.controller("ProjectManagementCtrl", function($scope,queryService,projectService){
	$scope.projectService = projectService;
	
	projectService.getListOfProjectsfromDatabase();
	
	
	$scope.currentProjectSelected = "";//used as flag for keeping track of projects deleted
	$scope.deleteProjectStatus = 0;//count changes depending on how many queryObjects (rows) belonging to a project have been deleted from database
	$scope.deleteQueryObjectStatus = 0;//count changes to 1 when a single queryObject has been deleted from database
	$scope.insertQueryObjectStatus = 0;//count changes when single queryObject or multiple are added to the database
	var nameOfQueryToDelete = "";
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
	
	$scope.getListOfQueryObject = function(){
		projectService.getListOfQueryObjects(projectService.data.projectSelectorUI);
	};

	
//	$scope.$on('objects:updated', function(event, data){
//		console.log("scope in controller", $scope);
//		console.log("completeObjects in controller", data);
//		console.log("event in controller", event);
//		
//		$scope.listItems = data;
//		console.log("listitms", $scope.listItems);
//		
//	});
	
	//as soon as service returns deleteStatus
	//1. report status
	//2. reset required variables
	//3. updates required lists
     $scope.$watch(function(){
    	 return queryService.dataObject.deleteProjectStatus;
     },
    	 function(){
    	 $scope.deleteProjectStatus = queryService.dataObject.deleteProjectStatus;
    	 if(! ($scope.deleteProjectStatus == 0 || angular.isUndefined($scope.deleteProjectStatus)))
    		 {
    		 if(!($scope.currentProjectSelected != "" || angular.isUndefined($scope.currentProjectSelected)))
    			 {
	    			 alert("The Project " + $scope.currentProjectSelected + " has been deleted");
	    			 queryService.dataObject.listOfProjectsFromDatabase = [];//emptying projects list
	    			 queryService.dataObject.listofQueryObjectsInProject = [];//emptying queryObjects list
	    			 $scope.projectSelectorUI = $scope.defaultProjectOption;//resetting dropDown UI
	    			 $scope.currentProjectSelected = "";//reset
	    			 queryService.getListOfProjectsfromDatabase();//fetch new list
    			 }
    		 	
    		 }
    	 
	    	 queryService.dataObject.deleteProjectStatus = 0;
    	
     });
     
     $scope.$watch(function(){
    	 return queryService.dataObject.deleteQueryObjectStatus;
     }, function(){
    	 $scope.deleteQueryObjectStatus = queryService.dataObject.deleteQueryObjectStatus;
    	    	// console.log("deleteStatus", $scope.deleteQueryObjectStatus);
    	     	// console.log("name ofQueryToDelete", nameOfQueryToDelete);
    	     	 
    	     	 if(!(angular.isUndefined($scope.deleteQueryObjectStatus)))
    	  		 {
    	  		 	if($scope.deleteQueryObjectStatus != 0 && !(angular.isUndefined($scope.projectSelectorUI)))
    	  		 		{
    	  		 			alert("Query Object " + nameOfQueryToDelete + " has been deleted");
    	      		 		queryService.dataObject.listofQueryObjectsInProject = [];
    	 	    			queryService.getListOfQueryObjectsInProject($scope.projectSelectorUI);//makes a new call
    	  		 		}
    	  		 }
     });
     
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
     
    var newWeave;
     
     $scope.$watch(function(){
    	 return queryService.dataObject.weaveSessionState;//string which is the session state
    	 console.log("weaveSessionState", queryService.dataObject.weaveSessionState);
     }, function(newVal, oldVal){
    	 if(!(newVal == oldVal)){
    		 if(!(angular.isUndefined(queryService.dataObject.weaveSessionState))){
        		 if (!newWeave || newWeave.closed) {
     				newWeave = window
     						.open("aws/visualization/weave/weave.html",
     								"abc",
     								"toolbar=no, fullscreen = no, scrollbars=yes, addressbar=no, resizable=yes");
     				newWeave.setSession = queryService.dataObject.weaveSessionState;
     			}
        		 else{
        			 newWeave.setSessionHistory(queryService.dataObject.weaveSessionState);
        		 }
        		 newWeave.logvar = "Displaying Visualizations";
        	 }
    	 }
    	 
    	 
     });
	/****************Button Controls***************************************************************************************************************************************/
     $scope.loadConstructedQueryObject = function(){
     	 console.log("cconstructed query Object", queryService.queryObject);
     	$scope.currentJson = queryService.queryObject; 
      };
     
	//deletes an entire Project along with all queryObjects within
	$scope.deleteEntireProject = function(){
		console.log("currentProject", $scope.currentProjectSelected);
		$scope.deleteProjectConfirmation($scope.currentProjectSelected);
	};
	
	
	//additional checks for confirming deletion
		$scope.deleteProjectConfirmation = function(currentProjectSelected){
			var deletePopup = confirm("Are you sure you want to delete project " + currentProjectSelected + "?");
			if(deletePopup == true){
				//only if Ok is pressed delete the project
				queryService.deleteProject($scope.currentProjectSelected);
			}
			
		};
		
	$scope.deleteQueryConfirmation = function(currentProjectSelected, currentQueryFileName){
		var deletePopup = confirm("Are you sure you want to delete " + currentQueryFileName + " from " + currentProjectSelected + "?");
		if(deletePopup == true){
			 
			queryService.deleteQueryObject(currentProjectSelected, currentQueryFileName);
		
		}
	};
	$scope.runQueryInAnalysisBuilder = function(item){
		queryService.queryObject = item;
		queryHandler = new aws.QueryHandler(queryService.queryObject);//TO DO
		queryHandler.runQuery();
		console.log("running query");
	};
	
	//deletes a single queryObject within the currently selected Project
	$scope.deleteSpecificQueryObject = function(item){
		console.log('checkingforINdex', item);
		var index = queryService.dataObject.listofQueryObjectsInProject.indexOf(item);
		
		nameOfQueryToDelete = queryService.dataObject.queryNames[index];
		console.log('queryName', nameOfQueryToDelete);
		
		$scope.deleteQueryConfirmation($scope.currentProjectSelected, nameOfQueryToDelete);
		
	};
	
	$scope.returnSessionState = function(queryObject){
		projectService.returnSessionState(queryObject);
	};
	
});

