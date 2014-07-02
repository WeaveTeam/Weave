angular.module('aws.project', [])
.controller("ProjectManagementCtrl", function($scope,queryService){
	$scope.defaultProjectOption = 'Select Project';
	$scope.currentProjectSelected = "";//used as flag for keeping track of projects deleted
	
	$scope.listOfProjects =[];
	queryService.getListOfProjectsfromDatabase();
	$scope.thumbnailsToDisplay = [];
	$scope.listItems = [];//list of returned JSON Objects 
	$scope.currentQuerySelected = {};//current query Selected by the user for loading/running/deleting etc
	$scope.deleteProjectStatus = 0;//count changes depending on how many queryObjects (rows) belonging to a project have been deleted from database
	$scope.deleteQueryObjectStatus = 0;//count changes to 1 when a single queryObject has been deleted from database
	$scope.insertQueryObjectStatus = 0;//count changes when single queryObject or multiple are added to the database
	$scope.columnString= "";//string that displays the by-variables in the 'Columns:' section of each list item 
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
	
	$scope.$watch(function(){
		return queryService.dataObject.listOfProjectsFromDatabase;
	}, function(){
		$scope.listOfProjects = queryService.dataObject.listOfProjectsFromDatabase;
	});
	
	//as soon as the UI is updated fetch the project and the list of queryObjects within
	$scope.$watch('projectSelectorUI', function(){
		if($scope.projectSelectorUI != undefined && $scope.projectSelectorUI != ""){
			$scope.currentProjectSelected = $scope.projectSelectorUI;
			//if its isnt undefined clean and reset for every project selection iteration
			if(!(angular.isUndefined($scope.listItems))){
				$scope.listItems = [];
			}
			
			//works
			//$scope.listItems = queryService.getListOfQueryObjectsInProject($scope.projectSelectorUI);
			$scope.listItems = queryService.getListOfQueryObjects($scope.projectSelectorUI);
		}
	});
	
	
	// as soon as dataObject in queryService is updated, update the listItems(dataSource to populate list of queryObjects dynamically)
	$scope.$watch(function() {
		return queryService.dataObject.listofQueryObjectsInProject;
	}, function() {
		$scope.listItems = queryService.dataObject.listofQueryObjectsInProject;//updating the list of projects in this controller
		//for retrieving the columns section on the listItem to be displayed
		for(var i in $scope.listItems){
			$scope.columnString = "";
			var columns = $scope.listItems[i].ScriptColumnRequest;
			for(var j in columns){
				var title = columns[j].title;
				$scope.columnString= $scope.columnString.concat(title) + " , ";
			}
		}
	});
	
	$scope.$watch(function(){
		return queryService.dataObject.projectDescription;
	},function(){
		$scope.projectDescriptionStatement = queryService.dataObject.projectDescription;
	});

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
    	    	 console.log("deleteStatus", $scope.deleteQueryObjectStatus);
    	     	 console.log("name ofQueryToDelete", nameOfQueryToDelete);
    	     	 
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
     
     $scope.completeObjects= [];
     //watch when thumbnails are returned
     $scope.$watch(function() {
			return queryService.dataObject.thumbnails;
		}, function() {
			// list of base64 encoded images returned
			$scope.thumbnailsToDisplay = [];
			$scope.thumbnailsReturned = queryService.dataObject.thumbnails;
			if (!(angular.isUndefined($scope.thumbnailsReturned))) {
				for ( var i = 0; i < $scope.thumbnailsReturned.length; i++) {
					var imageString = "data:image/png;base64,"
							+ $scope.thumbnailsReturned[i];
					$scope.thumbnailsToDisplay[i] = imageString;
				}
			}
			
			//make the complete object 
			if(!(angular.isUndefined($scope.listItems)))
				{
					$scope.completeObjects = [];
					for(var f = 0; f < $scope.listItems.length; f++){
						var tempObject = {};
						tempObject.queryObject = $scope.listItems[f];
						tempObject.thumbnail = $scope.thumbnailsToDisplay[f];
						$scope.completeObjects.push(tempObject);
					}
				}
			
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
		queryService.returnSessionState(queryObject);
	};
	
});

