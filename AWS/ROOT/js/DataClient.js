/**
 * This function is a wrapper for making a sevlet request to the DataService
 * 
 * @param {string} method The method name to be passed to the servlet
 * @param {Array:Object} params An array of object to be passed as parameters to the method 
 * @param {function} callback A callback function that handles the servlet response
 * 
 * @return void
 */
function queryDataService(method, params, callback)
{
	var url = '/WeaveServices/DataService';
	var request = {
	               jsonrpc:"2.0",
	               id:"no_id",
	               method : method,
	               params : params
	};
	
	$.post(url, JSON.stringify(request), callback, "json");
}


/**
 * This function is a wrapper for making a sevlet request to the AdminService
 * 
 * @param {string} method The method name to be passed to the servlet
 * @param {Array:Object} params An array of object to be passed as parameters to the method 
 * @param {function} callback A callback function that handles the servlet response
 * 
 * @return void
 */
function queryAdminService(method, params, callback)
{
	var url = '/WeaveServices/AdminService';
	var request = {
	               jsonrpc:"2.0",
	               id:"no_id",
	               method : method,
	               params : params
	};
	
	$.post(url, JSON.stringify(request), callback, "json");
}

/**
 * This function mirrors the getEntityHierarchyInfo on the servlet.
 * 
 * @param {string} connectionName The connection name to authenticate on the database
 * @param {string} password The password to authenticate on the database 
 * @param {int} entityType The entityType
 *  
 * @return {EntityHieraryInfo} An array of EntityHierarchyInfo
 */
function getEntityHierarchyInfo(connection, password, entityType) {
	
	var EntityHierarchyInfo = [];
	
	queryAdminService("getEntityHierarchyInfo", [connection, password, entityType], handleResponse);
	
	function handleResponse(response){

		if(response.error)	
			alert("connection failed"); // TODO change this to a better error handling mechanism
	
		else
		{
			EntityHierarchyInfo = response.result;
		}
	 }
	
	 return EntityHierarchyInfo;
}

/**
 * This function mirrors the getColumn on the servlet.
 * 
 * @param {string} user The username for the connection
 * @param {string} password The password for the connection
 *  
 * @return {Object} ConnectionInfo
 */
function getConnectionInfo(user, password) {
	
	var connectionInfo = {};
	
	queryAdminService("getConnectionInfo", [user, password], handleResponse);
	
	function handleResponse(response){
		
		if (response.error) {
			alert("connection failed"); // TODO change this to a better error handling mechanism
		}
		else{
			connectionInfo = response.result;
		}
		
		return connectionInfo;
	}	
	
}
		
/**
 * This function mirrors the getEntityChildIds on the servlet.
 * 
 * @param {int} id The parent id.
 *  
 * @return {Array:int} An array of child ids.
 */
function getEntityChildIds(id) {
	
	var childIds = [];

	queryDataService("getEntityChildIds", [id], handleResponse);
	
	function handleResponse(response){

		if(response.error)	
			alert("connection failed"); // TODO change this to a better error handling mechanism
	
		else
		{
			childIds = response.result;
		}
	 }
	
	 return childIds;
}

/**
 * This function mirrors the getEntitiesById on the servlet.
 * 
 * @param {Array:int} ids An array of ids
 *  
 * @return {Array:Object} An array of DataEntity
 */
function getDataColumnEntities(ids) {
	
	var DataEntity = [];
	
	queryDataService("getEntitiesById", [ids], handleResponse);	
	
	function handleResponse(response){

		if(response.error)	
			alert("connection failed"); // TODO change this to a better error handling mechanism
	
		else
		{
			DataEntity = response.result;
		}
	 }
	
	 return DataEntity;
}

/**
 * This function mirrors the getColumn on the servlet.
 * 
 * @param {int} ColumnId The column Id
 * @param {Number} minParam
 * @param {Number} maxParam
 * @param {Array:string} sqlParams
 *  
 * @return {Object} AttributeColumnData
 */
function getColumn(columnId, minParam, maxParam, sqlParams) {
	
	var AttributeColumnData = {};
	
	queryDataService("getColumn", [columnId, minParam, maxParam, sqlParams], handleResponse);	
	
	function handleResponse(response){

		if(response.error)	
			alert("connection failed"); // TODO change this to a better error handling mechanism
	
		else
		{
			AttributeColumnData = response.result;
		}
	 }
	
	 return AttributeColumnData;
}


