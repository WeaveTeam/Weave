var projectModule = angular.module('aws.project');
projectModule.controller("projectAdditionController", function($scope, $modal, projectService){
	$scope.projectService = projectService;
	
	//options needed for creating the modal instance window
	 //communicating with the modal
	 $scope.pjtModalOptions = {//TODO find out how to push error log to bottom of page
			 backdrop: true,
	         backdropClick: false,
	         dialogFade: true,
	         keyboard: true,
	         templateUrl: 'src/project/projectAdditionPanel.html',
	         controller: 'pjtAddtionInstanceCtrl',
	         resolve :{
	        	 projectNameEntered : function(){return $scope.projectNameEntered;},
	        	 userNameEntered : function(){return $scope.userNameEntered;},
	        	 projectDescriptionEntered : function(){return $scope.projectDescriptionEntered;}
	        	 
	         }
		};
	
	//button click event that creates the modal
	$scope.openAdditionPanel = function(){
		var saveNewProject = $modal.open($scope.pjtModalOptions);
		
		//called when modal is being closed
		saveNewProject.result.then(function(additionParams){//then function takes a single object
			 console.log("jsons", additionParams.uploadedObjects.queryObjectJsons);
			 console.log("titles", additionParams.uploadedObjects.queryObjectTitles);
			 console.log("userName", additionParams.userNameEntered);
			 
			 
			 
		});
	};
});

//Modal instance controller
projectModule.controller('pjtAddtionInstanceCtrl', function($scope, $modalInstance,projectService, projectNameEntered,projectDescriptionEntered, userNameEntered ) {
	$scope.projectService = projectService;
	$scope.uploadStatus = "";
	
	//object representation of a SINGLE file uploaded, changed everytime a file is uploaded
	$scope.uploaded = {
			QueryObject : {
				filename : "",
				content : ""			
			}
	};
	
	$scope.uploadedObjects = {
			
		queryObjectJsons : [],//contains the content of all query objects uploaded (json strings)
		queryObjectTitles : []//contains the titles of all query Objects uploaded
	};
	
	
	var queryObjectJsons = [];
	$scope.queryObjectTitles = [];
	//whenever a file is uploaded
	$scope.$watch('uploaded.QueryObject.filename', function(){
		
		if($scope.uploaded.QueryObject.filename)
			{
				//check if the file had been uploaded before
				if($.inArray($scope.uploaded.QueryObject.filename, $scope.uploadedObjects.queryObjectTitles) == -1)
					{
						//managing the title of queryObject (json )uploaded
						var title = $scope.uploaded.QueryObject.filename;
						$scope.uploadedObjects.queryObjectTitles.push(title);
						
						//managing the content of queryObject (json )uploaded
						var content = $scope.uploaded.QueryObject.content;
						$scope.uploadedObjects.queryObjectJsons.push(content);
						
						
						var countUploaded = $scope.uploadedObjects.queryObjectTitles.length;
						$scope.uploadStatus = countUploaded + " file(s) uploaded";
					}
			}
		
	});
	
	//called when save button is hit.;
	$scope.saveQueryObjects = function (projectNameEntered,projectDescriptionEntered, userNameEntered) {
		var additionParams = {
				projectNameEntered : projectNameEntered,
				userNameEntered :userNameEntered,
				projectDescriptionEntered : projectDescriptionEntered,
				uploadedObjects : $scope.uploadedObjects
		};
		
		console.log("being called");
		
		$scope.projectService.createNewProject(additionParams.userNameEntered,
											   additionParams.projectNameEntered,
											   additionParams.projectDescriptionEntered,
											   additionParams.uploadedObjects.queryObjectTitles,
											   additionParams.uploadedObjects.queryObjectJsons,
											null);
		
		 $modalInstance.close(additionParams);
	 };
	 
	 $scope.remove = function(file){
		 //removes the file from the uploaded collection
		 $scope.uploadedObjects.queryObjectTitles.splice($.inArray(file, $scope.uploadedObjects.queryObjectTitles), 1);
		 var countUploaded = $scope.uploadedObjects.queryObjectTitles.length;
		 $scope.uploadStatus = countUploaded + " file(s) uploaded";
		 if(countUploaded == 0)
			 $scope.uploadStatus = "";
	 };
});