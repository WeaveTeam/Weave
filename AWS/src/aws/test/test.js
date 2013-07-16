
goog.provide('aws.test');
goog.require('aws.RClient');

aws.test = function(){
	console.log('hi');
	aws.RClient.getConnectionObject('resd', ' ', function(result){ console.log(JSON.stringify(result, null, 3)); });
};
