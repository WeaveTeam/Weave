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

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;

import weave.beans.HierarchicalClusteringResult;
import weave.beans.LinearRegressionResult;
import weave.beans.RResult;
import weave.config.WeaveContextParams;


 
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
	public RResult[] runScriptOnCSVOnServer(Object[] queryObject)throws Exception
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
		    String csvLocation = "C:\\Users\\Shweta\\Desktop\\"+(queryObject[0]).toString();
			String cannedScriptLocation = "C:\\Users\\Shweta\\Desktop\\"+(queryObject[1]).toString();
			
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
		    String cannedSQLScriptLocation = "C:\\Users\\Shweta\\Desktop\\" + (queryObject[1]).toString();
			
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
