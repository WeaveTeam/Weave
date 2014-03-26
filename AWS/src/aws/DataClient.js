goog.provide('aws.DataClient');

goog.require('aws');

var dataServiceURL = '/WeaveServices/DataService';

/**
 * This function mirrors the getEntityHierarchyInfo on the servlet.
 * 
 * @param {function(Array.<aws.EntityHierarchyInfo>)} handleResult
 */
aws.DataClient.getDataTableList = function(handleResult) {
	aws.queryService(dataServiceURL, "getDataTableList", null, handleResult);
};
	
/**
 * This function mirrors the getEntityChildIds on the servlet.
 * 
 * @param {number} id The parent id.
 * @param {function(Array.<number>)} handleResult
 */
aws.DataClient.getEntityChildIds = function(id, handleResult) {
	aws.queryService(dataServiceURL, "getEntityChildIds", [id], handleResult);
};


/**
 * This function calls the getListOfProjects function on the servlet
 * it will get the list of files in the directory
 * @param {Function} callback callback function
 */
aws.DataClient.getListOfProjects = function(callback) {
	aws.queryService(rServiceURL, 'getListOfProjects', null, callback);
};

aws.DataClient.getListOfProjectsFromDatabase = function(callback) {
	aws.queryService(rServiceURL, "getProjectFromDatabase", null,  callback);
};


//aws.DataClient.getListOfQueryObjects = function(projectName, callback){
//	aws.queryService(rServiceURL, 'getQueryObjectsInProject', [projectName], callback);
//};

aws.DataClient.getListOfQueryObjects = function(projectName, callback){
	aws.queryService(rServiceURL, 'getQueryObjectsFromDatabase', [projectName], callback);
};



aws.DataClient.deleteProject = function(projectName, callback){
	aws.queryService(rServiceURL, 'deleteProjectFromDatabase',[projectName], callback );
};

aws.DataClient.deleteQueryObject = function(projectName, queryObjectTitle, callback){
	aws.queryService(rServiceURL, 'deleteQueryObjectFromProjectFromDatabase',[projectName, queryObjectTitle], callback );
};

aws.DataClient.insertQueryObject= function(userName, projectName,projectDescription, queryObjectTitle, queryObjectContent, callback){
	aws.queryService(rServiceURL, "insertMultipleQueryObjectInProjectFromDatabase", [userName, projectName, projectDescription, queryObjectTitle, queryObjectContent], callback);
};
/**
 * This function mirrors the getEntitiesById on the servlet.
 * 
 * @param {Array.<number>} ids An array of ids
 * @param {function(Array.<Object>)} handleResult
 */
aws.DataClient.getDataColumnEntities = function(ids, handleResult) {
	aws.queryService(dataServiceURL, "getEntitiesById", [ids], handleResult);	
};

/**
 * This function mirrors the getColumn on the servlet.
 * 
 * @param {number|Object} columnId A column entity ID or a set of public metadata that uniquely identifies a column
 * @param {number} minParam Used for filtering numeric data
 * @param {number} maxParam Used for filtering numeric data
 * @param {Array.<string>} sqlParams Parameters for '?' placeholders in the column's SQL query
 * @param {function(Object)} handleResult
 */
aws.DataClient.getColumn = function(columnId, minParam, maxParam, sqlParams, handleResult) {
	aws.queryService(dataServiceURL, "getColumn", [columnId, minParam, maxParam, sqlParams], handleResult);	
};

/**
 * @param {Object} meta
 * @param {function(Object)} handleResult
 */
aws.DataClient.getEntityIdsByMetadata = function(meta, handleResult){
	// Assuming we want a column back, the dataEntity Type should be 1.
	aws.queryService(dataServiceURL, "getEntityIdsByMetadata", [meta, 1], handleResult);
};

/**
 * Accepts a varValues property from an aws_metadata object and passes the corresponding data mapping to a callback function.
 * @param {number|string|Object|Array.<Object>} varValues Either an Array of value-label pairs or a column identifier in one of three formats:
 *   1. An integer for a column entity id (used by the admin console);
 *   2. An Object containing metadata fields that uniquely identify the column; and
 *   3. A String which specifies the value for a single predefined metadata field (aws_id) which uniquely identifies a column.
 * @param {function(Array.<Object>)} callback A callback which receives the data mapping.
 */
aws.DataClient.getDataMapping = function(varValues, callback)
{
	if (Array.isArray(varValues))
	{
		setTimeout(function(){ callback(varValues); }, 0);
		return;
	}
	
	if (typeof varValues == 'string')
		varValues = {"aws_id": varValues};
	
	aws.queryService(
		dataServiceURL,
		'getColumn',
		[varValues, NaN, NaN, null],
		function(columnData) {
			var result = [];
			for (var i in columnData.keys)
				result[i] = {"value": columnData.keys[i], "label": columnData.data[i]};
			callback(result);
		}
	);
};

/**
 * This function mirrors the getColumn on the servlet.
 * 
 * @param {number|Object} columnId A column entity ID or a set of public metadata that uniquely identifies a column
 * @param {number} minParam Used for filtering numeric data
 * @param {number} maxParam Used for filtering numeric data
 * @param {Array.<string>} sqlParams Parameters for '?' placeholders in the column's SQL query
 * @param {function(Object)} handleResult
 */
aws.DataClient.getColumn = function(columnId, minParam, maxParam, sqlParams, handleResult) {
	aws.queryService(dataServiceURL, "getColumn", [columnId, minParam, maxParam, sqlParams], handleResult);	
};


aws.DataClient.getColumnsFromIds = function(ids, handleResult) {
	aws.bulkQueryService(dataServiceURL, "getColumn", ids.map(function(id) { return [id, null, null, null];}), handleResult);
};

aws.DataClient.getColumnsFromTableId = function(id, handleResult) {
	aws.DataClient.getEntityChildIds(id, function(ids) { aws.DataClient.getColumnsFromIds(ids, handleResult);});
};

/**
 * @param {Object} meta
 * @param {function(Object)} handleResult
 */
aws.DataClient.getEntityIdsByMetadata = function(meta, handleResult){
	aws.queryService(dataServiceURL, "getEntityIdsByMetadata", [meta, 1], handleResult);
};

/**
 * This function will return a dataset, given a list of entity ids
 * @param {Array.<number>} ids Array of ids
 * 
 * @param {function(Array.<Object>)} callback A callback which receives the data mapping.
 */
aws.DataClient.getDataSet = function(ids, callback)
{
	aws.queryService(dataServiceURL, "getDataSet", [ids], callback);
};

/**
 * This function will return a dataset, given a single table entity id.
 * @param {number} id table id
 * 
 * @param {function(Array.<Object>)} callback A callback which receives the data mapping.
 */
aws.DataClient.getDataSetFromTableId = function(id, callback)
{
	aws.DataClient.getEntityChildIds(id, function(ids) {
		aws.DataClient.getDataSet(ids, callback);
	});
};
