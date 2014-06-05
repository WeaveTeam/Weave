/**
 * this controller controls the output tab 
 */
angular.module('aws.outputView', [])
.controller("OutputViewManagementController", function($scope, queryService){
	
	$scope.listofProjects = [];
	
	//when the user chooses between multiple or single project view
	$scope.watch('projectListMode', function(){
		
		if($scope.projectListMode == 'multiple'){
			//get pictures of all records(projects)
			queryService.getListOfQueryObjectVisualizations(null);//all projects
		}
		
		if($scope.projectListMode == 'single'){
			//enable selection of project and retrieve existing projects
			queryService.getListOfProjectsfromDatabase;
		}
	});
	
	//once project is selected for single view, obtain the list of visualizations in that project
	$scope.watch('existingProjects', function(){
		queryService.getListOfQueryObjectVisualizations($scope.existingProjects);//depending on project selected		
	});
	
	$scope.watch(function(){
		return queryService.dataObject.listOfProjectsFromDatabase;
	}, function(){
		$scope.lisofProjects = queryService.dataObject.listOfProjectsFromDat;
	});
	
	$scope.watch(function(){
		return queryService.dataObject.listofVisualizations;
	}, function(){
		$scope.listofVisualizations = queryService.dataObject.listofVisualizations;
	});
});