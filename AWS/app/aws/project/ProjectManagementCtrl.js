angular.module('aws.project', [])
.controller("ProjectManagementCtrl", function($scope,queryService){
	$scope.defaultProjectOption = 'Select Project';
	$scope.currentProjectSelected = "";//used as flag for keeping track of projects deleted
	
	$scope.listOfProjects =[];
	//$scope.listOfProjects = queryService.getListOfProjects();//fetches for Drop down
	$scope.listOfProjects = queryService.getListOfProjectsfromDatabase();
	$scope.queryObjectJson = "";
	
	$scope.listItems = [];//list of returned JSON Objects 
	$scope.currentQuerySelected = {};//current query Selected by the user for loading/running/deleting etc
	$scope.deleteProjectStatus = 0;//count changes depending on how many queryObjects (rows) belonging to a project have been deleted from database
	$scope.deleteQueryObjectStatus = 0;//count changes to 1 when a single queryObject has been deleted from database
	
	$scope.columnString= "";//string that displays the by-variables in the 'Columns:' section of each list item 
	
	//external directives
	$scope.aside = {
			title : 'Query Object Editor'
			
		};
	$scope.aside2 = {
			title : 'New Project'
			
		};
	

	//TODO find way to identify button id in angular
	$scope.load = function(buttonid){
		console.log(buttonid);
		if(buttonid == "newQueryObjectButton"){
			
			$scope.queryObjectJson = "";
		}
			
		if(buttonid == "openQueryObjectButton"){
			$scope.queryObjectJson = $scope.currentQuerySelected;
		}
	};
	//as soon as the UI is updated fetch the project and the list of queryObjects within
	$scope.$watch('projectSelectorUI', function(){
		if($scope.projectSelectorUI != undefined && $scope.projectSelectorUI != ""){
			queryService.queryObject.projectSelected = $scope.projectSelectorUI;//updates query Object
			$scope.currentProjectSelected = $scope.projectSelectorUI;
			
			//if its isnt undefined clean and reset for every project selection iteration
			if(!(angular.isUndefined($scope.listItems))){
				$scope.listItems = [];
			}
			
			$scope.listItems = queryService.getListOfQueryObjectsInProject($scope.projectSelectorUI);
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
			var columns = $scope.listItems[i].FilteredColumnRequest;
			for(var j in columns){
				var title = columns[j].column.title;
				$scope.columnString= $scope.columnString.concat(title) + " , ";
			}
		}
		//TO DO find better way to do this
		//put a check if project is empty	
		if($scope.listItems == null && !(angular.isUndefined($scope.projectSelectorUI))){
			alert("There are no queryObjects in the current project");
		}
	});
	
	//updates the UI depending on the queryObject
	$scope.$watch(function(){
		return queryService.queryObject.projectSelected;
	}, function(){
		$scope.projectSelectorUI = queryService.queryObject.projectSelected;
	});
	
	
	//as soon as service returns deleteStatus
	//1. report status
	//2. reset required variables
	//3. updates required lists
     $scope.$watch(function(){
    	 return queryService.dataObject.deleteProjectStatus;
     },
    	 function(){
    	 if($scope.deleteProjectStatus != 0 && $scope.currentProjectSelected != ""){
 			alert("The Project " + $scope.currentProjectSelected + " has been deleted");
 			$scope.currentProjectSelected = "";//reset
 			$scope.deleteProjectStatus = 0;//reset
 			$scope.projectSelectorUI = $scope.defaultProjectOption;//resetting dropDown UI
 			//update the query Object and queryObject UI
 			queryService.dataObject.listofQueryObjectsInProject = [];//clean and reset for next selection iteration, resets listItems which is used to render list of queryObjects
 			$scope.listOfProjects = queryService.getListOfProjects();//updates the new list of projects
 		}
    	 else{
    		 if($scope.currentProjectSelected != "")
    		 alert("The Project " + $scope.currentProjectSelected + " could not be deleted");
    	 }
     });
     
     $scope.$watch(function(){
    	 return queryService.dataObject.deleteQueryObjectStatus;
    	 //return $scope.deleteQueryObjectStatus;
     }, function(){
    	 console.log("woooohoooooo");
    	 $scope.deleteQueryObjectStatus = queryService.dataObject.deleteQueryObjectStatus;
    	 console.log("checking",$scope.deleteQueryObjectStatus);
    	 if($scope.deleteQueryObjectStatus != 0)
    		 {
    		 	alert("Query Object " + $scope.currentQuerySelected.title + " has been deleted");
    		 	$scope.currentQuerySelected = ""; //resetting currently selected queryObject
    		 	queryService.dataObject.listofQueryObjectsInProject = [];//resets and updates new list of queryObjects
    		 	queryService.getListOfQueryObjectsInProject($scope.projectSelectorUI);//makes a new call
    		 }
     });

     
     //sets the current queryObject
     $scope.choseQueryObject = function(item){
    	 $scope.currentQuerySelected = item;
		  console.log("current", $scope.currentQuerySelected);
 	};

	
	/****************Button Controls***************************************************************************************************************************************/
	
	$scope.openInQueryObjectEditor = function(){
		//load that JSON queryObject
		queryService.queryObject = $scope.currentQuerySelected;
		//set the currentJson of the democtrl
		console.log("updatedQuery", $scope.currentQuerySelected);
	};
	
	//deletes an entire Project along with all queryObjects within
	$scope.deleteEntireProject = function(){
		//$scope.currentProjectSelected = $scope.projectSelectorUI;//project selected for addition or deletion from UI
		console.log("currentProject", $scope.currentProjectSelected);
		$scope.deleteProjectConfirmation($scope.currentProjectSelected, null);
	};
	
	
	//additional checks for confirming deletion
		$scope.deleteProjectConfirmation = function(currentProjectSelected){
			var deletePopup = confirm("Are you sure you want to delete project " + currentProjectSelected + "?");
			if(deletePopup == true){
				//only if Ok is pressed delete the project
				$scope.deleteProjectStatus = queryService.deleteProject($scope.currentProjectSelected);
			}
			
		};
		
	$scope.deleteQueryConfirmation = function(currentProjectSelected, currentQueryFileName){
		var deletePopup = confirm("Are you sure you want to delete " + currentQueryFileName + " from " + currentProjectSelected + "?");
		if(deletePopup == true){
			 
			queryService.deleteQueryObject(currentProjectSelected, currentQueryFileName);
		
		}
	};
	$scope.runQueryInAnalysisBuilder = function(){
		queryService.queryObject = $scope.currentQuerySelected;
		queryHandler = new aws.QueryHandler(queryService.queryObject);//TO DO
		queryHandler.runQuery();
		console.log("running query");
	};
	
	//deletes a single queryObject within the currently selected Project
	$scope.deleteSpecificQueryObject = function(){
		console.log('checkingforINdex', $scope.currentQuerySelected);
		var index = queryService.dataObject.listofQueryObjectsInProject.indexOf($scope.currentQuerySelected);
		
		var nameOfQueryToDelete = queryService.dataObject.queryNames[index];
		console.log('queryName', nameOfQueryToDelete);
		
		$scope.deleteQueryConfirmation($scope.currentProjectSelected, nameOfQueryToDelete);
		
	};
	
});

