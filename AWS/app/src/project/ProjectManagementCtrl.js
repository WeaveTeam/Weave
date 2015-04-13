angular.module('aws.project', [])
.controller("ProjectManagementCtrl", function($scope,$rootScope, $filter, queryService, projectService, WeaveService, usSpinnerService, $location){
	$scope.projectService = projectService;
	//retrives project list
	$scope.projectService.getListOfProjects();
	//projectlist
	
	
	//when a is selected or changed
	$scope.$watch('projectService.cache.project.selected', function(){
		if($scope.projectService.cache.project.selected){
			console.log("project Selected", $scope.projectService.cache.project.selected);
			$scope.projectService.getListOfQueryObjects($scope.projectService.cache.project.selected);
		}
	});
	
	
	$scope.insertQueryObjectStatus = 0;//count changes when single queryObject or multiple are added to the database
	var nameOfQueryObjectToDelete = "";

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
	    			queryService.getListOfQueryObjectsInProject($scope.projectService.cache.project.selected);//makes a new call
		 		}
		 }
	 
     	queryService.queryObject.properties.insertQueryObjectStatus = 0;//reset
      });
     
	/****************Button Controls***************************************************************************************************************************************/

	//deletes an entire Project along with all queryObjects within
	$scope.deleteEntireProject = function(){
		$scope.deleteProjectConfirmation($scope.projectService.cache.project.selected);
	};
	
	
	//additional checks for confirming deletion
		$scope.deleteProjectConfirmation = function(projectSelected){
			var deletePopup = confirm("Are you sure you want to delete project " + projectSelected + "?");
			if(deletePopup == true){
				projectService.deleteProject(projectSelected);
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
		$scope.deleteQueryConfirmation($scope.projectService.cache.project.selected, nameOfQueryObjectToDelete);
	};

	$scope.openInAnalysis = function(incoming_queryObject) {
		//queryService.queryObject = queryObject;
		//TODO dont use rootscope
		//$rootScope.$broadcast('queryObjectloaded', incoming_queryObject);
		$scope.$emit("queryObjectloaded", incoming_queryObject);
		$location.path('/analysis'); 
	};
	
//	$rootScope.$on('queryObjectloaded', function(event,incoming_queryObject){
//		//TODO dont use rootscope
//		console.log("receiving broadcast");
//		$rootScope.$watch(function(){
//			 return WeaveService.weave;
//		}, function(){
//			queryService.queryObject = incoming_queryObject;
//			if(WeaveService.checkWeaveReady()){
//				if(incoming_queryObject.weaveSessionState)
//					WeaveService.weave.path().state(incoming_queryObject.weaveSessionState);//TODO fix this adding properties dynamically not GOOD
//			}
//		});
//			
//	});
	
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

