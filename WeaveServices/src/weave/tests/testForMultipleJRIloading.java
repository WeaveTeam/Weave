/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of Weave.
 *
 * The Initial Developer of Weave is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2015
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weave.tests;

public class testForMultipleJRIloading
{

	public static void call(String[] keys,String[] inputNames, Object[][] inputValues, String[] outputNames, String script, String plotScript, boolean showIntermediateResults, boolean showWarnings, boolean useColumnAsList) throws Exception
	{
		/*
		RResult[] scriptResult = null;
		try {
			scriptResult =	ws.runScript(keys,inputNames, inputValues, outputNames, script, plotScript, showIntermediateResults, showWarnings,useColumnAsList);
		} catch (RemoteException e) {
			e.printStackTrace();
		}
		finally{
			System.out.println(scriptResult);
		}
		*/
	}
	
	public static void main(String[] args) throws Exception {
		// TODO Auto-generated method stub
		System.out.println("hi");		
		//ws = new JRIService();
	
		
		String[] inputNames = {};
		Object[][] inputValues = {};			
		String plotscript = "";
		String script = "";		
		String [] resultNames = {};	
		
		Object[] array1 = {0,10,20,30,40,50};
		Object[] array2 = {10,20,30,52,34,87};
		String[] keys = {"a","b","c","d","e","f"};
//		//Object[] array3 = {"aa","bb","cc","dd","ee","ff"};
		
//		plotscript ="";
//		script = "x<-5";
//		inputNames = new String[]{};
//		inputValues = new Object[][]{};
//		resultNames = new String []{"x"};
//		keys = new  String[]{};
//		call(keys,inputNames,inputValues,resultNames,script,plotscript,false,false);
//		
//		inputNames =  new String []{"x","y"};
//		inputValues = new Object[][]{array1,array2};	
//		keys = new String []{"0","1","2","3","4","5"};
//		plotscript = "plot(x,y)";
//		script = "df<-data.frame(x,y)";		
//		resultNames =  new String []{"df"};			
//		call(keys,inputNames,inputValues,resultNames,script,plotscript,false,false);	
		

//		inputNames =  new String []{"x","y"};
//		inputValues = new Object[][]{array1,array2};	
//		keys = new String []{"a","b","c","d","e","f"};
//		//plotscript = "plot(x,y)";
//		script = "fun<-function(arg1){\n" +
//				"ans<-(arg1) + 5\n" +
//				"return(ans)}\n" +
//				"d<-lapply(x,fun)";		
//		resultNames =  new String []{"d"};			
//		call(keys,inputNames,inputValues,resultNames,script,plotscript,false,false);
		
		inputNames =  new String []{"x","y"};
		inputValues = new Object[][]{array1,array2};
		//plotscript = "plot(x,y)";
		//keys = new  String[]{};
		script = "d<-x[x>20]";		
		resultNames =  new String []{"x","d"};			
		call(keys,inputNames,inputValues,resultNames,script,plotscript,false,false,false);
		
	}
}
