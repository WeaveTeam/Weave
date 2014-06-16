/**
 * this controller controls the output tab 
 */
angular.module('aws.outputView', [])
.controller("OutputViewManagementController", function($scope, queryService){
	
	$scope.listOfProjectsforOuput = [];
	$scope.listofVisualizations = [];//
	$scope.projectListMode = 'unselected';
	$scope.listItems = [];
	$scope.currentThumbnail = "";
	
	//when the user chooses between multiple or single project view
	$scope.$watch('projectListMode', function(){
		
		if($scope.projectListMode == 'multiple'){
			//get pictures of all records(projects)
			queryService.getListOfQueryObjectVisualizations("CDC");
		}
		
		if($scope.projectListMode == 'single'){
			//enable the drop down box
			//returns the list of projects to select from 
			queryService.getListOfProjectsfromDatabase();
		}
	});
	
	//once project is selected for single view, obtain the list of visualizations in that project
	$scope.$watch('existingProjects', function(){
		if(!(angular.isUndefined($scope.existingProjects)) && $scope.existingProjects != "")
			console.log("projectSelected", $scope.existingProjects);
		var params= {};
		params.projectName = $scope.existingProjects;
		queryService.getListOfQueryObjectVisualizations(params);//depending on project selected		
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
		return queryService.dataObject.listofVisualizations;
	}, function(){
		//list of base64 encoded images returned
		$scope.listItems = queryService.dataObject.listofVisualizations;
		if(!(angular.isUndefined($scope.listItems)))
			{
				for( var i = 0; i < $scope.listItems.length; i++){
					var imageString = "data:image/png;base64," + $scope.listItems[i];
					$scope.listofVisualizations[i] = imageString;
				}
			}
		
	});
	
	
	
	$scope.showThumbnail = function(item){
		$scope.currentThumbnail = item;
	};
});