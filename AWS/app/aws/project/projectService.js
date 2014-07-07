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
   
    this.getListOfProjectsfromDatabase = function() {
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
        				var singleQueryObject = {};
        				singleQueryObject.finalQueryObject = JSON.parse(AWSQueryObjectCollection[i].finalQueryObject);
        				singleQueryObject.queryObjectName = AWSQueryObjectCollection[i].queryName;
        				singleQueryObject.projectDescription = AWSQueryObjectCollection[i].projectDescription;
        				that.data.projectDescription = AWSQueryObjectCollection[i].projectDescription;
        				singleQueryObject.thumbnail = "data:image/png;base64," + AWSQueryObjectCollection[i].thumbnail;
        				
        				
        				that.data.columnstring = "";
        				var columns = singleQueryObject.finalQueryObject.ScriptColumnRequest;
        				for(var j in columns){
        					var title = columns[j].title;
        					that.data.columnstring= that.data.columnstring.concat(title) + " , ";
        				}
        				singleQueryObject.columnstring = that.data.columnstring.slice(0,-2);//getting rid of the last comma
        				that.data.returnedQueryObjects[i] = singleQueryObject;
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
      		 
      		 that.data.completeObjects = [];
      		 alert("The Project " + projectName + " has been deleted");
      		 that.data.listOfProjectsFromDatabase = [];//reset and clean for next iteration
      		 that.data.listofQueryObjectsInProject = [];//clean list for the current project being deleted
      		 console.log("checking projectSelectorUI", that.data.projectSelectorUI);
      		 
      		 that.getListOfProjectsfromDatabase();//call the updated projects list
      	 }
      	 
      	 that.data.deleteProjectStatus = 0;//reset 
       	
       	
       	
       	scope.$safeApply(function() {
               deferred.resolve(result);
           });
       	
       });
       
       return deferred.promise;
       
   };
   
   
   
   
   
   
   
//   	 if(! ($scope.deleteProjectStatus == 0 || angular.isUndefined($scope.deleteProjectStatus)))
//   		 {
//   		 if(!($scope.currentProjectSelected != "" || angular.isUndefined($scope.currentProjectSelected)))
//   			 {
//	    			 alert("The Project " + $scope.currentProjectSelected + " has been deleted");
//	    			 queryService.dataObject.listOfProjectsFromDatabase = [];//emptying projects list
//	    			 queryService.dataObject.listofQueryObjectsInProject = [];//emptying queryObjects list
//	    			 $scope.projectSelectorUI = $scope.defaultProjectOption;//resetting dropDown UI
//	    			 $scope.currentProjectSelected = "";//reset
//	    			 queryService.getListOfProjectsfromDatabase();//fetch new list
//   			 }
//   		 	
//   		 }
//   	 
//	    	 queryService.dataObject.deleteProjectStatus = 0;
//   	
//    });
    
    
}]);
