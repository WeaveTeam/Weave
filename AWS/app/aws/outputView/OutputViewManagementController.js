/**
 * this controller controls the output tab 
 */
angular.module('aws.outputView', [])
.controller("OutputViewManagementController", function($scope, queryService){
	
	$scope.listOfProjectsforOuput = [];
	$scope.listofVisualizations = [];//
	$scope.projectListMode = 'unselected';
	$scope.listItems = ['a','b','c'];//stores current image list depending on mode selected
	
	//when the user chooses between multiple or single project view
	$scope.$watch('projectListMode', function(){
		
		if($scope.projectListMode == 'multiple'){
			//get pictures of all records(projects)
			console.log("multiple");
			queryService.getListOfQueryObjectVisualizations(null);
		}
		
		if($scope.projectListMode == 'single'){
			//enable the drop down box
			queryService.getListOfProjectsfromDatabase();
		}
	});
	
	//once project is selected for single view, obtain the list of visualizations in that project
	$scope.$watch('existingProjects', function(){
		if(!(angular.isUndefined($scope.existingProjects)) && $scope.existingProjects != "")
			console.log("projectSelected", $scope.existingProjects);
		//queryService.getListOfQueryObjectVisualizations($scope.existingProjects);//depending on project selected		
	});
	
	//check for when list of proejcts is returned
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
		$scope.listofVisualizations = queryService.dataObject.listofVisualizations;
	});
});