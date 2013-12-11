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
 * @param {number} columnId The column Id
 * @param {number} minParam
 * @param {number} maxParam
 * @param {Array.<string>} sqlParams
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
 * @param {Object} varValues Either an Array of value-label pairs or a column identifier in one of three formats:
 *   1. An integer for a column entity id (used by the admin console);
 *   2. An Object containing metadata fields that uniquely identify the column; and
 *   3. A String which specifies the value for a single predefined metadata field (aws_id) which uniquely identifies a column.
 * @param {function(Array.<Object>)} A callback which receives the data mapping.
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
