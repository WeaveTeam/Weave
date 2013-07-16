goog.provide('aws.client.DataClient');

goog.require('aws.client');

var dataServiceURL = '/WeaveServices/DataService';

/**
 * This function mirrors the getEntityHierarchyInfo on the servlet.
 * 
 * @param {function(Array.<aws.client.EntityHierarchyInfo>)} handleResult
 */
aws.client.DataClient.getDataTableList = function(handleResult) {
	aws.client.queryService(dataServiceURL, "getDataTableList", null, handleResult);
};

	
/**
 * This function mirrors the getEntityChildIds on the servlet.
 * 
 * @param {number} id The parent id.
 * @param {function(Array.<number>)} handleResult
 */
aws.client.DataClient.getEntityChildIds = function(id, handleResult) {
	aws.client.queryService(dataServiceURL, "getEntityChildIds", [id], handleResult);
};

/**
 * This function mirrors the getEntitiesById on the servlet.
 * 
 * @param {Array.<number>} ids An array of ids
 * @param {function(Array.<Object>)} handleResult
 */
aws.client.DataClient.getDataColumnEntities = function(ids, handleResult) {
	aws.client.queryService(dataServiceURL, "getEntitiesById", [ids], handleResult);	
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
aws.client.DataClient.getColumn = function(columnId, minParam, maxParam, sqlParams, handleResult) {
	aws.client.queryService(dataServiceURL, "getColumn", [columnId, minParam, maxParam, sqlParams], handleResult);	
};


