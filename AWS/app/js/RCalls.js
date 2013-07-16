'use strict';

/* RCalls */

var user = 'resd';//should be put in through UI
var passwd = 'esdresdr1';
// Demonstrate how to register services
// In this case it is a simple value service.
function DialogCtrl($scope){
	$scope.callingR = function()
	{
		aws.client.RClient.getConnectionObject(user,passwd,storeConnection);
	};
}

 
