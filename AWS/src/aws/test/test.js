
goog.provide('aws.test');
goog.require('aws.RClient');

aws.test = function(){
	console.log('hi');
	aws.RClient.getConnectionObject('resd', ' ', function(result){ console.log(JSON.stringify(result, null, 3)); });
};


aws.stataTest = function(handleResult){
	console.log('stata says hi');
	aws.queryService("/WeaveServices/StataServlet", "SendScriptToStata", ["scriptName", ["option1"]], handleResult);
};