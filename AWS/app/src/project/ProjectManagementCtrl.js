angular.module('aws.project', [])
.controller("ProjectManagementCtrl", function($scope,$rootScope, $filter, queryService, projectService, QueryHandlerService, WeaveService, $location){
	$scope.projectService = projectService;
	
	//retrives project list
	projectService.getListOfProjects();
	//projectlist
	
	//when a datatable is selected or changed
	$scope.$watch('projectService.cache.dataTable', function(){
		if($scope.projectService.cache.dataTable){
			console.log("project Selected", $scope.projectService.cache.dataTable);
			$scope.projectService.getListOfQueryObjects($scope.projectService.cache.dataTable);
		}
	});
	
	
	$scope.insertQueryObjectStatus = 0;//count changes when single queryObject or multiple are added to the database
	var nameOfQueryObjectToDelete = "";
	
	//external directives
//	$scope.aside = {
//			title : 'Query Object Editor'
//			
//		};
//	$scope.aside2 = {
//			title : 'New Project'
//			
//		};

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
		$scope.deleteQueryConfirmation($scope.projectService.cache.dataTable, nameOfQueryObjectToDelete);
	};

	$scope.openInAnalysis = function(queryObject) {
		queryService.queryObject = queryObject;
		//TODO dont use rootscope
		$rootScope.$broadcast('queryObjectloaded', queryService.queryObject);
		$location.path('/analysis'); 
	};
	
	$rootScope.$on('queryObjectloaded', function(event,data){
		//TODO dont use rootscope
		console.log("receiving broadcast");
		$rootScope.$watch(function(){
			 return WeaveService.weave;
		}, function(){
			if(WeaveService.weave){
				WeaveService.weave.path().state(data.sessionState);//TODO fix this adding properties dynamically not GOOD
				delete data.sessionState;//TODO fix this adding properties dynamically not GOOD
			}
		});
			
	});
	
	//called when the thumb-nail is clicked
	/**
	 *@param given a query object
	 *@returns it returns the weave visualizations for it.
	 */
	$scope.returnSessionState = function(queryObject){
		projectService.returnSessionState(queryObject).then(function(weaveSessionState){
			var newWeave;
			if(!(angular.isUndefined(weaveSessionState))){
				
		   		 if (!newWeave || newWeave.closed) {
						newWeave = window
								.open("/weave.html?",
										"abc",
										"toolbar=no, fullscreen = no, scrollbars=yes, addressbar=no, resizable=yes");
					}
		   		 
			   		WeaveService.setWeaveWindow(newWeave);
			   		
			   		$scope.$watch(function(){
			   			return WeaveService.weave;
			   		},function(){
			   			if(WeaveService.checkWeaveReady()) 
		   					WeaveService.setBase64SessionState(weaveSessionState);
			   		});
		   		}
			else{
				console.log("Session state was not returned");
			}
		});
	};
	
});

