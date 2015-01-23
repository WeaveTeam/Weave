angular.module('aws.project', [])
.controller("ProjectManagementCtrl", function($scope, $filter, queryService,projectService, QueryHandlerService){
	$scope.projectService = projectService;
	
	//retrives project list
	projectService.getListOfProjects();
	//select2-sortable handlers
	$scope.getItemId = function(item) {
		return item;
	};
	
	$scope.getItemText = function(item) {
		return item;
	};
	
	//projectlist
	$scope.getProjectsList = function(term, done) {
		var values = $scope.projectService.cache.listOfProjectsFromDatabase;
		done($filter('filter')(values,term));
	};
	
	$scope.$watch('projectService.cache.dataTable', function(){
		if($scope.projectService.cache.dataTable){
			console.log("project Selected", $scope.projectService.cache.dataTable);
			$scope.projectService.getListOfQueryObjects($scope.projectService.cache.dataTable);
		}
	});
	
	
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
	

     //Watch for when record is inserted in db
     $scope.$watch(function(){
     	return queryService.queryObject.properties.insertQueryObjectStatus;
      }, function(){ 
     	 $scope.insertQueryObjectStatus = queryService.queryObject.properties.insertQueryObjectStatus;
     	if(!(angular.isUndefined($scope.insertQueryObjectStatus)))
		 {
		 	if($scope.insertQueryObjectStatus != 0)
		 		{
    		 		alert("Query Object has been added");
    		 		queryService.cache.listofQueryObjectsInProject = [];
	    			queryService.getListOfQueryObjectsInProject($scope.projectSelectorUI);//makes a new call
		 		}
		 }
	 
     	queryService.queryObject.properties.insertQueryObjectStatus = 0;//reset
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
		console.log("item", item);
		nameOfQueryObjectToDelete = item.queryObjectName; 
		$scope.deleteQueryConfirmation($scope.projectService.cache.dataTable, nameOfQueryObjectToDelete);
	};
	
	$scope.runQueryInAnalysisBuilder = function(item){
		//queryService.queryObject = item;//setting the queryObject to be handled by the QueryHandlerService
		//TODO validate the query before running
		
		QueryHandlerService.run(item);
		console.log("Running query");
	};
	
	$scope.returnSessionState = function(queryObject){
		projectService.returnSessionState(queryObject);
	};
	
	$scope.loadInAnalysis = function(queryObject){
		console.log("setting queryObject");
		queryService.queryObject = queryObject;
	};
	
});

