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

import java.io.IOException;
import java.rmi.RemoteException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.ListIterator;
import java.util.Map;
import java.util.Set;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;

import com.google.gson.Gson;

import weave.beans.HierarchicalClusteringResult;
import weave.beans.LinearRegressionResult;
import weave.beans.RResult;
import weave.beans.RequestObject;
import weave.config.WeaveContextParams;
import weave.config.ConnectionConfig.ConnectionInfo;
import weave.utils.DebugTimer;


 
public class RService extends GenericServlet
{
	private static final long serialVersionUID = 1L;

	public RService()
	{
	}

	private static Process rProcess = null;
	
	public void init(ServletConfig config) throws ServletException
	{
		super.init(config);
		docrootPath = WeaveContextParams.getInstance(config.getServletContext()).getDocrootPath();
		uploadPath = WeaveContextParams.getInstance(config.getServletContext()).getUploadPath();
		
	    try {
	    	String rServePath = WeaveContextParams.getInstance(config.getServletContext()).getRServePath();
	    	if (rServePath != null && rServePath.length() > 0)
	    		rProcess = Runtime.getRuntime().exec(new String[]{ rServePath });
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
	
	//handles running canned scripts by pulling data from csv
	public RResult[] runScriptOnCSVOnServer(String[] queryObject)throws Exception
	{
		RResult[] csvreturnedColumns;
		//get the upload path for csv (on server)
		//get the upload path for canned RScript (on server)
		//if using run on csv
		//TO DO: check for server side code?
//		String cannedScriptLocation = (uploadPath  + scriptName).replace('/', '\\');
//		String csvLocation = (uploadPath + datasetName).replace('/', '\\');
		
		//To Do check if queryObject is null
		//hard coded for now
			//String cannedScriptLocation = "C:\\Users\\Shweta\\Desktop\\brfss_RRoutine.R";
			//String csvLocation = "C:\\Users\\Shweta\\Desktop\\SDoH2010Q.csv";
		    String csvLocation = "/Users/franckamayou/Desktop/"+(queryObject[0]).toString();
			String cannedScriptLocation = "/Users/franckamayou/Desktop/"+(queryObject[1]).toString();
			
			Object[] inputValues = {cannedScriptLocation,csvLocation };
			
			String[] inputNames = {"cannedScriptPath", "csvDatasetPath"};
			String adminScript = "scriptFromFile <- source(cannedScriptPath)\n" +
			"library(survey)\n" +
			"columnsReturnedFromCSV <- scriptFromFile$value(csvDatasetPath)\n";
			//String[] outputNames = {"columnsReturnedFromCSV"};
			String[] outputNames = {};
			
			csvreturnedColumns = this.runScript(null, inputNames, inputValues, outputNames, adminScript, "", false, false, false);
			
		
		return csvreturnedColumns;
		
	}		
	
	//TO DO write to and retrieve computation results from database
	//TO DO make it a map of the entire queryObject, of which the results is a property
	//temporary fix storing computation results in a hashmap
	public Map<String,RResult[]> compResultLookMap = new HashMap<String,RResult[]>();
	
	/**
	 * 
	 * @param requestObject sent from the AWS UI collection of parameters to run a computation
	 * @param connectionObject send from the AWS UI parameters needed for connection Rserve to the db
	 * @return returnedColumns result columns from the computation
	 * @throws Exception
	 */
	public RResult[] runScriptOnSQLColumns(Map<String,String> connectionObject, Map<String,Object> requestObject) throws Exception
	{
		System.out.print("Reached the Rservlet\n");
		DebugTimer db = new DebugTimer();
		db.report();
		
		RResult[] returnedColumns;
		
		//Set<String> keys = connectionObject.keySet();
//		String user = connectionObject.get("user");
//		String password = connectionObject.get("password");
//		String schemaName = connectionObject.get("schema");
//		String hostName = connectionObject.get("host");
		
		//hard coded finish before 31st
		String user = "root";
		String password = "shweta";
		String dataset = "test";
		String hostName = "localhost";
		String schemaName = "data";
		
		
		//String dataset = requestObject.get("dataset").toString();
		String scriptName = requestObject.get("rRoutine").toString();
		//TO DO Find better way to do this? full proof queries?
		//query construction
		Object columnNames = requestObject.get("columnsToBeRetrieved");//array list
		ArrayList<String> columns = new ArrayList<String>();
		columns = (ArrayList)columnNames;
		
		int counter = columns.size();
		String tempQuery = "";
		
		for(int i=0; i < counter; i++)
		{
			String tempColumnName = columns.get(i);
			if(i == (counter-1))
			{
				tempQuery = tempQuery.concat(tempColumnName);
			}
			else
				tempQuery = tempQuery.concat(tempColumnName + ", ");
		}
		
		String query = "select " + tempQuery + " from " + (dataset).toString();
		
		 String cannedSQLScriptLocation = "/Users/Shweta/Desktop" + (scriptName).toString();//hard coded for now
		 
		 Object[] requestObjectInputValues = {cannedSQLScriptLocation, query};
		 String[] requestObjectInputNames = {"cannedScriptPath", "query"};
		
		
		String finalScript = "scriptFromFile <- source(cannedScriptPath)\n" +
		"library(RMySQL)\n" +
		"con <- dbConnect(dbDriver(\"MySQL\"), user =" + "\"" +user+"\" , password =" + "\"" +password+"\", host =" + "\"" +hostName+"\", port = 3306, dbname =" + "\"" +schemaName+"\")\n" +
		"library(survey)\n" +
		"returnedColumnsFromSQL <- scriptFromFile$value(query)\n";
		String[] requestObjectOutputNames = {};
		
		returnedColumns = this.runScript(null, requestObjectInputNames, requestObjectInputValues, requestObjectOutputNames, finalScript, "", false, false, false);
		
		System.out.print("Results leaving servlet\n");
		db.report();
		
		compResultLookMap.put(scriptName, returnedColumns);//temporary solution for caching. To be replaced by retrieval of computation results from db
		return returnedColumns;
		
	}
	
	//handles running canned scripts by pulling data from SQl database
	public RResult[] runScriptOnSQLOnServer(String[] queryObject, String queryStatement, String schema) throws Exception
	{
		RResult[] sqlreturnedColumns;
		//hard coding the query TO DO: has to be defined by user input and UI
		//To Do check if queryObject is null
		//String query = "select `@_STATE`,`@_PSU`,`@_STSTR`,`@_FINALWT`,DIABETE2 from sdoh2010q";
		//String query = "select `@_STATE`,`@_PSU`,`@_STSTR`,`@_FINALWT`,DIABETE2 from "+ (queryObject[0]).toString();
		String query = "select " + queryStatement + " from " + (queryObject[0]).toString();
		String editedQuery = query.replace(".csv", "");
		
			//String cannedSQLScriptLocation = "C:\\Users\\Shweta\\Desktop\\CDCSQLQueries.R";
			//Object[] sqlinputValues = {cannedSQLScriptLocation, query};
		//"con <- dbConnect(dbDriver(\"MySQL\"), user = \"root\", password = \"Tc1Sgp7nFc\", host = \"129.63.8.210\", port = 3306, dbname = \"resd\")\n"
		    String cannedSQLScriptLocation = "/Users/franckamayou/Desktop" + (queryObject[1]).toString();
			
			Object[] sqlinputValues = {cannedSQLScriptLocation, editedQuery};
			String[] sqlinputNames = {"cannedScriptPath", "query"};
			
			String sqlRScript = "scriptFromFile <- source(cannedScriptPath)\n" +
			"library(RMySQL)\n" +
			"con <- dbConnect(dbDriver(\"MySQL\"), user = \"root\", password = \"Tc1Sgp7nFc\", host = \"129.63.8.210\", port = 3306, dbname =" + "\"" +schema+"\")\n" +
			"library(survey)\n" +
			"returnedColumnsFromSQL <- scriptFromFile$value(query)\n";
			//String[] sqlOutputNames = {"returnedColumnsFromSQL"};
			String[] sqlOutputNames = {};
			
			sqlreturnedColumns = this.runScript(null, sqlinputNames, sqlinputValues, sqlOutputNames, sqlRScript, "", false, false, false);
			
		return sqlreturnedColumns;
	}
	
	public RResult[] runScript(String[] keys,String[] inputNames, Object[] inputValues, String[] outputNames, String script, String plotScript, boolean showIntermediateResults, boolean showWarnings, boolean useColumnAsList) throws Exception
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
					return RServiceUsingRserve.runScript( docrootPath, inputNames, inputValues, outputNames, script, plotScript, showIntermediateResults, showWarnings);
				
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

	public RResult[] kMeansClustering(String[] inputNames, Object[][] inputValues, boolean showWarnings,int numberOfClusters, int iterations) throws Exception
	{
		
		//return RServiceUsingRserve.kMeansClustering( docrootPath, dataX, dataY, numberOfClusters);
		return RServiceUsingRserve.kMeansClustering(inputNames, inputValues, showWarnings,numberOfClusters, iterations);
	}

	public HierarchicalClusteringResult hierarchicalClustering(double[] dataX, double[] dataY) throws RemoteException
	{
		return RServiceUsingRserve.hierarchicalClustering( docrootPath, dataX, dataY);
	}

	public RResult[] handlingMissingData(String[] inputNames, Object[][] inputValues, String[] outputNames, boolean showIntermediateResults, boolean showWarnings, boolean completeProcess) throws Exception
	{
		return RServiceUsingRserve.handlingMissingData(inputNames, inputValues, outputNames,showIntermediateResults, showWarnings, completeProcess);
	}
	
	
}
