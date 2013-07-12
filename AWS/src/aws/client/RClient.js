var dataServiceURL = '/WeaveServices/DataService';



/**
 *  This function mirrors the runScriptOnSQLServer function on the RService. It runs a script using R and fetching the data from the database.
 * 
 *  @param {Object} connectionInfo the connection info to allow R to connect to the database
 *  @param {string} script the Script to be ran.
 *  @param {Object} columns the columns to be fetched from the database.
 * 
 * @return {Object} RResult[]
 */
function runScriptOnSQLOnServer(connectionName, script, columns)
{
	queryRService('', [connectionName, script, columns], callback)

}