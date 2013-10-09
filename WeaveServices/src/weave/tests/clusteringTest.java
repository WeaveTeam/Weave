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
package weave.tests;


import java.rmi.RemoteException;
import java.text.SimpleDateFormat;
import java.util.Arrays;
import java.util.Calendar;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;

import weave.beans.RResult;
import weave.servlets.RService;

public class clusteringTest
{

	static RService ws = null;
	
	
	public static void call(String[] keys, String[]inputNames, Object[]inputValues, String[]resultNames, String script, String plotScript, boolean showIntermediateResults, boolean showWarnings, boolean useColumnAsList)
	throws Exception
	{

	    for(int i = 0; i < 4; i++)
	    {
			
				RResult[] scriptResult = null;
				
				Object [] allResults = new Object[3];
				
				System.out.println(System.getProperty("user.dir"));
			try {
				
				scriptResult = ws.runScript(null, inputNames, inputValues, resultNames, script, plotScript, showIntermediateResults, showWarnings, useColumnAsList);
				} catch (RemoteException e) {
					e.printStackTrace();
				}
				finally
				{
					System.out.println(Arrays.asList(scriptResult));
				}
				allResults[i] = scriptResult;
	    }
	}
	

	public static void main(String[] args) throws Exception
	{
		ws = new RService();
		
		//Object[] inputValues1 = {};	
		//Object[] inputValues = {};
		String plotscript = "";
		//Object[] parameters = {};
		String [] resultNames = {};	
		String scriptFilePath = "C:\\RScripts\\TestingAWS_RODBC.R";
		//String csvPath = "C:\\Users\\Shweta\\Desktop\\SDoH2010Q.csv";
		String user = "root";
		String password = "shweta";
		String hostName = "localhost";
		String schemaName = "data";
		String dsn = "myCDC";
		String [] columns = {"X_STATE", "X_PSU", "X_STSTR", "X_FINALWT", "DIABETE2"};
		String query = "select `X_STATE`,`X_PSU`,`X_STSTR`,`X_FINALWT`,DIABETE2 from sdoh2010q";
		
		 Object[] inputValues = {scriptFilePath, query, columns, user, password, hostName, schemaName, dsn};
		 String[] inputNames = {"cannedScriptPath", "query", "params", "myuser", "mypassword", "myhostName", "myschemaName", "mydsn"};
		
		String script =  "scriptFromFile <- source(cannedScriptPath)\n" +
		  "library(RMySQL)\n" +
		  "con <- dbConnect(dbDriver(\"MySQL\"), user = myuser , password = mypassword, host = myhostName, port = 3306, dbname =myschemaName)\n" +
		  "library(survey)\n" +
		  "getColumns <- function(query)\n" +
		  "{\n" +
		  "return(dbGetQuery(con, paste(query)))\n" +
		  "}\n" +
		  "returnedColumnsFromSQL <- scriptFromFile$value(query, params)\n";
		
		
		call(null,inputNames, inputValues,resultNames,script,plotscript, false,false,false);
		
		
		//inputValues1 = new Object[0];
		//inputNames = new String[]{"myMatrix"};
		//Object[] array4 = {"ji", "hello"};
		//Object[] array5 = {0,1,2,3,4};
		//inputNames = new String []{"inputColumns","EMModel"};
		//Object[][] myMatrix = new Object[][]{array1, array2, array3};
		//String[] EMModel = {"VII"};
		//inputValues1 = new Object[]{myMatrix};
		//script = "y <- max(x)";
//		script = " frame <- data.frame(myMatrix)\n" +
//				"normandBin <- function(frame)\n" +  
//                               "structure(list(counts = getCounts(frame), breaks = getBreaks(frame)), class = \"normandBin\");\n"+
//				"getNorm <- function(frame){\n" +				
//			         "myRows <- nrow(frame)\n" +
//					 "myColumns <- ncol(frame)\n" +
//					 "for (z in 1:myColumns ){\n" +
//			         "maxr <- max(frame[z])\n" +
//			         "minr <- min(frame[z])\n" +
//			         "for(i in 1:myRows ){\n" +
//			         "frame[i,z] <- (frame[i,z] - minr) / (maxr - minr)\n" +
//			         " }\n" +
//			         "}\n" +
//					 "return(frame)\n" +
//					 "}\n" +
//		 "getCounts <- function(normFrame){\n" +
//					   "normFrame <- getNorm(frame)\n" +
//						"c <- ncol(normFrame)\n" +
//						"histoInfo <- list()\n" +
//						"answerCounts <- list()\n" +
//						"for( s in 1:c){\n" + 
//					    "histoInfo[[s]] <- hist(normFrame[[s]], plot = FALSE)\n" + 
//						"answerCounts[[s]] <- histoInfo[[s]]$counts\n" +
//						"}\n" +
//						"return(answerCounts)\n" +
//						"}\n" +
//		"getBreaks <- function(frame){\n" +
//		              "normFrame <- getNorm(frame)\n" +
//					  " c <- ncol(normFrame)\n" +
//					  "histoInfo <- list()\n" +
//					  "answerBreaks <- list()\n" +
//					  "for( i in 1:c){\n" +
//					  "histoInfo[[i]] <- hist(normFrame[[i]], plot = FALSE)\n" +
//					  "answerBreaks[[i]] <- histoInfo[[i]]$breaks\n" +
//					  "}\n" +
//					  "return(answerBreaks)\n" +
//					  "}\n" +
//					
//		"finalResult <- normandBin(frame)\n";
//		
		
//		script = "library(mclust)\n" +
//		"hello1 <- function(inputColumns, EMModel){\n" +
//		"Clusters = list()\n" + 
//		"for(i in 1: length(EMModel)){\n" +
//		"BIC <- NA\n" +
//		"try(BIC <- Mclust(inputColumns, 7, EMModel[i]))\n" +
//		"Results <- NA\n" +
//		"try( Results <- summary( BIC, inputColumns ) )\n" +
//		"Clusters [[i]]<- Results$classification\n" + 
//		"return(Clusters)}}\n" +
//		"ans <- hello1(inputColumns, EMModel)\n";
		
			
//		
	}	
}		
		
	
