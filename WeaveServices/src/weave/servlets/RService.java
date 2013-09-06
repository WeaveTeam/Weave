/*
    Weave (Web-based Analysis and Visualization Environment)
    Copyright (C) 2008-2011 University of Massachusetts Lowell

    This file is a part of Weave.

    Weave is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License, Version 3,
    as published by the Free Software Foundation.

    Weave is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Weave.  If not, see <http://www.gnu.org/licenses/>.
*/

package weave.servlets;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.File;
import java.io.InputStreamReader;
import java.rmi.RemoteException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.ListIterator;
import java.util.List;
import java.util.LinkedList;
import java.util.Map;
import java.util.Set;
import java.net.URI;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;

import com.google.gson.Gson;

import weave.beans.HierarchicalClusteringResult;
import weave.beans.LinearRegressionResult;
import weave.beans.RResult;
import weave.beans.RequestObject;
import weave.config.WeaveContextParams;
import weave.config.ConnectionConfig.ConnectionInfo;
import weave.utils.CommandUtils;
import weave.utils.DebugTimer;

import weave.utils.SQLUtils;


import weave.config.ConnectionConfig;
import weave.config.ConnectionConfig.ConnectionInfo;
import weave.config.DataConfig;
import weave.config.DataConfig.DataEntity;
import weave.config.DataConfig.DataEntityMetadata;
import weave.config.DataConfig.DataEntityWithChildren;
import weave.config.DataConfig.DataType;
import weave.config.DataConfig.EntityHierarchyInfo;
import weave.config.DataConfig.PrivateMetadata;
import weave.config.DataConfig.PublicMetadata;

import static weave.config.WeaveConfig.getConnectionConfig;
import static weave.config.WeaveConfig.getDataConfig;
import static weave.config.WeaveConfig.initWeaveConfig;
 
import weave.servlets.DataService;

public class RService extends GenericServlet
{
	private static final long serialVersionUID = 1L;

	public RService()
	{

	}

	private static Process rProcess = null;
	private String rServePath = "";
	public void init(ServletConfig config) throws ServletException
	{
		super.init(config);
		docrootPath = WeaveContextParams.getInstance(config.getServletContext()).getDocrootPath();
		uploadPath = WeaveContextParams.getInstance(config.getServletContext()).getUploadPath();
		initWeaveConfig(WeaveContextParams.getInstance(config.getServletContext()));
		rServePath =  WeaveContextParams.getInstance(config.getServletContext()).getRServePath();
	    try {
	    	if (rProcess == null) {
	    		startRServe();
	    	}
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
	
	public void destroy()
	{
		try {
			if (rProcess != null)
				rProcess.destroy();
		} finally {
			super.destroy();
		}
	}

	private String docrootPath = "";
	private String uploadPath = "";
	
	enum ServiceType { JRI, RSERVE; }
	private static ServiceType serviceType = ServiceType.JRI;
	
	public boolean checkforJRIService()throws Exception
	{
	    boolean jriStatus;
	
	    try
			{
				if(RServiceUsingJRI.getREngine() != null)
						jriStatus = true;
					else
						jriStatus = false;
				
			}
			//if JRI not present
			catch (RServiceUsingJRI.JRIConnectionException e) {
				e.printStackTrace();
				jriStatus = false;
			}
	//	}
		
		return jriStatus;
	}
		
	
	
	//TO DO write to and retrieve computation results from database
	//TO DO make it a map of the entire queryObject, of which the results is a property
	//temporary fix storing computation results in a hashmap
	public Map<String,RResult[]> compResultLookMap = new HashMap<String,RResult[]>();
	
	public void clearCache() {
		compResultLookMap.clear();
	}

	public void runTest() throws Exception
	{
		int[] col_args = {45};
		String[] ret_args = {};
		runScriptViaSQL(col_args, "test.r", ret_args);
	}
	/**
	 * Secure retrieval of data and execution of R scripts.
	 * @param columns Mapping of column IDs to R variable names.
	 * @param scriptPath Path to the R script to execute.
	 * @param returnNames R variables to return.
	 * @return returnedColumns result columns from the R script.
	 */
	public RResult[] runScriptViaSQL(int[] columns, String scriptName, String[] returnNames) throws Exception
	{
		DataConfig dc = getDataConfig();
		ConnectionInfo info;
		DataEntity ent;
		List<String> columnNames = new LinkedList<String>(); 
		File script_path = new File(uploadPath, scriptName);

		String connectionName = null; /* There should only be one connectionName/tableName used, for now. */
		String tableName = null;
		
		for (int col_id : columns)
		{
			String tmpTableName, tmpConnectionName, tmpColumnName;
			ent = dc.getEntity(col_id);
			tmpConnectionName = ent.privateMetadata.get(DataConfig.PrivateMetadata.CONNECTION);
			tmpTableName = ent.privateMetadata.get(DataConfig.PrivateMetadata.SQLTABLE);
			tmpColumnName = ent.privateMetadata.get(DataConfig.PrivateMetadata.SQLCOLUMN);

			if (tableName == null) tableName = tmpTableName;
			if (connectionName == null) connectionName = tmpConnectionName;

			if (tableName != tmpTableName)
			{
				throw new RemoteException("Columns are not members of the same table.", null); 
			}
			if (connectionName != tmpConnectionName)
			{
				throw new RemoteException("Columns are not members of the same connection.", null);
			}

			columnNames.add(tmpColumnName);
		}

		ConnectionConfig cc = getConnectionConfig();
		info = cc.getConnectionInfo(connectionName);

		String cleanConnectString = info.connectString.substring(5);
		URI connectionUri;
		try 
		{
			connectionUri = new URI(cleanConnectString);
		}
		catch (Exception e)
		{
			throw new RemoteException("Failed to parse jdbc connect string.", e);
		}
		String username, password, hostname, db_name, args, db_type;
		Integer db_port;
		Map<String,String> query_map;
		hostname = connectionUri.getHost();
		db_name = connectionUri.getPath().substring(1); // Remove leading slash to get dbname
		db_port = connectionUri.getPort();
		args = connectionUri.getQuery(); // Decompose URL-encoded params
		query_map = queryToMap(args);
		username = query_map.get("user");
		password = query_map.get("password");
		db_type = connectionUri.getScheme(); // DB type
		String sql_query = buildSelectQuery(columnNames, tableName);

		System.out.println(db_type);
		if (!db_type.equals("mysql"))
			throw new RemoteException("Only MySQL-sourced columns are supported in RServe queries.", null);

		String[] inputNames = {"username", "password", "hostname", "db_name", "db_port", "sql_query", "column_names", "script_path"};
		Object[] inputValues = {username, password, hostname, db_name, db_port, sql_query, columnNames, script_path.getAbsolutePath() };
		String[] outputNames = {"ingest_start", "process_start", "process_complete"};
		String r_script = 
			"library(RMySQL)\n"+
			"ingest_start <- as.numeric(Sys.time())\n"+
			"connection <- dbConnect(dbDriver('MySQL'), user = username, password = password, host = hostname, port = db_port, dbname = db_name)\n"+
			"input_data <- dbGetQuery(connection, sql_query)\n"+
			"rm(username, password, hostname, db_port, db_name, connection, sql_query) # Delete sensitive info from the workspace before executing untrusted script.\n"+
			"process_start <- as.numeric(Sys.time())\n"+
			"source(script_path)\n"+
			"process_complete <- as.numeric(Sys.time())\n";
		RResult[] returnedColumns = runScript( null, inputNames, inputValues, outputNames, r_script, "", false, false, false );
		return returnedColumns;
	}

	private Map<String,String> queryToMap(String query)
	{
		// Split it along &
		String[] pairs = query.split("&");
		Map<String,String> query_map = new HashMap<String,String>();
		for (String pair_str: pairs)
		{
			String[] pair = pair_str.split("=", 2);

			query_map.put(pair[0], pair[1]);
		}

		return query_map;
	}

	// this select query is the first version without filtering
	// we need to eventually replace it with the getQuery function in the DataService
	private String buildSelectQuery(List<String> columns, String tableName)
	{
			int counter = columns.size();
			String tempQuery = "";
			
			for(int i=0; i < counter; i++)
			{
				String tempColumnName = SQLUtils.quoteSymbol(SQLUtils.MYSQL, columns.get(i));

				if(i == (counter-1))
				{
					tempQuery = tempQuery.concat(tempColumnName);
				}
				else
					tempQuery = tempQuery.concat(tempColumnName + ", ");
			}
			
			String query = "select " + tempQuery + " from " + SQLUtils.quoteSymbol(SQLUtils.MYSQL, tableName);
			return query;
	}
	/**
	 * 
	 * @param requestObject sent from the AWS UI collection of parameters to run a computation
	 * @param connectionObject send from the AWS UI parameters needed for connection Rserve to the db
	 * @return returnedColumns result columns from the computation
	 * @throws Exception
	 */
	public RResult[] runScriptOnSQLColumns(Map<String,String> connectionObject, Map<String,Object> requestObject) throws Exception
	{
		RResult[] returnedColumns;
		String connectionType = connectionObject.get("connectionType").toString();
		String scriptName = requestObject.get("scriptName").toString();
		System.out.print(requestObject.toString());
		//if the computation result has been stored then computation is not run
		//the stored results are simply returned
		if(compResultLookMap.containsKey(requestObject.toString()))
		{
			return compResultLookMap.get(requestObject.toString());
		}
		
		else
		{
			//Set<String> keys = connectionObject.keySet();
			String user = connectionObject.get("user");
			String password = connectionObject.get("password");
			String schemaName = connectionObject.get("schema");
			String hostName = connectionObject.get("host");
			
				
			String dataset = requestObject.get("dataset").toString();
			String scriptPath = requestObject.get("scriptPath").toString();
			//TODO Find better way to do this? full proof queries?
			//query construction
			Object columnNames = requestObject.get("columnsToBeRetrieved");//array list
			ArrayList<String> columns = new ArrayList<String>();
			columns = (ArrayList)columnNames;
			
			String col1 = columns.get(0);
			String col2 = columns.get(1);
			String col3 = columns.get(2);
			String col4 = columns.get(3);
			String col5 = columns.get(4);
			
			System.out.println(col1 + col2 + col3  + col4 + col5);
			String query = buildSelectQuery(columns, dataset);
			
			String cannedScriptLocation = scriptPath + scriptName;
			 //String cannedSQLScriptLocation = "C:\\Users\\Shweta\\Desktop\\" + (scriptName).toString();//hard coded for now
			 
			 Object[] requestObjectInputValues = {cannedScriptLocation, query, col1, col2, col3, col4, col5};
			 String[] requestObjectInputNames = {"cannedScriptPath", "query", "col1", "col2", "col3", "col4", "col5"};
			
			 String finalScript = "";
			 String dsn = connectionObject.get("dsn").toString();
			if(connectionType.equalsIgnoreCase("RMySQL"))
			{
				finalScript = "scriptFromFile <- source(cannedScriptPath)\n" +
							  "library(RMySQL)\n" +
							  "con <- dbConnect(dbDriver(\"MySQL\"), user =" + "\"" +user+"\" , password =" + "\"" +password+"\", host =" + "\"" +hostName+"\", port = 3306, dbname =" + "\"" +schemaName+"\")\n" +
							  "library(survey)\n" +
							  "getColumns <- function(query)\n" +
							  "{\n" +
							  "return(dbGetQuery(con, paste(query)))\n" +
							  "}\n" +
							  "returnedColumnsFromSQL <- scriptFromFile$value(query, params)\n";
			} else if (connectionType.equalsIgnoreCase("RODBC"))
			{
				finalScript = "scriptFromFile <- source(cannedScriptPath)\n" +
							 "library(RODBC)\n" +
							 "con <- odbcConnect(dsn =" + "\"" +dsn+"\", uid =" + "\"" +user+"\" , pwd =" + "\"" +password+"\")\n" +
							 "library(survey)\n" +
							 "getColumns <- function(query)\n" +
							 "{\n" +
							 "return(sqlQuery(con, paste(query)))\n" +
							 "}\n" +
							 "returnedColumnsFromSQL <- scriptFromFile$value(query, params)\n";
			}
			String[] requestObjectOutputNames = {};
			
			returnedColumns = this.runScript( null, requestObjectInputNames, requestObjectInputValues, requestObjectOutputNames, finalScript, "", false, false, false);
			
			//rewriting?
			compResultLookMap.put(requestObject.toString(), returnedColumns);//temporary solution for caching. To be replaced by retrieval of computation results from db
			return returnedColumns;
		}
		 
	}
	
	// this functions makes a command line call on the server machine.
	// the command executed starts the Rserve on windows or unix
	// On windows: the rServePath needs to be given in the configuration file
	// On mac: the command R CMD RServe needs to work http://dev.mygrid.org.uk/blog/?p=34
	public void startRServe() throws IOException {
		
		if (rProcess == null)
		{
			if (System.getProperty("os.name").startsWith("Windows")) 
			{
				try 
				{
					rProcess = Runtime.getRuntime().exec(rServePath);
				} catch (Exception e) 
			
				{
					e.printStackTrace();
				}
			}
			else 
			{
				String[] args = {"R", "CMD", "RServe", "--vanilla"};
				try {
					rProcess = Runtime.getRuntime().exec(args);
				} catch (Exception e) {
					e.printStackTrace();
				}
			}
		}
	}
	
	// this function should stop the Rserve... needs revision
	public void stopRServe() throws IOException {
	 try {
		if (rProcess != null )
		{
			rProcess.destroy();
		}
	 } catch (Exception e) {
		e.printStackTrace();
	 }
	}

	// this functions intends to run a script with filtered.
	// essentially this function should eventually be our main run script function.
	// in the request object, there will be: the script path, the script name
	// and the columns, along with their filters.
	// TODO not completed
	public RResult[] runScriptWithFilteredColumns(Map<String,Object> requestObject) throws Exception
	{
		RResult[] returnedColumns;
		
		String scriptPath = requestObject.get("scriptPath").toString();
		String scriptName = requestObject.get("scriptName").toString();
		String cannedScript = scriptPath + scriptName;
		
		String[] inputNames = {"cannedScriptPath", "dataset"};
		
		DataService.FilteredColumnRequest[] filteredColumnRequest = (DataService.FilteredColumnRequest[]) requestObject.get("filteredColumnsRequest");
		
		Object[][] recordData = DataService.getFilteredRows(filteredColumnRequest, null).recordData;

		Object[] inputValues = {cannedScript, recordData};
		
		String finalScript = "scriptFromFile <- source(cannedScriptPath)\n" +
					         "scriptFromFile$value(dataset)"; 
		
		String[] outputNames = {};
		returnedColumns = this.runScript(null, inputNames, inputValues, outputNames, finalScript, "", false, false, false);
			
		return returnedColumns;
		
	}
	
	public String[] getListOfScripts(String folderPath)
	{
		File directory = new File(folderPath);
		String[] files = directory.list();
		List<String> rFiles = new ArrayList<String>();
		String extension = "";
		
		for (int i = 0; i < files.length; i++)
		{
			extension = files[i].substring(files[i].lastIndexOf(".") + 1, files[i].length());
			if(extension.equalsIgnoreCase("r"))
				rFiles.add(files[i]);
		}
		return rFiles.toArray(new String[0]);
	}

// not needed for now.
	
//	public class ScriptMetadata
//	{
//		// input variables
//		public String[] inputs;
//		// description of the input variables
//		public String[] inputDescriptions;
//		
//		// output variables
//		public String[] outputs;
//		// description of the output variables
//		public String[] outputDescriptions;
//
//	}
	
	public RResult[] runScript( String[] keys,String[] inputNames, Object[] inputValues, String[] outputNames, String script, String plotScript, boolean showIntermediateResults, boolean showWarnings, boolean useColumnAsList) throws Exception
	{
		Exception exception = null;
		
		// check chosen service first
		ServiceType[] types = ServiceType.values();
		if (serviceType != types[0])
		{
			types[1] = types[0];
			types[0] = serviceType;
		}
		for (ServiceType type : types)
		{
			try
			{
				if (type == ServiceType.RSERVE)
					return RServiceUsingRserve.runScript(docrootPath, inputNames, inputValues, outputNames, script, plotScript, showIntermediateResults, showWarnings);
				
				// this crashes Tomcat
				if (type == ServiceType.JRI)
					return RServiceUsingJRI.runScript( docrootPath, keys, inputNames, inputValues, outputNames, script, plotScript, showIntermediateResults, showWarnings, useColumnAsList);
				
			}
			catch (RServiceUsingJRI.JRIConnectionException e)
			{
				e.printStackTrace();
				// remember exception associated with chosen service
				// alternate for next time
				if (type == serviceType)
					exception = e;
				else
					serviceType = type;
			}
			catch (RServiceUsingRserve.RserveConnectionException e)
			{
				e.printStackTrace();
				// remember exception associated with chosen service
				// alternate for next time
				if (type == serviceType)
					exception = e;
				else
					serviceType = type;
			}
		}
		throw new RemoteException("Unable to connect to RServe & Unable to initialize REngine", exception);
	}
	
	
	public LinearRegressionResult linearRegression(double[] dataX, double[] dataY) throws RemoteException
	{
		
		return RServiceUsingRserve.linearRegression( docrootPath, dataX, dataY);
	}

	public RResult[] kMeansClustering( String[] inputNames, Object[][] inputValues, boolean showWarnings,int numberOfClusters, int iterations) throws Exception
	{
		
		//return RServiceUsingRserve.kMeansClustering( docrootPath, dataX, dataY, numberOfClusters);
		return RServiceUsingRserve.kMeansClustering(inputNames, inputValues, showWarnings,numberOfClusters, iterations);
	}

	public HierarchicalClusteringResult hierarchicalClustering(double[] dataX, double[] dataY) throws RemoteException
	{
		return RServiceUsingRserve.hierarchicalClustering( docrootPath, dataX, dataY);
	}

	public RResult[] handlingMissingData( String[] inputNames, Object[][] inputValues, String[] outputNames, boolean showIntermediateResults, boolean showWarnings, boolean completeProcess) throws Exception
	{
		return RServiceUsingRserve.handlingMissingData(inputNames, inputValues, outputNames,showIntermediateResults, showWarnings, completeProcess);
	}
	
	
}
