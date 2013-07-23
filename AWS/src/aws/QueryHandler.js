goog.provide('aws.QueryHandler');

goog.require('aws.client');
//will distribute the required data to the different clients(brokers)
//takes an object literal as an argument which is updated with ui interaction at runtime
var title; 
var dategenerated;
var creator;
//Rserve requirements
//data set to pull columns from
var computationEngine;//(either R or STATA)
var dataset = "";
//script to be run R, STATA
var computationScript;
var columnString;
var columns = columnString.split(",");//should we do this?
var scriptLocation;
//connection information
var host;
var user;
var password;
var schema;
//visualization parameters(map or array?)
var vizTools = [];
var vizParameters;

/**@constructor*/
function QueryHandler(queryObject)
{
	/**@type {string}*/
	this.title = queryObject.nameofqueryObject;
	this.dategenerated = queryObject.date;
	this.creator = queryObject.creator;
	this.computationEngine = queryObject.computationEngine;
	this.dataset = queryObject.dataset;
	this.computationScript = queryObject.scriptName;
	this.scriptLocation = queryObject.scriptPath;
	this.columnString = queryObject.listofColumns;
};


/*-------------------------------BROKER ARGUMENTS----------------------------------------------------------------------*/
var rDataObject = new Object();
rDataObject.dataset = dataset;
rDataObject.computationScript = computationScript;
rDataObject.columns = columns;
rDataObject.scriptLocation = scriptLocation;


var connObject = new Object();
connObject.host = host;
connObject.user = user;
connObject.password = password;
connObject.schema = schema;


/* ----------------------------INSTANTIATING THE CLIENTS------------------------------------------------------------------*/
var rBroker = new aws.Client.RClient(connObject, rDataObject);
//var vizBroker = new aws.Client.WeaveClient(weave);//need a pointer to the weave instance
var stataBroker = new aws.Client.StataClient();

rBroker.runScriptOnSQLdata();