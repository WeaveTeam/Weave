/**
 * contains all the functions required for project management 
 */
angular.module('aws.project')
.service('projectService', ['$q', '$rootScope', 'WeaveService', 'QueryHandlerService', 'runQueryService', 'projectManagementURL',
                            function($q, scope, WeaveService, QueryHandlerService, runQueryService, projectManagementURL){
	
	var that = this;
	
	this.cache= {
			dataTable: "",
			listOfProjectsFromDatabase : [],
			returnedQueryObjects : [],
			columnstring : "", 
			projectDescription : "", 
			userName : "", 
			weaveSessionState : "",
			deleteProjectStatus : null, 
			deleteQueryObjectStatus : null, 
			insertQueryObjectStatus : null 
	};

	
	
	/**
     * This function wraps the async aws getListOfProjects function into an angular defer/promise
     * So that the UI asynchronously wait for the data to be available...
     */
   
    this.getListOfProjects = function() {
    	var deferred = $q.defer();
    	runQueryService.queryRequest(projectManagementURL, 'getProjectListFromDatabase', null, function(result){
			that.cache.listOfProjectsFromDatabase = result;
        
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
    	runQueryService.queryRequest(projectManagementURL, 'getListOfQueryObjects', [projectName], function(AWSQueryObjectCollection){
    		that.cache.returnedQueryObjects = [];
    		if(!(angular.isUndefined(AWSQueryObjectCollection)))
    			{    			
        			var countOfJsons = AWSQueryObjectCollection.length;
        			for(var i = 0; i < countOfJsons; i++)
        			{
        				var singleObject= {};
        				singleObject.queryObject = JSON.parse(AWSQueryObjectCollection[i].finalQueryObject);
        				singleObject.queryObjectName = AWSQueryObjectCollection[i].queryObjectName;
        				singleObject.projectDescription = AWSQueryObjectCollection[i].projectDescription;
        				that.cache.projectDescription = AWSQueryObjectCollection[i].projectDescription;
        				if(angular.isUndefined(AWSQueryObjectCollection[i].thumbnail)){
        					singleObject.thumbnail = undefined;
        					console.log("This queryObject does not contain any stored visualizations");
        				}
        				else{
        					
        					singleObject.thumbnail = "data:image/png;base64," + AWSQueryObjectCollection[i].thumbnail;
        				}
        				
        				
        				that.cache.columnstring = "";
        				var columns = singleObject.queryObject.scriptOptions;
        				for(var j in columns){
        					var title = columns[j].title;
        					that.cache.columnstring= that.cache.columnstring.concat(title) + " , ";
        				}
        				singleObject.columnstring = that.cache.columnstring.slice(0,-2);//getting rid of the last comma
        				that.cache.returnedQueryObjects[i] = singleObject;
        			}
        			
    			}else{
    				that.dataTable = "";
    				that.cache.projectDescription = "";
    				that.cache.userName = "";
    			}
    		
	    		scope.$safeApply(function() {
	                deferred.resolve(AWSQueryObjectCollection);
	            });
        	
        });
    	
    	return deferred.promise;
    };
    
    var newWeave;
    
    /**
     * this function returns the session state corresponding to the thumbnail that was clicked
     */
    this.returnSessionState = function(queryObject){
   	 var deferred = $q.defer();
   	 queryObject = angular.toJson(queryObject);
   	 console.log("stringified queryObject", queryObject);
   	 runQueryService.queryRequest(projectManagementURL, 'getSessionState', [queryObject], function(result){
    		
   		 that.cache.weaveSessionState = result;
   		 
   		if(!(angular.isUndefined(that.data.weaveSessionState))){
   		 if (!newWeave || newWeave.closed) {
				newWeave = window
						.open("/weave.html?",
								"abc",
								"toolbar=no, fullscreen = no, scrollbars=yes, addressbar=no, resizable=yes");
				//WeaveService.setSessionHistory(that.data.weaveSessionState);
			}
   		 
   		QueryHandlerService.waitForWeave(newWeave, function(weave) {
			WeaveService.weave = weave;
			WeaveService.setSessionHistory(that.data.weaveSessionState);
		});
   		 //newWeave.logvar = "Displaying Visualizations";
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
   	runQueryService.queryRequest(projectManagementURL, 'deleteProjectFromDatabase', [projectName], function(result){
           
       	that.cache.deleteProjectStatus = result;//returns an integer telling us the number of row(s) deleted
       	
      	 if(! (that.cache.deleteProjectStatus == 0 )){
      		 
      		that.cache.returnedQueryObjects = [];//reset
      		that.cache.projectDescription = "";
      		 alert("The Project " + projectName + " has been deleted");
      		 that.getListOfProjects();//call the updated projects list
      	 }
      	 
      	 that.cache.deleteProjectStatus = 0;//reset 
       	
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
	   runQueryService.queryRequest(projectManagementURL, 'deleteQueryObjectFromProject', [projectName, queryObjectTitle], function(result){
	       	that.cache.deleteQueryObjectStatus = result;
	       	console.log("in the service",that.cache.deleteQueryObjectStatus );
	       	
	       	alert("Query Object " + queryObjectTitle + " has been deleted");
	       	
	       	that.cache.returnedQueryObjects = [];//clears list
	       	
	       	that.getListOfQueryObjects(projectName);//fetches new list
	       	
	       	//if the project contained only one QO which was deleted , retrive the new updated lists of projects
	       	if(that.cache.returnedQueryObjects.length == 0){
	       		
	       		that.getListOfProjects();
	       		
	       		that.cache.dataTable = "";
	       	}
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
   this.insertQueryObjectToProject = function(userName, projectName, projectDescription,queryObjectTitles,queryObjectJsons, resultVisualizations){
 
   	var deferred = $q.defer();

   	runQueryService.queryRequest(projectManagementURL, 'insertMultipleQueryObjectInProjectFromDatabase', [userName,
   	                                                                                          projectName,
   	                                                                                          projectDescription,
   	                                                                                          queryObjectTitles,
   	                                                                                          queryObjectJsons,
   	                                                                                          resultVisualizations], function(result){
   		that.cache.insertQueryObjectStatus = result;//returns an integer telling us the number of row(s) added
       	console.log("insertQueryObjectStatus", that.cache.insertQueryObjectStatus);
       	if(that.cache.insertQueryObjectStatus != 0){
       		alert(that.cache.insertQueryObjectStatus + " Query Object(s)" +  " have been added to project:" + projectName);
       	}
       	
       	scope.$safeApply(function() {
               deferred.resolve(result);
           });
       	
       });
       
       return deferred.promise;
       
   };
   
   this.createNewProject = function(userNameEntered, projectNameEntered,projectDescriptionEntered, queryObjectTitles, queryObjectJsons){
	   that.insertQueryObjectToProject(userNameEntered,
			   						   projectNameEntered,
			   						   projectDescriptionEntered,
			   						   queryObjectTitles,
			   						   queryObjectJsons,
			   						   null)
	   .then(function(){
		   that.cache.listOfProjectsFromDatabase = [];//clear
		   that.getListOfProjects();//fetch new list
	   });

   };
   
}]);
