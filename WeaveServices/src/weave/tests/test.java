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

//import java.util.ArrayList;
//import java.util.HashMap;
//import java.util.List;
//import java.util.Map;

//import weave.beans.WeaveRecordList;
import java.util.HashMap;

import weave.beans.WeaveRecordList;
import weave.config.SQLConfigManager;
import weave.config.WeaveContextParams;
import weave.servlets.DataService;

public class test {

	/**
	 * @param args
	 * @throws Exception 
	 */
	public static void main(String[] args) throws Exception {
		// TODO Auto-generated method stub
		System.out.println("hi");
		
//		RService ws = new RService();
//         
//		
//		
//		Object[] array1 = {11,2,33,44,55,46};
//		Object[] array2 = {10,20,30,52,34,87};
//		//Object[] array3 = {"aa","bb","cc","dd","ee","ff"};
////		
////		KMeansClusteringResult HCresult = ws.kMeansClustering(array1, array2, 3);
////		System.out.println(HCresult);
//		
//		//KMeansClusteringResult result = ws.kMeansClusteringFromArrays(array1, array2);
////		
//	/*	String script = "dataframe1 <- data.frame(array1, array2)\n"
//			+ "Clustering <- function(clusternumber,iter.max){\n"
//			+ "result1 <- kmeans(dataframe1, clusternumber, iter.max)\n"
//			+ "result2 <- kmeans(dataframe1, clusternumber, (iter.max - 1))\n"
//			+ "while(result1$centers != result2$centers){iter.max <- iter.max + 1\n"
//		+ "result1 <- kmeans(dataframe1, clusternumber, iter.max)\n"
//		+ "result2 <- kmeans(dataframe1, clusternumber, (iter.max - 1))\n"
//			+ "}\n"
//			+ "print(result1)\n"
//			+ "print(result2)\n"
//			+ "}\n"
//		+ "Cluster <- Clustering(3,2)";
//		
//		String[] resultNames = {
//				//Returns a vector indicating which cluster each data point belongs to
//				"Cluster$cluster",
//				//Returns the means of each of the clusters
//				"Cluster$centers",
//				//Returns the size of each cluster
//				"Cluster$size",
//				//Returns the sum of squares within each cluster
//				"Cluster$withinss"
//		};*/
//		
//		//to test warning message
//		String plotscript = "plot(x,y)";
//		String script = "sqrt(-17)";
//		String [] resultNames = {"dataframe1"};		
//		System.out.println(ws.runScript(
//			new String[]{"x","y"},
//			new Object[][]{array1,array2},
//			resultNames,
//			script,plotscript,false,false
//			
//	));		
	/*	Object[] resultNames = {"y"};
		System.out.println(ws.runScript(
			new String[]{},
			new String[]{},
			resultNames,
			script,true,false
			
			));*/
		
		//System.out.println(ws.AdvancedRScriptFromArray(l1, "data", "mean(data)"));
				
		
		
		// hide annoying compiler warnings
	//	for(Object o:new Object[]{
	//		ws,array1,array2,script,resultNames
	//	})o=true?o:o;
		
		/******************** Datservice Testing ************/
		
		HashMap<String,String> params = new HashMap<String,String>();
		//params.put("dataTable","my cool test table");
		//params.put("name","the first data column");
		params.put("keyType","my cool keytype");
		
		SQLConfigManager configManager = new SQLConfigManager(new WeaveContextParams("",""));
		
		DataService ds = new DataService(configManager);
		
		System.out.println(ds.getRows("my cool keytype", new String[]{"g"}));
		
		
		WeaveRecordList result = ds.getRows("US State FIPS Code", new String[]{"02"});
		System.out.println(String.format(
				"%s columns, %s rows",
				result.attributeColumnMetadata.length,
				result.recordKeys.length
			));
	}
}
