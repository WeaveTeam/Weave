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

import java.util.Properties;

public class JRItest
{
	//static JRIService ws = null;
	public static void call(String[] keys,String[] inputNames, Object[][] inputValues, String[] outputNames, String script, String plotScript, boolean showIntermediateResults, boolean showWarnings, boolean useColumnAsList) throws Exception{
		
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
	 
	
	@SuppressWarnings("unused")
	public static void main(String[] args) throws Exception {
		System.out.println("hi");		
		//ws = new JRIService();
		
		Properties prop = System.getProperties();
		String classPathh = prop.getProperty("java.class.path", null);
		//System.out.println(classPathh);
		String[] classPathArray = classPathh.split(";");
		for(int i = 0; i<classPathArray.length ;i++){
			//System.out.println(classPathArray[i]);
		}
		
		String[] inputNames = {};
		Object[][] inputValues = {};
		String plotscript = "";
		String script = "";		
		String [] resultNames = {};	
		
		Object[] array1 = { 0, 10, 20, 30, 40, 50, 56, 45, 67, 56, 98, 23, 45, 76};
		Object[] array2 = {10, 20, 30, 52, 34, 87, 34, 77, 44, 33, 88, 66, 22, 11};
		String[] keys   = {"a","b","c","d","e","f","g","h","i","j","k","l","m","n",};
		Object[] array3 = {"aa","bb","cc","dd","ee","ff","gg","hh","ii","jj","kk","ll","mm","nn"};
				

		inputNames =  new String []{"x","y"};
		inputValues = new Object[][]{array1,array2};
		script = "fun<-function(arg1){\n" +
				"ans<-(arg1) + 5\n" +
				"return(ans)}\n" +
				"d<-lapply(x,fun)";		
		resultNames =  new String []{"d"};			
		call(keys,inputNames,inputValues,resultNames,script,plotscript,true,false,false);
		
		inputNames =  new String []{"x","y"};
		inputValues = new Object[][]{array1,array2};
		plotscript = "plot(x,y)";
		//keys = new  String[]{};
		script = "d<-x[x>20]";		
		resultNames =  new String []{"x","d"};			
		call(keys,inputNames,inputValues,resultNames,script,plotscript,false,false,false);		
		
		script ="data1<-cbind(x,y) \n corelation<-cor(data1,use=\"complete\")";
		resultNames =  new String []{"corelation"};
		call(keys,inputNames,inputValues,resultNames,script,plotscript,true,false,false);
		
		call(keys, new String []{},new Object[][]{},resultNames,"","",false,false,false);
	
	}
}
