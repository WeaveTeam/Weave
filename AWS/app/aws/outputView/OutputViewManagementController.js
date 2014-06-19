/**
 * this controller controls the output tab 
 */
angular.module('aws.outputView', [])
.controller("OutputViewManagementController", function($scope, queryService){
	
	$scope.listOfProjectsforOuput = [];
	$scope.thumbnails = [];//
	$scope.projectListMode = 'unselected';
	$scope.listItems = [];
	$scope.currentThumbnail = "";
	$scope.listOfSessionStates= [];
	
	//when the user chooses between multiple or single project view
	$scope.$watch('projectListMode', function(){
		
		if($scope.projectListMode == 'multiple'){
			//get pictures of all records(projects)
			queryService.getListOfQueryObjectVisualizations(null);
		}
		
		if($scope.projectListMode == 'single'){
			//enable the drop down box
			//returns the list of projects to select from 
			queryService.getListOfProjectsfromDatabase();
		}
	});
	
	//once project is selected for single view, obtain the list of visualizations in that project
	$scope.$watch('existingProjects', function(){
		if(!(angular.isUndefined($scope.existingProjects)) && $scope.existingProjects != ""){
			
			console.log("projectSelected", $scope.existingProjects);
			queryService.getListOfQueryObjectVisualizations($scope.existingProjects);//depending on project selected		
		}
	});
	
	//check for when list of projects is returned
	$scope.$watch(function(){
		return queryService.dataObject.listOfProjectsFromDatabase;
		console.log("projectsReturned", queryService.dataObject.listOfProjectsFromDatabase);
	}, function(){
		$scope.listOfProjectsforOuput = queryService.dataObject.listOfProjectsFromDatabase;
	});
	
	//check for visualizations are returned
	$scope.$watch(function(){
		return queryService.dataObject.thumbnails;
	}, function(){
		//list of base64 encoded images returned
		$scope.listItems = queryService.dataObject.thumbnails;
		if(!(angular.isUndefined($scope.listItems)))
			{
				for( var i = 0; i < $scope.listItems.length; i++){
					var imageString = "data:image/png;base64," + $scope.listItems[i];
					$scope.thumbnails[i] = imageString;
				}
			}
	});
	
	//collecting the session states returned
	$scope.$watch(function(){
		return queryService.dataObject.listOfSessionStates;
	}, function(){
		$scope.listOfSessionStates = queryService.dataObject.listOfSessionStates;
	});
	
	$scope.showThumbnail = function(item){
		$scope.currentThumbnail = item;
		$scope.index = $scope.thumbnails.indexOf(item);
		console.log("index", $scope.index);
	};
	
	//testing
	var newWeave ;
	
	/**********************************************************Button controls*****************************/
	$scope.openRealWeave = function(){

		if(!newWeave || newWeave.closed) {
		newWeave = window.open("aws/visualization/weave/weave.html",
			"abc","toolbar=no, fullscreen = no, scrollbars=yes, addressbar=no, resizable=yes");
	}
	
	 newWeave.logvar = "Loading Session State";
 	var currentSessionString = $scope.listOfSessionStates[$scope.index];
		newWeave.setSession = currentSessionString;
	};
});