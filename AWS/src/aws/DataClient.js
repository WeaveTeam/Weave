goog.provide('aws.DataClient');

goog.require('aws.client');

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


aws.DataClient.getEntityIdsByMetadata = function(meta, handleResult){
	meta = [meta, 1]; // Assuming we want a column back, the dataEntity Type should be 1.
	aws.queryService(dataServiceURL, "getEntityIdsByMetadata", meta, handleResult);
};

