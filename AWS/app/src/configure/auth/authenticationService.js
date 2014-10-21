/**
 * this service deals with login credentials
 */

var authenticationModule = angular.module('aws.configure.auth', []);
//experimenting with another kind of angular provider factory vs service (works!!)
authenticationModule
.factory('authenticationService',['$rootScope', 'runQueryService', 'adminServiceURL', function authenticationServiceFactory(scope, runQueryService, adminServiceURL){
	var authenticationService = {};
	authenticationService.user;
	authenticationService.password;
	authenticationService.authenticated = false;
	
	//make call to server to authenticate
	 authenticationService.authenticate = function(user, password){

		 runQueryService.queryRequest(adminServiceURL, 'authenticate', [user, password], function(result){
    		console.log("authenticated", result);
    		authenticationService.authenticated = result;
          //if accepted
            if(authenticationService.authenticated){
            	
            	authenticationService.user = user;
            	authenticationService.password = password;
            }
            scope.$apply();
        }.bind(authenticationService));
   };
//    
    authenticationService.logout = function(){
    	console.log("loggin out");
    	//resetting variables
    	authenticationService.authenticated = false;
    	authenticationService.user = "";
    	authenticationService.password = "";
    };
   
   return authenticationService;
	
}]);
