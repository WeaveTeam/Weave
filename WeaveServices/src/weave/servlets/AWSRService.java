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
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.rmi.RemoteException;
import java.sql.Connection;
import java.sql.SQLException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;
import java.util.Vector;
import javax.script.ScriptException;
import javax.servlet.ServletConfig;
import javax.servlet.ServletException;

import org.apache.commons.io.FilenameUtils;
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;
import org.json.simple.parser.ParseException;
import org.rosuda.REngine.REXP;
import org.rosuda.REngine.REXPMismatchException;
import org.rosuda.REngine.RFactor;
import org.rosuda.REngine.Rserve.RConnection;
import org.rosuda.REngine.Rserve.RserveException;

import weave.beans.RResult;
import weave.config.WeaveContextParams;
import weave.config.ConnectionConfig.ConnectionInfo;
import weave.config.WeaveConfig;

import weave.servlets.DataService.FilteredColumnRequest;
import weave.utils.FileUtils;
import weave.utils.MapUtils;
import weave.utils.SQLResult;
import weave.utils.SQLUtils;
import weave.utils.SQLUtils.WhereClause;

import com.google.gson.Gson;
import com.google.gson.internal.StringMap;

public class AWSRService extends RService
{
	private static final long serialVersionUID = 1L;

	public AWSRService()
	{

	}

	public void init(ServletConfig config) throws ServletException {
		super.init(config);
		awsConfigPath = WeaveContextParams.getInstance(
				config.getServletContext()).getConfigPath();
		awsConfigPath = awsConfigPath + "/../aws-config/";
	}

	private String awsConfigPath = "";

	public static class AWSConnectionObject {
		String connectionType;
        String user;
        String password;
        String schema;
        String host;
        String dsn;
	}
	
	public static class AWSRequestObject
	{
		String scriptName;
		String dataset;
		String scriptPath;
		String[] columnsToBeRetrieved;
		FilteredColumnRequest[] filteredColumnRequests;
	}
   
	public class MyResult {
	
		public RResult[] data;
		public long[] times = new long[2];
	
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
	private String buildSelectQuery(String [] columns, String tableName)
	{
			int counter = columns.length;
			String tempQuery = "";
			
			for(int i=0; i < counter; i++)
			{
				String tempColumnName = SQLUtils.quoteSymbol(SQLUtils.MYSQL, columns[i]);

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
	public RResult[] runScriptOnSQLColumns(AWSConnectionObject conn, AWSRequestObject request) throws Exception
	{
		RResult[] returnedColumns;
		
		//query construction
		
		String query = "";
		//String query = buildSelectQuery(columns, dataset);
		
		String cannedScriptLocation = request.scriptPath + request.scriptName;
		// String cannedSQLScriptLocation = "C:\\Users\\Shweta\\Desktop\\" +
		// (scriptName).toString();//hard coded for now

		Object[] requestObjectInputValues = { cannedScriptLocation, query,
				request.columnsToBeRetrieved[0],
				request.columnsToBeRetrieved[1],
				request.columnsToBeRetrieved[2],
				request.columnsToBeRetrieved[3],
				request.columnsToBeRetrieved[4] };
		String[] requestObjectInputNames = { "cannedScriptPath", "query",
				"col1", "col2", "col3", "col4", "col5" };

		String finalScript = "";
		if(conn.connectionType.equalsIgnoreCase("RMySQL"))
		{
			finalScript = "scriptFromFile <- source(cannedScriptPath)\n" +
						  "library(RMySQL)\n" +
						  "con <- dbConnect(dbDriver(\"MySQL\"), user =" + "\"" +conn.user+"\" , password =" + "\"" +conn.password+"\", host =" + "\"" +conn.host+"\", port = 3306, dbname =" + "\"" +conn.schema+"\")\n" +
						  "library(survey)\n" +
						  "getColumns <- function(query)\n" +
						  "{\n" +
						  "return(dbGetQuery(con, paste(query)))\n" +
						  "}\n" +
						  "returnedColumnsFromSQL <- scriptFromFile$value(query, params)\n";
		} else if (conn.connectionType.equalsIgnoreCase("RODBC"))
		{
			finalScript ="scriptFromFile <- source(cannedScriptPath)\n" +
						 "library(RODBC)\n" +
						 "con <- odbcConnect(dsn =" + "\"" +conn.dsn+"\", uid =" + "\"" +conn.user+"\" , pwd =" + "\"" +conn.password+"\")\n" +
						 "sqlQuery(con, \"USE " + conn.schema + "\")\n" +
						 "library(survey)\n" +
						 "getColumns <- function(query)\n" +
						 "{\n" +
						 "return(sqlQuery(con, paste(query)))\n" +
						 "}\n" +
						 "returnedColumnsFromSQL <- scriptFromFile$value(query, params)\n";
		}
		String[] requestObjectOutputNames = {};

		returnedColumns = this.runScript(null, requestObjectInputNames,
				requestObjectInputValues, requestObjectOutputNames,
				finalScript, "", false, false, false);

		return returnedColumns;
	}
	
	private class InputPairs
	{
		ArrayList<String> names = new ArrayList<String>();
		ArrayList<Object> values = new ArrayList<Object>();
		void add(String name, Object value)
		{
			names.add(name);
			values.add(value);
		}
	}
	
	/**
	 * 
	 * @param requestObject sent from the AWS UI collection of parameters to run a computation
	 * @param connectionObject send from the AWS UI parameters needed for connection Rserve to the db
	 * @param algorithmCollection collection of data mining algorithm objects to be run, eg KMeans, DIANA, CLARA etc
	 * @return returnedColumns result columns from the computation
	 * @throws Exception
	 */
	public RResult[] runScriptonAlgoCollection(AWSConnectionObject conn, AWSRequestObject request, Map<String,Object> params) throws Exception
	{
		RResult[] returnedColumns;
			
		InputPairs input = new InputPairs();
		
		String query = buildSelectQuery(request.columnsToBeRetrieved, request.dataset);
		String cannedScriptLocation = request.scriptPath + request.scriptName;
		
		input.add("cannedScriptPath", cannedScriptLocation);
		input.add("query", query);
		input.add("params", request.columnsToBeRetrieved);
		input.add("myuser", conn.user);
		input.add("mypassword", conn.password);
		input.add("myhostName", conn.host);
		input.add("myschemaName", conn.schema);
		input.add("mydsn", conn.schema);
		
		//looping through the parameters needed in the computational algorithms in r
		//if the map is not empty or if it exists
		if(!(params.isEmpty()) || params != null)
			for (Entry<String,Object> entry : params.entrySet())
				input.add(entry.getKey(), entry.getValue());
			
					
		Object[] requestObjectInputValues = input.values.toArray();
		String [] requestObjectInputNames = new String[requestObjectInputValues.length];
		input.names.toArray(requestObjectInputNames);
		 
		//Object[] requestObjectInputValues = {cannedScriptLocation, query, columns, user, password, hostName, schemaName, dsn};
		// String[] requestObjectInputNames = {"cannedScriptPath", "query", "params", "myuser", "mypassword", "myhostName", "myschemaName", "mydsn"};
		
		 String finalScript = "";
		if(conn.connectionType.equalsIgnoreCase("RMySQL"))
		{
			finalScript = "library(RMySQL)\n" +
						  "con <- dbConnect(dbDriver(\"MySQL\"), user = myuser , password = mypassword, host = myhostName, port = 3306, dbname =myschemaName)\n" +
						  "library(survey)\n" +
						   "getColumns <- function(query)\n" +
						  "{\n" +
						  "return(dbGetQuery(con, paste(query)))\n" +
						  "}\n" +
						   "scriptFromFile <- source(cannedScriptPath)\n" +
						   "returnedColumns <- scriptFromFile$value(ClusterSizes, Maxiterations, query)\n";
		} else if (conn.connectionType.equalsIgnoreCase("RODBC"))
		{
			finalScript = "library(RODBC)\n" +
						 "con <- odbcConnect(dsn = mydsn, uid = myuser , pwd = mypassword)\n" +
						 "sqlQuery(con, \"USE myschemaName\")\n" +
						 "library(survey)\n" +
						 "getColumns <- function(query)\n" +
						 "{\n" +
						 "return(sqlQuery(con, paste(query)))\n" +
						 "}\n" +
						 "scriptFromFile <- source(cannedScriptPath)\n" +
						 "returnedColumnsFromSQL <- scriptFromFile$value(ClusterSizes, Maxiterations, query)\n";
		}
		String[] requestObjectOutputNames = {};
		
		returnedColumns = this.runScript( null, requestObjectInputNames, requestObjectInputValues, requestObjectOutputNames, finalScript, "", false, false, false);
		
		return returnedColumns;
	}

	/**
	    * @param userName author of a given Project
	    * @param projectName project which contains queryObjects
	    * @return  collection of queryObjects in the project 
	    * @throws Exception
	    */
	//retrieves all the projects belonging to a particular user
	public String[] getProjectFromDatabase() throws SQLException, RemoteException{
		SQLResult projectObjects= null;//all the projects belonging to the userName
		ConnectionInfo coninfo = WeaveConfig.getConnectionConfig().getConnectionInfo("mysql");
		Connection con = coninfo.getConnection();
		
		List<String> selectColumns = new ArrayList<String>();
		selectColumns.add("projectName");//we're retrieving the list of projects in the projectName column in database
		
//		Map<String,String> whereParams = new HashMap<String, String>();
//		whereParams.put("userName", userName);
//		Set<String> caseSensitiveFields  = new HashSet<String>(); 
//		queryObjects= SQLUtils.getResultFromQuery(con, query, params, false); OR
//		projectObjects = SQLUtils.getResultFromQuery(con,selectColumns, "data", "stored_query_objects", whereParams, caseSensitiveFields);
		
		
		String query = String.format("SELECT distinct(%s) FROM %s", "projectName", (SQLUtils.quoteSchemaTable(con,"data", "stored_query_objects2")));
		projectObjects = SQLUtils.getResultFromQuery(con,query, null, true );
		
		String[] projectNames = new String[projectObjects.rows.length];
		for(int i = 0; i < projectObjects.rows.length; i++){
			Object project = projectObjects.rows[i][0];//TODO find better way to do this
			projectNames[i] = project.toString();

		}
		
		return projectNames;
	}
	
	/**

	 * 
	 * @param projectName
	 *            project from which queryObjects have to be listed
	 * @return finalQueryObjectCollection array of [jsonObjects, namesofFiles]
	 * @throws Exception
	 */
	// Gets the list of queryObjects in a folder and returns an array of
	// JSONObjects(each JSONObject --> one queryObject)
	public Object[] getQueryObjectsInProject(String projectName)
			throws Exception {
		Object[] finalQueryObjectCollection = new Object[2];

		JSONObject[] finalQueryObjects = null;
		String[] queryNames = getQueryObjectNamesInProject(projectName);
		if (queryNames.length != 0) {// if the project contains something
			ArrayList<JSONObject> jsonlist = new ArrayList<JSONObject>();
			JSONParser parser = new JSONParser();

			finalQueryObjects = new JSONObject[queryNames.length];

			for (int i = 0; i < queryNames.length; i++) {
				// for every queryObject, convert to a json object
				String extension = FilenameUtils.getExtension(queryNames[i]);

				// add file filter for searching only for json files
				if (extension.equalsIgnoreCase("json")) {
					String path = "C:/Projects/" + projectName + "/"
							+ queryNames[i];// TODO find better way
					FileReader reader = new FileReader(path);
					Object currentQueryObject = parser.parse(reader);
					JSONObject currentjsonObject = (JSONObject) currentQueryObject;
					jsonlist.add(currentjsonObject);
					reader.close();
				}
			}

			// returning an array of JSON Objects
			finalQueryObjects = jsonlist.toArray(finalQueryObjects);
		}

		else {
			// if project is empty return null
			finalQueryObjects = null;
			// throw new
			// RemoteException("No query Objects found in the specified folder!");
		}

		finalQueryObjectCollection[0] = finalQueryObjects;
		finalQueryObjectCollection[1] = queryNames;

	}
		/*
 	    * @param userName author of a given Project
	    * @param projectName project which contains the requested query
	    * @param queryObjectName the filename that contains the requested queryObject
	    * @return the requested single queryObject 
	    * @throws Exception
	    */
	public SQLResult getSingleQueryObjectInProjectFromDatabase(String username, String projectName, String queryObjectName){
		SQLResult singleQueryObject = null;//the queryObject requested
		
		return singleQueryObject;
	};

	//Gets the sub-directories (projects) in the 'Projects' folder
//	public String[] getListOfProjects() 
//	{
//		File projects = new File("C:/", "Projects");
//		//File projects = new File(uploadPath, "Projects");
//		String[] projectNames = projects.list();
//		return projectNames; 
//	}
//	
	
//	public String[] getQueryObjectNamesInProject(String projectName)throws Exception
//	{
//		String[] queryObjectNames = null;
//		String pathq = "C:/Projects/" + projectName;
//		File queries = new File(pathq);
//		if(queries.exists()){
//			System.out.println("Exists");
//			queryObjectNames = queries.list();
//		}
//		return queryObjectNames;
//	}
//	
//	
	
   /** 
   * @param projectName project from which queryObjects have to be listed
   * @return finalQueryObjectCollection array of [jsonObjects, title of queryObjects]   
   * @throws Exception
   */
	public Object[] getQueryObjectsFromDatabase(String projectName) throws RemoteException, SQLException
	{
		Object[] finalQueryObjectCollection = new Object[2];
		ConnectionInfo coninfo = WeaveConfig.getConnectionConfig().getConnectionInfo("mysql");
		Connection con = coninfo.getConnection();
		
		//we're retrieving the list of queryObjects in the selected project
		List<String> selectColumns = new ArrayList<String>();
		selectColumns.add("queryObjectTitle");
		selectColumns.add("queryObjectContent");
		
		
		Map<String,String> whereParams = new HashMap<String, String>();
		whereParams.put("projectName", projectName);
		Set<String> caseSensitiveFields  = new HashSet<String>();//empty 
		SQLResult queryObjectsSQLresult = SQLUtils.getResultFromQuery(con,selectColumns, "data", "stored_query_objects2", whereParams, caseSensitiveFields);
		
		
		
		//getting names from queryObjectTitle
		String[] queryNames =  new String[queryObjectsSQLresult.rows.length];
		for(int i = 0; i < queryObjectsSQLresult.rows.length; i++){
			Object singleSQLQueryObject = queryObjectsSQLresult.rows[i][0];//TODO find better way to do this
			queryNames[i] = singleSQLQueryObject.toString();
		}
		
		//getting json objects from queryObjectContent
		JSONObject[] finalQueryObjects = null;
		if(queryObjectsSQLresult.rows.length != 0)
		{
			ArrayList<JSONObject> jsonlist = new ArrayList<JSONObject>();
			JSONParser parser = new JSONParser();
			finalQueryObjects = new JSONObject[queryObjectsSQLresult.rows.length];
			
			
			for(int i = 0; i < queryObjectsSQLresult.rows.length; i++)
			{
				Object singleObject = queryObjectsSQLresult.rows[i][1];//TODO find better way to do this
				String singleObjectString = singleObject.toString();
				try{
					
					 Object parsedObject = parser.parse(singleObjectString);
					 JSONObject currentJSONObject = (JSONObject) parsedObject;
					
					 jsonlist.add(currentJSONObject);
				}
				catch (ParseException pe){
					
				}
				
			}//end of for loop
			
			finalQueryObjects = jsonlist.toArray(finalQueryObjects);
			
		}
		else{
			finalQueryObjects = null;
		}
		
		finalQueryObjectCollection[0] = finalQueryObjects;
		finalQueryObjectCollection[1] = queryNames;
		
		return finalQueryObjectCollection;
		
	}
	
	//deletes the entire specified folder (files within and folder itself)
	public boolean deleteProject(String projectName) throws Exception
	{
		boolean status;
		File pj = new File("C:/Projects", projectName);
		status = FileUtils.deleteDirectory(pj);

		return status;
	}

	// deletes the specified file(json) within the specified folder
	public boolean deleteQueryObject(String projectName, String queryObjectName)
			throws Exception {
		boolean status = false;

		String path = "C:/Projects/" + projectName + "/" + queryObjectName;// TODO
																			// find
																			// better
																			// way
		File fileToDelete = new File(path);

		if (fileToDelete.exists()) {
			fileToDelete.delete();
			status = true;
			System.out.println("deleted the file");
		}

		return status;
	}
	
//	/**
//	    * 
//	    * @param projectName project from which queryObjects have to be listed
//	    * @return finalQueryObjectCollection array of [jsonObjects, namesofFiles] 
//	    * @throws Exception
//	    */
//	//Gets the list of queryObjects in a folder and returns an array of JSONObjects(each JSONObject --> one queryObject)
//	public Object[] getQueryObjectsInProject(String projectName) throws Exception
//	{
//		Object[] finalQueryObjectCollection = new Object[2];
//		
//		JSONObject[] finalQueryObjects = null;
//		String[] queryNames = getQueryObjectNamesInProject(projectName);
//		if(queryNames.length != 0)
//		{//if the project contains something
//			ArrayList<JSONObject> jsonlist = new ArrayList<JSONObject>();
//			JSONParser parser = new JSONParser();
//			
//			finalQueryObjects = new JSONObject[queryNames.length];
//			
//				for(int i =0; i < queryNames.length; i++)
//				{
//					//for every queryObject, convert to a json object
//					String extension = FilenameUtils.getExtension(queryNames[i]);
//					
//					//add file filter for searching only for json files
//					if(extension.equalsIgnoreCase("json"))
//					{
//						String path = "C:/Projects/"+projectName+"/"+queryNames[i];//TODO find better way
//						FileReader reader = new FileReader(path);
//						Object currentQueryObject = parser.parse(reader);
//						JSONObject currentjsonObject = (JSONObject) currentQueryObject;
//						jsonlist.add(currentjsonObject);
//						reader.close();
//					}
//				}
//					
//					//returning an array of JSON Objects
//				finalQueryObjects = jsonlist.toArray(finalQueryObjects);
//		}
//			
//			else{
//				//if project is empty return null
//				finalQueryObjects = null;
//				//throw new RemoteException("No query Objects found in the specified folder!");
//			}
//			
//			
//		finalQueryObjectCollection[0] = finalQueryObjects;
//		finalQueryObjectCollection[1] = queryNames;
//		
//		return finalQueryObjectCollection;
//		
//	}
	
	public boolean deleteProjectFromDatabase(String projectName)throws RemoteException, SQLException
	{
		boolean status = false;
		ConnectionInfo coninfo = WeaveConfig.getConnectionConfig().getConnectionInfo("mysql");
		Connection con = coninfo.getConnection();

		
		//Set<String> caseSensitiveFields  = new HashSet<String>(); 
		Map<String,Object> whereParams = new HashMap<String, Object>();
		whereParams.put("projectName", projectName);
		WhereClause<Object> clause = new WhereClause<Object>(con, whereParams, null, true);
		
		int count = SQLUtils.deleteRows(con, "data", "stored_query_objects",clause);
		
		if(count != 0){
			status = true;//flag which indicates if all query objects in a project have been deleted
		}
		
		return status;
	}
	
	
	public boolean deleteQueryObjectFromProjectFromDatabase(String projectName, String queryObjectTitle)throws RemoteException, SQLException{
		boolean status = false;
		
		ConnectionInfo coninfo = WeaveConfig.getConnectionConfig().getConnectionInfo("mysql");
		Connection con = coninfo.getConnection();
		
		Map<String,Object> whereParams = new HashMap<String, Object>();
		whereParams.put("projectName", projectName);
		whereParams.put("queryObjectTitle", queryObjectTitle);
		WhereClause<Object> clause = new WhereClause<Object>(con, whereParams, null, true);
		
		int count = SQLUtils.deleteRows(con, "data", "stored_query_objects",clause);
		
		if(count != 0){
			status = true;//flag which indicates if all query objects in a project have been deleted
		}
		
		
		
		return status;
	}
	//adds a queryObject to the database
	public boolean insertQueryObjectInProjectFromDatabase(String userName, String projectName, String queryObjectTitle, String queryObjectContent) throws RemoteException, SQLException
	{
		boolean addStatus = false;
		ConnectionInfo coninfo = WeaveConfig.getConnectionConfig().getConnectionInfo("mysql");
		Connection con = coninfo.getConnection();
		
		Map<String,Object> record = new HashMap<String, Object>();
		record.put("userName", userName);
		record.put("projectName", projectName);
		record.put("queryObjectTitle", queryObjectTitle);
		record.put("queryObjectContent", queryObjectContent);
		
		int count = SQLUtils.insertRow(con, "data", "stored_query_objects", record );
		
		if(count != 0)
			addStatus = true;
		return addStatus;
	}
	
	//deletes the entire specified folder (files within and folder itself)
//	public boolean deleteProject(String projectName) throws Exception
//	{
//		boolean status;
//		File pj = new File("C:/Projects", projectName);
//		status = FileUtils.deleteDirectory(pj);
//		
//		return status;
//	}
//	
	
	//deletes the specified file(json) within the specified folder
//	public boolean deleteQueryObject(String projectName, String queryObjectName) throws Exception
//	{
//		boolean status = false;
//		
//		String path = "C:/Projects/" + projectName + "/" + queryObjectName;//TODO find better way 
//		File fileToDelete = new File(path);
//		
//		if(fileToDelete.exists()){
//			fileToDelete.delete();
//			status = true;
//			System.out.println("deleted the file");
//		}
//	
//		return status;
//	}
//	

	/**
     * 
     * @param request sent from the AWS UI collection of parameters to run a computation
     * @param conn send from the AWS UI parameters needed for connection Rserve to the db
     * @return returnedColumns result columns from the computation
     * @throws Exception
     */
    public RResult[] runScriptwithScriptMetadata(AWSConnectionObject conn, AWSRequestObject request) throws Exception
    {
        RResult[] returnedColumns;
        
        //TODO Find better way to do this? full proof queries?
        //query construction
        
        String query = buildSelectQuery(request.columnsToBeRetrieved, request.dataset);
        
        String cannedScriptLocation = request.scriptPath + request.scriptName;
         
        /*sending all necessary parameters to the database
         * getting rid of string concatenation
         * */
		Object[] requestObjectInputValues = {cannedScriptLocation, query, request.columnsToBeRetrieved, conn.user, conn.password, conn.host, conn.schema, conn.dsn};
		String[] requestObjectInputNames = {"cannedScriptPath", "query", "params", "myuser", "mypassword", "myhostName", "myschemaName", "mydsn"};
		
		String finalScript = "";
		if (conn.connectionType.equalsIgnoreCase("RMySQL")) {
			finalScript = "scriptFromFile <- source(cannedScriptPath)\n"
					+ "library(RMySQL)\n"
					+ "con <- dbConnect(dbDriver(\"MySQL\"), user = myuser , password = mypassword, host = myhostName, port = 3306, dbname =myschemaName)\n"
					+ "library(survey)\n"
					+ "getColumns <- function(query)\n"
					+ "{\n"
					+ "return(dbGetQuery(con, paste(query)))\n"
					+ "}\n"
					+ "returnedColumnsFromSQL <- scriptFromFile$value(query, params)\n";
		} else if (conn.connectionType.equalsIgnoreCase("RODBC")) {
			finalScript = "scriptFromFile <- source(cannedScriptPath)\n"
					+ "library(RODBC)\n"
					+ "con <- odbcConnect(dsn = mydsn, uid = myuser , pwd = mypassword)\n"
					+ "sqlQuery(con, \"USE myschemaName\")\n"
					+ "library(survey)\n"
					+ "getColumns <- function(query)\n"
					+ "{\n"
					+ "return(sqlQuery(con, paste(query)))\n"
					+ "}\n"
					+ "returnedColumnsFromSQL <- scriptFromFile$value(query, params)\n";
		}
		String[] requestObjectOutputNames = {};

		returnedColumns = runAWSScript(null, requestObjectInputNames,
				requestObjectInputValues, requestObjectOutputNames,
				finalScript, "", false, false);

		return returnedColumns;
	}

	public int runStataScript() throws IOException {

		Runtime run = Runtime.getRuntime();
		Process proc = null;
		proc = run.exec(new String[] { "stata-se", "-q" });
		OutputStream stdin = proc.getOutputStream();
		stdin.write(new String("/Users/franckamayou/Desktop/test.do")
				.getBytes());
		stdin.close();
		BufferedReader stdout = new BufferedReader(new InputStreamReader(
				proc.getInputStream()));
		BufferedReader stderr = new BufferedReader(new InputStreamReader(
				proc.getErrorStream()));

		while (true) {
			String line = null;
			try {
				// check both streams for new data
				if (stdout.ready()) {
					line = stdout.readLine();
				} else if (stderr.ready()) {
					line = stderr.readLine();
				}

				// print out data from stream
				if (line != null) {
					System.out.println(line);
					continue;
				}
			} catch (IOException ioe) {
				// stream error, get the return value of the process and return
				// from this function
				try {
					return proc.exitValue();
				} catch (IllegalThreadStateException itse) {
					return -Integer.MAX_VALUE;
				}
			}
			try {
				// if process finished, return
				return proc.exitValue();
			} catch (IllegalThreadStateException itse) {
				// process is still running, continue
			}
		}

	}

	/**
	 * Gives an object containing the script contents
	 * 
	 * @param scriptName
	 * @return
	 */
	public String getScript(String scriptName) throws Exception{
    	File directory = new File(awsConfigPath, "RScripts");
		String[] files = directory.list();
		String scriptContents = new String();
		BufferedReader bufr = null;
		for (int i = 0; i < files.length; i++)
		{
			if(scriptName.equalsIgnoreCase(files[i])){
				try {
					bufr = new BufferedReader(new FileReader(new File(directory, scriptName)));
					String contents = "";
					while((contents = bufr.readLine()) != null){
						scriptContents = scriptContents + contents + "\n";
					}
				} catch (IOException e) {
					e.printStackTrace();
				} finally {
					try {
						if(bufr != null){
							bufr.close();
						}
					} catch (IOException ex) {
						ex.printStackTrace();
					}
				}
			}
		}
		return scriptContents;
    }

	public String[] getListOfScripts() {

		File directory = new File(awsConfigPath, "RScripts");
		String[] files = directory.list();
		List<String> rFiles = new ArrayList<String>();
		String extension = "";

		for (int i = 0; i < files.length; i++) {
			extension = files[i].substring(files[i].lastIndexOf(".") + 1,
					files[i].length());
			if (extension.equalsIgnoreCase("r"))
				rFiles.add(files[i]);
		}
		return rFiles.toArray(new String[rFiles.size()]);
	}

	public String saveMetadata(String scriptName, Object scriptMetadata) throws Exception {
		String status = "";
		
		String jsonFileName = scriptName.substring(0, scriptName.lastIndexOf('.')).concat(".json");
		File file = new File(awsConfigPath + "RScripts", jsonFileName);
		if (!file.exists()){
			throw new RemoteException("Metadata file: " + jsonFileName + "does not exist");
			//file.createNewFile();
		}
		
		FileWriter fw = new FileWriter(file.getAbsolutePath());
		BufferedWriter bw = new BufferedWriter(fw);
		Gson gson = new Gson();
		gson.toJson(scriptMetadata, bw);
		bw.close();
		
		status = "success";
		return status;
	}

	public Object getScriptMetadata(String scriptName) throws Exception {
		File directory = new File(awsConfigPath, "RScripts");
		String[] files = directory.list();
		int filecount = 0;
		// this object will get the metadata from the json file
		Object scriptMetadata = new Object();
		
		// we replace scriptname.R with scriptname.json
		String jsonFileName = scriptName.substring(0, scriptName.lastIndexOf('.')).concat(".json");

		// we will check if there is a json file with the same name in the directory.
		for (int i = 0; i < files.length; i++)
		{
			if (jsonFileName.equalsIgnoreCase(files[i]))
			{
				filecount++;
				// do the work
				Gson gson = new Gson();
				
				if(filecount > 1) {
					throw new RemoteException("multiple copies of " + jsonFileName + "found!");
				}
				
				try {
					
					BufferedReader br = new BufferedReader(new FileReader(new File(directory, jsonFileName)));
					
					scriptMetadata = gson.fromJson(br, Object.class);
					
					System.out.println(scriptMetadata);
				} catch (IOException e) {
					e.printStackTrace();
				}
			}
		}
		// 
		if(filecount == 0) {
			throw new RemoteException("Could not find the file " + jsonFileName + "!");
		}
		
		return scriptMetadata;
	}
    
    // this functions intends to run a script with filtered.
	// essentially this function should eventually be our main run script function.
	// in the request object, there will be: the script path, the script name
	// and the columns, along with their filters.
	// TODO not completed
	public MyResult runScriptWithFilteredColumns(AWSRequestObject request) throws Exception
	{
		RResult[] returnedColumns;

		String cannedScript = uploadPath + "RScripts/" + request.scriptName;
		
		// Object filteredColumnRequests = requestObject.get("columnsToBeRetrieved");
		long startTime = System.currentTimeMillis();
		
		Object[][] recordData = DataService.getFilteredRows(request.filteredColumnRequests, null).recordData;
		Object[][] columnData = transpose(recordData);
		recordData = null;
		
		long endTime = System.currentTimeMillis();
		
		long time1 = endTime - startTime;
		
		Object[] inputValues = {cannedScript, columnData};
		String[] inputNames = {"cannedScriptPath", "dataset"};

		String finalScript = "scriptFromFile <- source(cannedScriptPath)\n" +
					         "scriptFromFile$value(dataset)"; 

		String[] outputNames = {};
		
		startTime = System.currentTimeMillis();
		returnedColumns = runAWSScript(null, inputNames, inputValues, outputNames, finalScript, "", false, false);
		endTime = System.currentTimeMillis();
		columnData = null;
		long time2 = endTime - startTime;
		MyResult result = new MyResult();
		result.data = returnedColumns;
		result.times[0] = time1;
		result.times[1] = time2;
		
		return result;

	}
	
	private static RResult[] runAWSScript( String docrootPath, String[] inputNames, Object[] inputValues, String[] outputNames, String script, String plotScript, boolean showIntermediateResults, boolean showWarnings) throws Exception
	{		
		RConnection rConnection = RServiceUsingRserve.getRConnection();
		
		RResult[] results = null;
		Vector<RResult> resultVector = new Vector<RResult>();
		try
		{
			// ASSIGNS inputNames to respective Vector in R "like x<-c(1,2,3,4)"			
			RServiceUsingRserve.assignNamesToVector(rConnection,inputNames,inputValues);
			
			evaluateWithTypeChecking( rConnection, script, resultVector, showIntermediateResults, showWarnings);
			
			if (plotScript != ""){// R Script to EVALUATE plotScript
				String plotEvalValue = RServiceUsingRserve.plotEvalScript(rConnection,docrootPath, plotScript, showWarnings);
				resultVector.add(new RResult("Plot Results", plotEvalValue));
			}
			for (int i = 0; i < outputNames.length; i++){// R Script to EVALUATE output Script
				String name = outputNames[i];						
				REXP evalValue = evalScript( rConnection, name, showWarnings);	
				resultVector.add(new RResult(name, RServiceUsingRserve.rexp2javaObj(evalValue)));					
			}
			// clear R objects
			clearCacheTimeLog = true;
			evalScript( rConnection, "rm(list=ls())", false);
			
		}
		catch (Exception e)	{
			e.printStackTrace();
			System.out.println("printing error");
			System.out.println(e.getMessage());
			throw new RemoteException("Unable to run script", e);
		}
		finally
		{
			results = new RResult[resultVector.size()];
			resultVector.toArray(results);
			rConnection.close();
		}
		return results;
	}
	
	
	
	private static String timeLogString = "";
	private static boolean clearCacheTimeLog;
	
	//used for time logging in the aws home page 
	public static String getCurrentTime(String message)
	{
		String timedMessage = ""; 
		Calendar clr = Calendar.getInstance();
		SimpleDateFormat dformdate = new SimpleDateFormat("MM/dd/yyyy");
		SimpleDateFormat dformtime = new SimpleDateFormat("HH:mm:ss");
		timedMessage = message + " " + dformdate.format(clr.getTime()) + " " + dformtime.format(clr.getTime()) + "\n";
		System.out.print(timedMessage);
		return timedMessage;
	}

	
	private static REXP evalScript(RConnection rConnection, String script, boolean showWarnings) throws REXPMismatchException,RserveException
	{
			timeLogString = "";
		
		REXP evalValue = null;
		
		if(!clearCacheTimeLog)
		{
			//timeLogString = timeLogString + getCurrentTime("Sending data to R :");
			//timeLogString = timeLogString +"\nSending call to R : "+ debugger.get();
		}
		
		if (showWarnings)			
			evalValue =  rConnection.eval("try({ options(warn=2) \n" + script + "},silent=TRUE)");
		else
			evalValue =  rConnection.eval("try({ options(warn=1) \n" + script + "},silent=TRUE)");
		
		if(!clearCacheTimeLog){
		//	timeLogString = timeLogString  + getCurrentTime("Retrieving results from R :");
			//timeLogString = timeLogString + "\nResults received From R : " + debugger.get() + " ms";
		}
		
		return evalValue;
	}
	
	//testing for JavascriptAPI calls
	private static Vector<RResult> evaluateWithTypeChecking(RConnection rConnection, String script, Vector<RResult> newResultVector, boolean showIntermediateResults, boolean showWarnings ) throws ScriptException, RserveException, REXPMismatchException 
	{
		REXP evalValue= evalScript(rConnection, script, showWarnings);
		Object resultArray = RServiceUsingRserve.rexp2javaObj(evalValue);
		Object[] columns;
		if (resultArray instanceof Object[])
		{
			columns = (Object[])resultArray;
		}
		else
		{
			throw new ScriptException(String.format("Script result is not an Array as expected: \"%s\"", resultArray));
		}

		Object[][] final2DArray;//collecting the result as a two dimensional arrray 
		
		Vector<String> names = evalValue.asList().names;
		
	//try{
			//getting the rowCounter variable 
			int rowCounter = 0;
			/*picking up first one to determine its length, 
			all objects are different kinds of arrays that have the same length
			hence it is necessary to check the type of the array*/
			Object currentRow = columns[0];
			if(currentRow instanceof int[])
			{
				rowCounter = ((int[]) currentRow).length;
									
			}
			else if (currentRow instanceof Integer[])
			{
				rowCounter = ((Integer[]) currentRow).length;
				
			}
			else if(currentRow instanceof Double[])
			{
				rowCounter = ((Double[]) currentRow).length;
			}
			else if(currentRow instanceof double[])
			{
				rowCounter = ((double[]) currentRow).length;
			}
			else if(currentRow instanceof RFactor)
			{
				rowCounter = ((RFactor[]) currentRow).length;
			}
			else if(currentRow instanceof String[])
			{
				rowCounter = ((String[]) currentRow).length;
			}
			
			//handling single row, that is the currentColumn has only one record
			else if (currentRow instanceof Double)
			{
				rowCounter = 1;
			}
			
			else if(currentRow instanceof Integer)
			{
				rowCounter = 1;
			}
			
			else if(currentRow instanceof String)
			{
				rowCounter = 1; 
			}
			int columnHeadingsCount = 1;
			
			rowCounter = rowCounter + columnHeadingsCount;//we add an additional row for column Headings
			
			final2DArray = new Object[rowCounter][columns.length];
			
			//we need to push the first entry as column names to generate this structure
			/*[
			["k","x","y","z"]
			["k1",1,2,3]
			["k2",3,4,6]
			["k3",2,4,56]
			] */
		
			String [] namesArray = new String[names.size()];
			names.toArray(namesArray);
			final2DArray[0] = namesArray;//first entry is column names
			
			for( int j = 1; j < rowCounter; j++)
			{
				ArrayList<Object> tempList = new ArrayList<Object>();//one added for every column in 'columns'
				for(int f =0; f < columns.length; f++){
					//pick up one column
					Object currentCol = columns[f];
					//check its type
					if(currentCol instanceof int[])
					{
						//the second index in the new list should coincide with the first index of the columns from which values are being picked
						tempList.add(f, ((int[])currentCol)[j-1]);
					}
					else if (currentCol instanceof Integer[])
					{
						tempList.add(f,((Integer[])currentCol)[j-1]);
					}
					else if(currentCol instanceof double[])
					{
						tempList.add(f,((double[])currentCol)[j-1]);
					}
					else if(currentCol instanceof RFactor)
					{
						tempList.add(f,((RFactor[])currentCol)[j-1]);
					}
					else if(currentCol instanceof String[])
					{
						tempList.add(f,((String[])currentCol)[j-1]);
					}
					//handling single record
					else if(currentCol instanceof Double)
					{
						tempList.add(f, (Double)currentCol);
					}
					else if(currentCol instanceof String)
					{
						tempList.add(f, (String)currentCol);
					}
					else if(currentCol instanceof Integer)
					{
						tempList.add(f, (Integer)currentCol);
					}
					
				}
				Object[] tempArray = new Object[columns.length];
				tempList.toArray(tempArray);
				final2DArray[j] = tempArray;//after the first entry (column Names)
				//final2DArray.add(tempList);
				//tempList.clear();
			}
			
			System.out.print(final2DArray);
			newResultVector.add(new RResult("endResult", final2DArray));
			newResultVector.add(new RResult("timeLogString", timeLogString));
			

			return newResultVector;
			
	//	}
	//	catch (Exception e){
			//e.printStackTrace();
	//	}
		
//do the rest to generate a single continuous string representation of the result 
		//	String finalresultString = "";
//		String namescheck = Strings.join(",", names);
//		finalresultString = finalresultString.concat(namescheck);
//		finalresultString = finalresultString.concat("\n");
//
//		
//
//		int numberOfRows = 0;
//		
//		Vector<String[]> columnsInStrings = new Vector<String[]>();
//		
//		String[] tempStringArray = new String[0];
//		
//		try
//		{
//			for (int r= 0; r < columns.length; r++)					
//			{
//				Object currentColumn = columns[r];
//						
//						if(currentColumn instanceof int[])
//						{
//							 int[] columnAsIntArray = (int[])currentColumn;
//							 tempStringArray = new String[columnAsIntArray.length] ; 
//							 for(int g = 0; g < columnAsIntArray.length; g++)
//							 {
//								 tempStringArray[g] = ((Integer)columnAsIntArray[g]).toString();
//							 }
//						}
//						
//						else if (currentColumn instanceof Integer[])
//						{
//							 Integer[] columnAsIntegerArray = (Integer[])currentColumn;
//							 tempStringArray = new String[columnAsIntegerArray.length] ;  
//							 for(int g = 0; g < columnAsIntegerArray.length; g++)
//							 {
//								 tempStringArray[g] = columnAsIntegerArray[g].toString();
//							 }
//						}
//						
//						else if(currentColumn instanceof double[])
//						{
//							double[] columnAsDoubleArray = (double[])currentColumn;
//							 tempStringArray = new String[columnAsDoubleArray.length] ;  
//							 for(int g = 0; g < columnAsDoubleArray.length; g++)
//							 {
//								 tempStringArray[g] = ((Double)columnAsDoubleArray[g]).toString();
//							 }
//						}
//						else if(currentColumn instanceof RFactor)
//						{
//							tempStringArray = ((RFactor)currentColumn).levels();
//						}
//						else if(currentColumn instanceof String[]){
//							 int lent = ((Object[]) currentColumn).length;
//							 //String[] columnAsStringArray = currentColumn;
//							 tempStringArray = new String[lent];  
//							 for(int g = 0; g < lent; g++)
//							 {
//								 tempStringArray[g] = ((Object[]) currentColumn)[g].toString();
//							 }
//						/*	String[] temp = (String[])
//							int arrsize = ((String[])currentColumn).length;
//							tempStringArray = new String[arrsize];
//							tempStringArray = (String[])currentColumn;*/
//						}
//						
//						columnsInStrings.add(tempStringArray);
//						numberOfRows = tempStringArray.length;
//			}
//			
//			
//			//if(rowresult.charAt(rowresult.length()-1) == ',')
//				//rowresult.substring(0, rowresult.length()-1);
//		}
//		catch (Exception e) {
//			e.printStackTrace();
//		}
//		
//		for(int currentRow =0; currentRow <numberOfRows; currentRow ++)
//		{
//			for(int currentColumn= 0; currentColumn < columnsInStrings.size(); currentColumn++)
//			{
//				finalresultString += columnsInStrings.get(currentColumn)[currentRow] + ',';
//			}
//			
//			/*remove last comma and  new line*/
//			finalresultString = finalresultString.substring(0, finalresultString.length()-1);
//			finalresultString += '\n';
//		}
		
		//newResultVector.add(new RResult("endResult", finalresultString));
		//newResultVector.add(new RResult("timeLogString", timeLogString));

	}
	
	public Object[][] transpose (Object[][] array) {
		  if (array == null || array.length == 0)//empty or unset array, nothing do to here
		    return array;

		  int width = array.length;
		  int height = array[0].length;

		  Object[][] array_new = new Object[height][width];

		  for (int x = 0; x < width; x++) {
		    for (int y = 0; y < height; y++) {
		      array_new[y][x] = array[x][y];
		    }
		  }
		  return array_new;
	}

    @SuppressWarnings("rawtypes")
    protected Object cast(Object value, Class<?> type) throws RemoteException
    {
    	if (type == FilteredColumnRequest.class && value != null && value instanceof Map)
    	{
    		FilteredColumnRequest fcr = new FilteredColumnRequest();
    		fcr.id = (Integer)cast(MapUtils.getValue((Map)value, "id", -1), int.class);
    		fcr.filters = (Object[])cast(MapUtils.getValue((Map)value, "filters", null), Object[].class);
    		if (fcr.filters != null)
    			for (int i = 0; i < fcr.filters.length; i++)
    			{
    				Object item = fcr.filters[i];
    				if (item != null && item.getClass() == ArrayList.class)
    					fcr.filters[i] = cast(item, Object[].class);
    			}
    		return fcr;
    	}
    	if (type == FilteredColumnRequest[].class && value != null && value.getClass() == Object[].class)
    	{
    		Object[] input = (Object[]) value;
    		FilteredColumnRequest[] output = new FilteredColumnRequest[input.length];
    		for (int i = 0; i < input.length; i++)
    		{
    			output[i] = (FilteredColumnRequest)cast(input[i], FilteredColumnRequest.class);
    		}
    		value = output;
    	}
    	
    	return super.cast(value, type);
    }
}
