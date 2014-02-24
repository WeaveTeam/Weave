goog.provide('aws');
goog.exportSymbol('aws', aws);

/**
 * 
 * @type {string} timeLogString the time log string.
 */
aws.timeLogString= "";

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
 * 	publicMetadata: object,
 *  privateMetadata: object
 *  }}
 */
aws.DataEntityMetadata;

/**
 * @typedef {*}
 */
aws.Visualization;

///** @typedef {{
// * 	  date: string, 
// *    author : string,
// *    conn : {sqldbname : string,
// *    		  scriptLocation : string,
// *    		  sqluser : string,
// *    		  sqlpass : string,
// *    		  serverType : string,
// *    	 	  sqlip : string,
// *    		  sqlport : string},
// *    		 
// *    scriptOptions : Array,
// *    scriptSelected : string,
// *    selectedVisualization : aws.Visualization,
// *    colorColumn : string,
// *    scriptType : string,
// *    maptool : Object,
// *    barchart : Object,
// *    datatable : Object
// *  }}
// * */
//aws.queryObject;
/**
 * @typedef {{
 * 	id: number,
 *  publicMetadata: Object,
 *  privateMetadata: Object
 * }}
 */
aws.DataEntity;

/**
 * @typedef{{
 *
 *		scriptName : string,
 * 		FilteredRequest : {
 * 			id: number,
 * 			filters: (Array.<string> | Array.<Array.<number>>)
 * 		}
 * }}
 */
aws.rDataRequestObject;

/**
 * Pointer to target window for RPC result.
 * Set this variable prior to calling queryService().
 * It will only affect one call to queryService().
 */
aws.window = window;

/**
 * This function is a wrapper for making a request to a JSON RPC servlet
 * 
 * @param {string} url
 * @param {string} method The method name to be passed to the servlet
 * @param {?Array|Object} params An array of object to be passed as parameters to the method 
 * @param {Function} resultHandler A callback function that handles the servlet result
 * @param {string|number=}queryId
 * @see aws.addBusyListener
 */
aws.queryService = function(url, method, params, resultHandler, queryId)
{
    var request = {
        jsonrpc: "2.0",
        id: queryId || "no_id",
        method: method,
        params: params
    };
    
    
    var targetWindow = aws.window;
    
    aws.window = window; // reset for next call to queryService()
    aws.activeQueryCount++;
    aws.broadcastBusyStatus();
    
    $.post(url, JSON.stringify(request), handleResponse, "text");

    function handleResponse(response)
    {
    	aws.activeQueryCount--;
    	aws.broadcastBusyStatus();
    	
    	// parse result for target window to use correct Array implementation
    	response = targetWindow.JSON.parse(response);
    	
        if (response.error)
        {
        	console.log(JSON.stringify(response, null, 3));
        }
        else if (resultHandler){
            return resultHandler(response.result, queryId);
        }
    }
};

/**
 * Makes a batch request to a JSON RPC 2.0 service. This function requires jQuery for the $.post() functionality.
 * @param {string} url The URL of the service.
 * @param {string} method Name of the method to call on the server for each entry in the queryIdToParams mapping.
 * @param {Array|Object} queryIdToParams A mapping from queryId to RPC parameters.
 * @param {function(Array|Object)} resultsHandler Receives a mapping from queryId to RPC result.
 */
aws.bulkQueryService = function(url, method, queryIdToParams, resultsHandler)
{
	var batch = [];
	for (var queryId in queryIdToParams)
		batch.push({jsonrpc: "2.0", id: queryId, method: method, params: queryIdToParams[queryId]});
	$.post(url, JSON.stringify(batch), handleBatch, "json");
	function handleBatch(batchResponse)
	{
		var results = Array.isArray(queryIdToParams) ? [] : {};
		for (var i in batchResponse)
		{
			var response = batchResponse[i];
			if (response.error)
				console.log(JSON.stringify(response, null, 3));
			else
				results[response.id] = response.result;
		}
		if (resultsHandler)
			resultsHandler(results);
	}
};

/**
 * @see aws.queryService
 * @see aws.addBusyListener
 * @private
 * @type {number}
 */
aws.activeQueryCount = 0;

/**
 * @see aws.queryService
 * @see aws.addBusyListener
 * @private
 * @type {Array.<function(number)>}
 */
aws.rpcBusyListeners = [];

/**
 * @see aws.queryService
 * @see aws.addBusyListener
 * @private
 */
aws.broadcastBusyStatus = function()
{
	aws.rpcBusyListeners.forEach(function(listener){ listener(aws.activeQueryCount); });
};

/**
 * Adds a listener that will receive a number corresponding to the number of active RPC calls.
 * @param {function(number)} callback Receives a number corresponding to the number of active RPC calls.
 * @return {void}
 * @see aws.queryService
 */
aws.addBusyListener = function(callback)
{
	aws.rpcBusyListeners.push(callback);
};