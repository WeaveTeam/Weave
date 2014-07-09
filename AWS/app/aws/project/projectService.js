/**
 * contains all the functions required for project management 
 */

var projectManagementURL = '/WeaveAnalystServices/ProjectManagementServlet';

angular.module('aws.project').service('projectService', ['$q', '$rootScope', function($q, scope){
	
	var that = this;
	this.data= {};
	this.data.projectSelectorUI;//for state preservation between tabs
	/**
     * This function wraps the async aws getListOfProjects function into an angular defer/promise
     * So that the UI asynchronously wait for the data to be available...
     */
   
    this.getListOfProjects = function() {
    	var deferred = $q.defer();
		aws.queryService(projectManagementURL, 'getProjectListFromDatabase', null, function(result){
			that.data.listOfProjectsFromDatabase = result;
        
			scope.$safeApply(function() {
				deferred.resolve(result);
			});
		
		});
    };

    /**
     * This function wraps the async aws getQueryObjectsInProject function into an angular defer/promise
     * So that the UI asynchronously wait for the data to be available...
     */
    this.getListOfQueryObjects = function(projectName) {
    	var deferred = $q.defer();
    	var params = {};
    	params.projectName = projectName;
    	aws.queryService(projectManagementURL, 'getListOfQueryObjects', [params], function(AWSQueryObjectCollection){
    		that.data.returnedQueryObjects = [];
    		if(!(angular.isUndefined(AWSQueryObjectCollection)))
    			{    			
        			var countOfJsons = AWSQueryObjectCollection.length;
        			for(var i = 0; i < countOfJsons; i++)
        			{
        				var singleObject = {};
        				singleObject.queryObject = JSON.parse(AWSQueryObjectCollection[i].finalQueryObject);
        				singleObject.queryObjectName = AWSQueryObjectCollection[i].queryObjectName;
        				singleObject.projectDescription = AWSQueryObjectCollection[i].projectDescription;
        				that.data.projectDescription = AWSQueryObjectCollection[i].projectDescription;
        				if(angular.isUndefined(AWSQueryObjectCollection[i].thumbnail)){
        					singleObject.thumbnail = undefined;
        					console.log("This queryObject does not contain any stored visualizations");
        				}
        				else{
        					
        					singleObject.thumbnail = "data:image/png;base64," + AWSQueryObjectCollection[i].thumbnail;
        				}
        				
        				
        				that.data.columnstring = "";
        				var columns = singleObject.queryObject.ScriptColumnRequest;
        				for(var j in columns){
        					var title = columns[j].title;
        					that.data.columnstring= that.data.columnstring.concat(title) + " , ";
        				}
        				singleObject.columnstring = that.data.columnstring.slice(0,-2);//getting rid of the last comma
        				that.data.returnedQueryObjects[i] = singleObject;
        			}
        			
    			}
    		
	    		scope.$safeApply(function() {
	                deferred.resolve(AWSQueryObjectCollection);
	            });
        	
        });
    };
    
    var newWeave;
    
    /**
     * this function returns the session state corresponding to the thumbnail that was clicked
     */
    this.returnSessionState = function(queryObject){
   	 var deferred = $q.defer();
   	 queryObject = angular.toJson(queryObject);
   	 console.log("stringified queryObject", queryObject);
   	 aws.queryService(projectManagementURL, 'returnSessionState', [queryObject], function(result){
    		
   		 that.data.weaveSessionState = result;
   		 
   		if(!(angular.isUndefined(that.data.weaveSessionState))){
   		 if (!newWeave || newWeave.closed) {
				newWeave = window
						.open("aws/visualization/weave/weave.html",
								"abc",
								"toolbar=no, fullscreen = no, scrollbars=yes, addressbar=no, resizable=yes");
				newWeave.setSession = that.data.weaveSessionState;
			}
   		 else{
   			 newWeave.setSessionHistory(that.data.weaveSessionState);
   		 }
   		 newWeave.logvar = "Displaying Visualizations";
   		}
   		 
        	scope.$safeApply(function() {
                deferred.resolve(result);
            });
        	
        });
    		
  
		return deferred.promise;
   };
   
   	//as soon as service returns deleteStatus
	//1. report status
	//2. reset required variables
	//3. updates required lists
   /**
    * This function wraps the async aws deleteproject function into an angular defer/promise
    * So that the UI asynchronously wait for the data to be available...
    */
   this.deleteProject = function(projectName) {
    console.log("currently selectec project", projectName);
   	var deferred = $q.defer();
   	var params = {};
   	params.projectName = projectName;

   	aws.queryService(projectManagementURL, 'deleteProjectFromDatabase', [params], function(result){
       	console.log("deleteProjectStatus", result);
           
       	that.data.deleteProjectStatus = result;//returns an integer telling us the number of row(s) deleted
       	
      	 if(! (that.data.deleteProjectStatus == 0 )){
      		 
      		that.data.returnedQueryObjects = [];//reset
      		that.data.projectDescription = "";
      		 alert("The Project " + projectName + " has been deleted");
      		 that.getListOfProjects();//call the updated projects list
      	 }
      	 
      	 that.data.deleteProjectStatus = 0;//reset 
       	
       	scope.$safeApply(function() {
               deferred.resolve(result);
           });
       	
       });
       
       return deferred.promise;
       
   };
   
   /**
    * This function wraps the async aws deleteQueryObject function into an angular defer/promise
    * So that the UI asynchronously wait for the data to be available...
    */
   this.deleteQueryObject = function(projectName, queryObjectTitle){
	   var deferred = $q.defer();
	   	var params = {};
	   	params.projectName = projectName;
	   	params.queryObjectTitle = queryObjectTitle;
	   
		aws.queryService(projectManagementURL, 'deleteQueryObjectFromProject', [params], function(result){
	       	that.data.deleteQueryObjectStatus = result;
	       	console.log("in the service",that.data.deleteQueryObjectStatus );
	       	
	       	alert("Query Object " + queryObjectTitle + " has been deleted");
	       	
	       	that.data.returnedQueryObjects = [];//clears list
	       	
	       	that.getListOfQueryObjects(projectName);//fetches new list
	       	
	       	
	       	scope.$safeApply(function() {
	               deferred.resolve(result);
	           });
	       	
	       });
	       
	       return deferred.promise;
   };
   
   /**
    * This function wraps the async aws insertQueryObjectToProject function into an angular defer/promise
    * adds a query object (row) to the specified project in the database
    * So that the UI asynchronously wait for the data to be available...
    */
   this.insertQueryObjectToProject = function(userName, projectName,projectDescription, queryObjectTitle, queryObjectContent) {
     	
   	var deferred = $q.defer();
   	var params = {};
   	params.userName = userName;
   	params.projectName = projectName;
   	params.projectDescription = projectDescription;
   	params.queryObjectTitle = queryObjectTitle;
   	params.queryObjectContent = queryObjectContent;

   	aws.queryService(projectManagementURL, 'insertMultipleQueryObjectInProjectFromDatabase', [params], function(result){
   		that.data.insertQueryObjectStatus = result;//returns an integer telling us the number of row(s) added
       	console.log("insertQueryObjectStatus", that.data.insertQueryObjectStatus);
       	if(that.data.insertQueryObjectStatus != 0){
       		alert("Query Object" + queryObjectTitle+ " has been added to project:" + projectName);
       	}
       	
       	scope.$safeApply(function() {
               deferred.resolve(result);
           });
       	
       });
       
       return [deferred.promise, that.data.insertQueryObjectStatus] ;
       
   };
   
//   $scope.$watch(function(){
//    	return queryService.dataObject.insertQueryObjectStatus;
//     }, function(){ 
//    	 $scope.insertQueryObjectStatus = queryService.dataObject.insertQueryObjectStatus;
//    	if(!(angular.isUndefined($scope.insertQueryObjectStatus)))
//		 {
//		 	if($scope.insertQueryObjectStatus != 0)
//		 		{
//   		 		alert("Query Object has been added");
//   		 		queryService.dataObject.listofQueryObjectsInProject = [];
//	    			queryService.getListOfQueryObjectsInProject($scope.projectSelectorUI);//makes a new call
//		 		}
//		 }
//	 
//    	queryService.dataObject.insertQueryObjectStatus = 0;//reset
//     });
   
}]);
