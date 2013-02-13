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

import java.io.File;
import java.rmi.RemoteException;
import java.util.Arrays;

import weave.beans.RResult;
import weave.config.ConnectionConfig;
import weave.config.DataConfig;
import weave.servlets.RService;
import weave.utils.ProgressManager.ProgressPrinter;

public class test
{

	static RService ws = null;
//	public static void call(String[] inputNames, Object[][] inputValues,  
//			 boolean showWarnings, int clusternumber, int iterationNumber) throws Exception{
	
	public static void call(String[] keys, String[]inputNames, Object[]inputValues, String[]resultNames, String script, String plotScript, boolean showIntermediateResults, boolean showWarnings, boolean useColumnAsList)
	throws Exception{

	    for(int i = 0; i < 4; i++)
	    {
			
				RResult[] scriptResult = null;
				
				Object [] allResults = new Object[3];
				
				System.out.println(System.getProperty("user.dir"));
			try {
				//scriptResult =	ws.kMeansClustering(inputNames, inputValues, showWarnings,clusterNo, iterations);
				//scriptResult = ws.handlingMissingData(inputNames, inputValues, outputNames, false, false, false);
				//scriptResult = ws.kMeansClustering(inputNames, inputValues, false, 3, 10);
				//scriptResult = ws.computingTStatisticforClassDiscrimination(inputNames, inputValues, resultNames, parameters);
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
	
	@SuppressWarnings("unused")
	public static void main(String[] args) throws Exception
	{
		for (String fileName : Arrays.asList(
				"/home/pkovac/dload/cfg/sqlconfig.xml",
				"d:/tomcat/webapps/weave-config/sqlconfig.xml",
				"c:/tomcat/webapps/weave-config/sqlconfig.xml"))
		{
			File file = new File(fileName);
			if (file.exists())
			{
				ConnectionConfig connConfig = new ConnectionConfig(file);
				if (connConfig.migrationPending())
				{
					ProgressPrinter pp = new ProgressPrinter(System.out);
					DataConfig dataConfig = connConfig.initializeNewDataConfig(pp.getProgressManager());
				}
				else
				{
					DataConfig dataConfig = new DataConfig(connConfig);
//					dataConfig.buildHierarchy(135616, 135616, 1);
				}
				break;
			}
		}
		
//		ConnectionInfo connInfo = new ConnectionInfo();
//		connInfo.connectString = "hello";
//		connInfo.name = "myname";
//		connInfo.dbms = "what";
//		connInfo.pass = "PPPASS";
//		connConfig.addConnectionInfo(connInfo);
//		
//		DatabaseConfigInfo dbInfo = new DatabaseConfigInfo();
//		dbInfo.connection = "myname";
//		dbInfo.schema = "weave";
//		connConfig.setDatabaseConfigInfo(dbInfo);
		
		if (true)
			return;
		
//		Connection conn = SQLUtils.getConnection(SQLUtils.getDriver(SQLUtils.MYSQL), "jdbc:mysql://localhost/weave?user=root&password=boolpup");
//		SQLConfig sqlcfg = new SQLConfig(new SQLConfigXML("C:\\Program Files (x86)\\Apache Software Foundation\\Tomcat 6.0\\webapps\\weave-config\\sqlconfig.xml"));
//		SQLConfig sqlcfg = new SQLConfig(new SQLConfigXML("sqlconfig.xml"));
//		System.out.println(sqlcfg.addEntry("Hello", null));
		// TODO Auto-generated method stub
		ws = new RService();
	
		
		String[] inputNames = {};
		Object[] inputValues1 = {};	
		Object[] inputValues = {};
		String plotscript = "";
		String script = "";		
		Object[] parameters = {};
		String [] resultNames = {};	
		
		Object[] array1 = {0,10,20,30,22,50,60,55,89,33,44,54,21};
		Object[] array2 = {10,20,44,52,34,87,45,65,76,87,23,12,34};
		Object[] array3 = {10,20,44,52,34,87,45,65,76,87,23,12,34};
		Object[] array4 = {"ji", "hello"};
		Object [] array5 = {0,1,2,3,4};
		//String[] keys = {"a","b","c","d","e","f"};
//		//Object[] array3 = {"aa","bb","cc","dd","ee","ff"};
		

		//String docrootPath  = "";
		//inputNames = new String []{"inputColumns", "number_of_clusters", "number_of_Iterations", "randomsets", "algorithm"};//for operations on matrices
		
		inputNames = new String []{"inputColumns","fnumberOfClusters","dmetric","fnumberOfIterations"};
		//inputNames = new String []{"inputColumns", "knumber_of_clusters","knumber_of_Iterations","randomsets","algorithm","fnumberOfClusters","dmetric","fnumberOfIterations"};//for operations on matrices
		Number number_of_clusters = 3;
		Number number_of_Iterations = 10;
		Number fnumber_of_clusters = 3;
		Number fnumber_of_Iterations = 500;
		Number randomsets = 1;
		String algorithm = "Forgy";
		String dmetric = "manhattan";
		//inputNames =  new String []{"myVector"};//for operations on vectors
	//inputValues = new Object[][]{array1,array2};
		Object[][] myMatrix = new Object[][]{array1, array2, array3};
	//inputValues1 = new Object[]{ array3 };
		inputValues1 = new Object[]{myMatrix,fnumber_of_clusters,dmetric,fnumber_of_Iterations};
	//inputValues1 = new Object[]{myMatrix,number_of_clusters,number_of_Iterations,randomsets,algorithm,fnumber_of_clusters,dmetric,fnumber_of_Iterations};

		//keys = new  String[]{};
//		script = "Clustering <- function(clusternumber, iterations)\n" +
//				 "{result1 <- kmeans(dataframe1, clusternumber, iterations)\n" +
//				 "result2 <- kmeans(dataframe1, clusternumber, (iterations-1))\n" +
//				 "while(result1$centers != result2$centers)\n" + 
	//			 "{ iterations <- iterations + 1\n" +
//				 "result1 <- kmeans(dataframe1, clusternumber, iterations)\n" + 
//				 "result2 <- kmeans(dataframe1, clusternumber, (iterations-1))}\n" + 
//				 "print(result1)\n" + 
//				 "print(result2)}\n" +
//				 "CluResult <- Clustering(clusterNo, iterations)";
			
		
	    //imputation script
//		script = "  library(norm) \n pre<-prelim.norm(Bind) \n eeo <- em.norm(pre) \n rngseed(34215) \n " +
//				 " imputed <- imp.norm(pre, eeo, Bind) ";

//	
	script = "library(cluster)\n" +
			"frame <- data.frame(inputColumns)\n" +
	"fuzzkMeansResult <- fanny(frame,fnumberOfClusters, metric = dmetric, maxit = fnumberOfIterations)\n";
//	script = "frame <- data.frame(inputColumns)\n" +
//	"kMeansResult <- kmeans(frame,knumber_of_clusters,knumber_of_Iterations, nstart = randomsets, algorithm)\n" +
//	"library(cluster)\n" +
//	"fuzzkMeansResult <- fanny(frame,fnumberOfClusters, metric = dmetric, maxit = fnumberOfIterations)\n"; 

//	script =	"frame <- data.frame(mymatrix)\n" +
//				"v <- function(frame){\n" +
//				"RR <- nrow(frame)\n"+
//				"CC <- ncol(frame)\n"+
//				"for (z in 1:(CC-1)){\n"+
//				"maxr <- max(frame[z])\n"+
//				"minr <- min(frame[z])\n"+
//				"for(i in 1:RR){\n"+
//				" frame[i,z] <- (frame[i,z] - minr) / (maxr - minr)\n"+
//				" }\n"+
//				"}\n"+
//				"frame\n"+
//				"}\n"+
//				"output <- v(frame)\n";
//	script = "s <- mean(mtVec1)\n" +
//			"m <- max(mtVec1)\n" +
//			"n <- min(mtVec1)";
	
	//script = "answer <- cor(mymatrix, use = \"everything\", method = \"pearson\")";
		//resultNames =  new String []{"answer"};//test for matrix
	//resultNames = new String[]{"2"};
	resultNames = new String[]{"fuzzkMeansResult"};
	//resultNames = new String[]{"pcaResult$loadings", "pcaResult$sd^2"};
	//plotscript = "plot(x <- c(1,2,3,4))";
	
//	plotscript = "for(i in 1:3)\n" +
//			"{" +
//			"hist(myVector)\n" +
//			"}";
//	plotscript =  "for(i in 1:l)\n" +
//	"{\n" +
//	"hist(myVector, xlab = shweta)\n" +
//	"}\n";
	//script = "s <- data.frame(Vec1)";
		//script = "Vec1 <- as.matrix(Vec1)\n";
		//resultNames = new String[]{"CluResult$cluster", "CluResult$centers", "CluResult$size", "CluResult$withinss"};
	//script = "d <- is.vector(mymatrix)";
//	script = "frame <- data.frame(mymatrix)\n" +
//	"pcaResult <- princomp(frame)\n";
		call(null,inputNames, inputValues1,resultNames,script,plotscript, true,false,false);
		
	}
}
