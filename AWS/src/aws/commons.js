goog.provide('aws.client');

goog.exportSymbol('aws', aws);

/**
 * @typedef {{
 * 	name: string,
 *  pass: string,
 *  folderName: string,
 *  connectionString: string,
 *  is_superuser: boolean
 * }}
 */
aws.ConnectionInfo;

/**
 * @typedef {{
 * 	id: number,
 *  title: String,
 *  numChildren: number
 * }}
 */
aws.EntityHierarchyInfo;


/**
 * @typedef {{
 * 	id: number,
 *  publicMetadata: Object,
 *  privateMetadata: Object
 * }}
 */
aws.DataEntity;

/**
 * @typedef {{}}
 */
//aws.WeaveObject;

/**
 * @typedef {string}
 */
aws.Column;

/**
 * This function is a wrapper for making a request to a JSON RPC servlet
 * 
 * @param {string} url
 * @param {string} method The method name to be passed to the servlet
 * @param {?Array|Object} params An array of object to be passed as parameters to the method 
 * @param {Function} resultHandler A callback function that handles the servlet result
 * @param {string|number=}queryId
 */
aws.queryService = function(url, method, params, resultHandler, queryId)
{
    var request = {
        jsonrpc: "2.0",
        id: queryId || "no_id",
        method: method,
        params: params
    };
    
    $.post(url, JSON.stringify(request), handleResponse, "json");

    function handleResponse(response)
    {
        if (response.error)
            console.log(JSON.stringify(response, null, 3));
        else if (resultHandler)
            resultHandler(response.result, queryId);
    }
};

/**
 * returns the current time to the console
 */
aws.reportTime = function()
{
	Date.prototype.today = function(){ 
		return ((this.getDate() < 10)?"0":"") + this.getDate() +"/"+(((this.getMonth()+1) < 10)?"0":"") + (this.getMonth()+1) +"/"+ this.getFullYear(); 
	};
	//For the time now
	Date.prototype.timeNow = function(){
		return ((this.getHours() < 10)?"0":"") + this.getHours() +":"+ ((this.getMinutes() < 10)?"0":"") + this.getMinutes() +":"+ ((this.getSeconds() < 10)?"0":"") + this.getSeconds();
	};
	var currentTime = new Date();
	
	return "Current time :" + currentTime.today() + "@" + currentTime.timeNow();
	
};