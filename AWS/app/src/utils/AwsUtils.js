var aws = {};

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
    
    $.post(url, JSON.stringify(request), handleResponse, "text");

    function handleResponse(response)
    {
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

var tryParseJSON = function(jsonString){
    try {
        var o = JSON.parse(jsonString);

        // Handle non-exception-throwing cases:
        // Neither JSON.parse(false) or JSON.parse(1234) throw errors, hence the type-checking,
        // but... JSON.parse(null) returns 'null', and typeof null === "object", 
        // so we must check for that, too.
        if (o && typeof o === "object" && o !== null) {
            return o;
        }
    }
    catch (e) { }

    return false;
};

var CSVToArray = function(strData, strDelimiter) {
    // Check to see if the delimiter is defined. If not,
    // then default to comma.
    strDelimiter = (strDelimiter || ",");
    // Create a regular expression to parse the CSV values.
    var objPattern = new RegExp((
    // Delimiters.
    "(\\" + strDelimiter + "|\\r?\\n|\\r|^)" +
    // Quoted fields.
    "(?:\"([^\"]*(?:\"\"[^\"]*)*)\"|" +
    // Standard fields.
    "([^\"\\" + strDelimiter + "\\r\\n]*))"), "gi");
    // Create an array to hold our data. Give the array
    // a default empty first row.
    var arrData = [[]];
    // Create an array to hold our individual pattern
    // matching groups.
    var arrMatches = null;
    // Keep looping over the regular expression matches
    // until we can no longer find a match.
    while (arrMatches = objPattern.exec(strData)) {
        // Get the delimiter that was found.
        var strMatchedDelimiter = arrMatches[1];
        // Check to see if the given delimiter has a length
        // (is not the start of string) and if it matches
        // field delimiter. If id does not, then we know
        // that this delimiter is a row delimiter.
        if (strMatchedDelimiter.length && (strMatchedDelimiter != strDelimiter)) {
            // Since we have reached a new row of data,
            // add an empty row to our data array.
            arrData.push([]);
        }
        // Now that we have our delimiter out of the way,
        // let's check to see which kind of value we
        // captured (quoted or unquoted).
        if (arrMatches[2]) {
            // We found a quoted value. When we capture
            // this value, unescape any double quotes.
            var strMatchedValue = arrMatches[2].replace(
            new RegExp("\"\"", "g"), "\"");
        } else {
            // We found a non-quoted value.
            var strMatchedValue = arrMatches[3];
        }
        // Now that we have our value string, let's add
        // it to the data array.
        arrData[arrData.length - 1].push(strMatchedValue);
    }
    // Return the parsed data.
    return (arrData);
};