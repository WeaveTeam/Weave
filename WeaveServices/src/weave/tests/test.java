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

import weave.beans.RResult;
import weave.servlets.RService;

public class test
{

	static RService ws = null;
	public static void call(String[] inputNames, Object[][] inputValues,  
			 boolean showWarnings, int clusternumber, int iterationNumber) throws Exception{
	
//	public static void call(String[] inputNames, Object[][] inputValues, String[] outputNames, String script, String plotScript,
//   boolean showIntermediateResults, boolean showWarnings) throws Exception;
		
		RResult[] scriptResult = null;
	try {
//			scriptResult =	ws.kMeansClustering(inputNames, inputValues,  
//					  showWarnings,clusterNo, iterations);
		//scriptResult = ws.handlingMissingData(inputNames, inputValues, outputNames, false, false, false);
		scriptResult = ws.kMeansClustering(inputNames, inputValues, false, 3, 10);
		} catch (RemoteException e) {
			e.printStackTrace();
		}
		finally{
			System.out.println(scriptResult);
		}
	}
	
	public static void main(String[] args) throws Exception {
		// TODO Auto-generated method stub
		System.out.println("hi");		
		ws = new RService();
	
		
		String[] inputNames = {};
		Object[][] inputValues = {};			
		String plotscript = "";
		String script = "";		
		String [] resultNames = {};	
		
		Object[] array1 = {0,10,20,30,22,50,60,55,89,33,44,54,21};
		Object[] array2 = {10,20,44,52,34,87,45,65,76,87,23,12,34};
		//String[] keys = {"a","b","c","d","e","f"};
//		//Object[] array3 = {"aa","bb","cc","dd","ee","ff"};
		
//		plotscript ="";
//		script = "x<-5";
//		inputNames = new String[]{};
//		inputValues = new Object[][]{};
//		resultNames = new String []{"x"};
//		keys = new  String[]{};
//		inputNames =  new String []{"x","y"};
//		inputValues = new Object[][]{array1,array2};	
//		keys = new String []{"0","1","2","3","4","5"};
//		plotscript = "plot(x,y)";
//		script = "df<-data.frame(x,y)";		
//		resultNames =  new String []{"df"};			
//		call(inputNames,inputValues,resultNames,script,plotscript,false,false);	
		

		String docrootPath  = "";
		
		inputNames =  new String []{"x","y"};
	inputValues = new Object[][]{array1,array2};	
//		keys = new String []{"a","b","c","d","e","f"};
//		//plotscript = "plot(x,y)";
//		script = "fun<-function(arg1){\n" +
//				"ans<-(arg1) + 5\n" +
//				"return(ans)}\n" +
//				"d<-lapply(x,fun)";		
//		resultNames =  new String []{"d"};			
//		call(inputNames,inputValues,resultNames,script,plotscript,false,false);
		
		
		
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
		
		//resultNames =  new String []{"pre$nmis","imputed" };
		
		//resultNames = new String[]{"CluResult$cluster", "CluResult$centers", "CluResult$size", "CluResult$withinss"};
		call(inputNames, inputValues, false, 3, 10);
		
	}
}
