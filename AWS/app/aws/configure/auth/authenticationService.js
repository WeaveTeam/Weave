/**
 * this service deals with login credentials
 */

var authenticationModule = angular.module('aws.configure.auth', []);

authenticationModule.factory('authenticationService',['$rootScope', function authenticationServiceFactory(scope){
	var authenticationService = {};
	authenticationService.user;
	authenticationService.password;
	authenticationService.authenticated = false;
	
	//make call to server to authenticate
	 authenticationService.authenticate = function(user, password){

    	aws.queryService(adminServiceURL, 'authenticate', [user, password], function(result){
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
    	authenticationService.authenticated = false;
    };
   
   return authenticationService;
	
}]);
