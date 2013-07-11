/**
 * This function is a wrapper for making a sevlet request to the RService
 * 
 * @param {string} method The method name to be passed to the servlet
 * @param {Array:Object} params An array of object to be passed as parameters to the method 
 * @param {function} callback A callback function that handles the servlet response
 * 
 * @return void
 */
function queryRService(method,params,callback,queryID)
{
	var url = '/WeaveServices/RService';
	var request = {
					jsonrpc:"2.0",
					id:queryID || "no_id",
					method : method,
					params : params
	};
	$.post(url,request, callback, "json");
}
