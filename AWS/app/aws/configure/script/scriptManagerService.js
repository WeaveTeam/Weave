ScriptManager.service("scriptManagerService", ['$q', '$rootScope', function($q, scope) {
				
				this.dataObject = {};
				
				this.getListOfScripts = function() {
				        
					var that = this;
				    if(this.dataObject.listOfScripts) {
				    	return this.dataObject.listOfScripts;
				    }
				    	
				    	
				   	var deferred = $q.defer();

				       aws.RClient.getListOfScripts(function(result) {
				            
				        	that.dataObject.listOfScripts = result;
				        	
				        	// since this function executes async in a future turn of the event loop, we need to wrap
				            // our code into an $apply call so that the model changes are properly observed.
				        	scope.$apply(function() {
				                deferred.resolve(result);
				            });
				        	
				        });
				        
				        // regardless of when the promise was or will be resolved or rejected,
				        // then calls one of the success or error callbacks asynchronously as soon as the result
				        // is available. The callbacks are called with a single argument: the result or rejection reason.
				        return deferred.promise;
				        
				    };
			}]);