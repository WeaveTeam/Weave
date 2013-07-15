angular.module('myApp.dataClient', [])
.controller('DataClientCtrl', function($scope, $http, dialog){


/************************Implementation functions*****************/
$scope.close = function(result){
    dialog.close(result);
 };

$scope.connect = function(){
    console.log("entered connect fcn");
    $scope.getDataTableList(function(result){
    
    	console.log(result);
 	});
/*    for(var i in res){
    	var table = res[i];
		$('#dataTables').append($("<option/>").val(table.id.toString()).text(table.title + " (" + table.numChildren + ")"));
		//appending this table of results to the data table selector
	}*/
   

    
};

/*****************************************************************/

var dataServiceURL = '/WeaveServices/DataService';

$scope.handleResponse = function(response)
    {
    	console.log("handleResponse fcn");
        if (response.error)
            alert(JSON.stringify(response, null, 3));
        else if (resultHandler)
            resultHandler(response.result, queryId);
    }

/**
 * This function is a wrapper for making a request to a JSON RPC servlet
 * 
 * @param {string} url
 * @param {string} method The method name to be passed to the servlet
 * @param {Array.<Object>} params An array of object to be passed as parameters to the method 
 * @param {Function} resultHandler A callback function that handles the servlet result
 * @param {number=}queryId
 */
$scope.queryService = function(url, method, params, resultHandler, queryId)
{
	console.log("entered queryService fcn");
    var request = {
        jsonrpc: "2.0",
        id: queryId || "no_id",
        method: method,
        params: params
    };
    console.log(request, $scope.handleResponse);
    $.post(url, JSON.stringify(request), $scope.handleResponse, "json");

    
};

/**
 * This function mirrors the getEntityHierarchyInfo on the servlet.
 * 
 * @param {function(Array.<aws.client.EntityHierarchyInfo>)} handleResult
 */
$scope.getDataTableList = function(handleResult) {
	console.log("enteredDataTableList fcn");
	$scope.queryService(dataServiceURL, "getDataTableList", null, handleResult);
};

	
/**
 * This function mirrors the getEntityChildIds on the servlet.
 * 
 * @param {number} id The parent id.
 * @param {function(Array.<number>)} handleResult
 */
$scope.getEntityChildIds = function(id, handleResult) {
	$scope.queryService(dataServiceURL, "getEntityChildIds", [id], handleResult);
};

/**
 * This function mirrors the getEntitiesById on the servlet.
 * 
 * @param {Array.<number>} ids An array of ids
 * @param {function(Array.<Object>)} handleResult
 */
$scope.getDataColumnEntities = function(ids, handleResult) {
	$scope.queryService(dataServiceURL, "getEntitiesById", [ids], handleResult);	
};

/**
 * This function mirrors the getColumn on the servlet.
 * 
 * @param {number} columnId The column Id
 * @param {number} minParam
 * @param {number} maxParam
 * @param {Array.<string>} sqlParams
 * @param {function(Object)} handleResult
 */
$scope.getColumn = function(columnId, minParam, maxParam, sqlParams, handleResult) {
	$scope.queryService(dataServiceURL, "getColumn", [columnId, minParam, maxParam, sqlParams], handleResult);	
};

});